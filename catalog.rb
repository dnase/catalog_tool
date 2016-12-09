#!/opt/puppet/bin/ruby
require 'puppet'
require 'puppet/face'
require 'optparse'
require 'fileutils'

# script to retrieve and store facts and catalogs from multiple puppet masters for multiple nodes
# IMPORTANT: in order for this to work in Puppet 3.8, edit puppet.conf on the master/CM and add
# "trusted_node_data = false" under the [main] section

cachedir = '/tmp/cache'
# create cachedir if it doesn't exist
Dir.mkdir(cachedir) unless File.exist?(cachedir)

if ARGV.count == 0
  puts "Usage: #{$0} [arguments]\n--help for details"
  exit
end

overwrite = false
options = {}
OptionParser.new do |opts|
  opts.on("-mMASTER", "--master=MASTER", "Puppet master") do |m|
    options[:master] = m
  end
  opts.on("-nNODES", "--nodes=NODES", "Puppet nodes as comma separated string") do |n|
    options[:nodes] = n
  end
  opts.on("-eENVIRONMENT", "--env=ENVIRONMENT", "Puppet environment") do |e|
    options[:env] = e
  end
  opts.on("-f", "--force", "Overwrite existing catalogs") do
    overwrite = true
  end
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

# all arguments must be given
if options[:master].nil? or options[:nodes].nil? or options[:env].nil?
  puts "All arguments are mandatory. Run with --help for details"
  exit
end

def prepare_facts(facts, environment)
  # make sure the "trusted" fact does not appear or puppet will complain
  facts.values().delete("trusted")
  text = facts.render(:pson)
  {
    :facts_format => :pson, 
    :facts => CGI.escape(text),
    :ignore_cache => true,
    :environment => Puppet::Node::Environment.remote(environment),
    :fail_on_404 => true,
    :transaction_uuid => SecureRandom.uuid
  }
end

Puppet.initialize_settings
Puppet[:server] = options[:master]
master = options[:master]
Puppet[:catalog_terminus] = :rest
Puppet[:facts_terminus] = :puppetdb
environment = options[:env]
# create array of nodes from comma separated string, stripping whitespace
nodes = options[:nodes].split(",").map{|node| node.strip}

nodes.each do |node|
  nodedir = "#{cachedir}/#{node}"
  Dir.mkdir(nodedir) unless File.exist?(nodedir)
  facts_file = "#{nodedir}/facts.yaml"
  catalog_file = "#{nodedir}/#{master}.pson"
  if File.exist?(catalog_file) and overwrite == false
    puts "Catalog exists and force-overwrite is not set. Run with -f or --force to replace catalog."
    exit
  end
  if File.exist?(facts_file)
    # load facts from yaml
    facts = YAML.load_file(facts_file)
    if facts.class != Puppet::Node::Facts
      puts "Error: invalid fact yaml"
      exit
    end
    puts "Loaded facts from #{facts_file}"
  else
    # get facts from master and save YAML to cachedir
    facts = Puppet::Face[:facts, '0.0.1'].find(node)
    fhandle = File.new(facts_file, 'w')
    fhandle.write(facts.render(:yaml))
    fhandle.close
    puts "Loaded facts from master, stored in #{facts_file}"
  end
  # get catalog and store to .pson file
  formatted_facts = prepare_facts(facts, environment)
  result = Puppet::Resource::Catalog.indirection.find(node, formatted_facts)
  fhandle = File.new(catalog_file, 'w')
  fhandle.write(result.to_pson)
  fhandle.close
  puts "Retrieved catalog for #{node}, stored in #{catalog_file}"
end
