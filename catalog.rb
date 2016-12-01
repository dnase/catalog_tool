#!/opt/puppet/bin/ruby
require 'puppet'
require 'puppet/face'
require 'optparse'

# script to retrieve and store facts and catalogs from multiple puppet masters for multiple nodes
# IMPORTANT: in order for this to work in Puppet 3.8, edit puppet.conf on the master/CM and add
# "trusted_node_data = false" under the [main] section

# directory to store facts - should exist beforehand
yamldir = '/tmp/yaml/facts'

if ARGV.count == 0
  puts "Usage: #{$0} [arguments]\n--help for details"
  exit
end

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

def prepare_facts(facts)
  # make sure the "trusted" fact does not appear or puppet will complain
  facts.values().delete("trusted")
  text = facts.render(:pson)
  {:facts_format => :pson, :facts => CGI.escape(text)}
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
  if File.exist?("#{yamldir}/#{node}.yaml")
    # load facts from yaml
    facts = YAML.load_file("#{yamldir}/#{node}.yaml")
    if facts.class != Puppet::Node::Facts
      puts "Error: invalid fact yaml"
      exit
    end
    puts "Loaded facts from #{yamldir}/#{node}.yaml"
  else
    # get facts from master and save YAML to yamldir
    facts = Puppet::Face[:facts, '0.0.1'].find(node)
    fhandle = File.new("#{yamldir}/#{node}.yaml", 'w')
    fhandle.write(facts.render(:yaml))
    fhandle.close
    puts "Loaded facts from master, stored in #{yamldir}/#{node}.yaml"
  end
  # get catalog and store to .pson file
  formatted_facts = prepare_facts(facts).merge(:ignore_cache => true, :environment => Puppet::Node::Environment.remote(environment), :fail_on_404 => true, :transaction_uuid => SecureRandom.uuid)
  result = Puppet::Resource::Catalog.indirection.find(node, formatted_facts)
  fhandle = File.new("#{node}-#{master}.pson", 'w')
  fhandle.write(result.to_pson)
  fhandle.close
  puts "Retrieved catalog for #{node}, stored in #{node}-#{master}.pson"
end

