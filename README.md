# catalog_tool
Puppet catalog tool to retrieve facts and catalogs from multiple masters when catalog diff is not working

in order for this to work in Puppet 3.8, edit puppet.conf on the master/CM and add "trusted_node_data = false" under the [main] section
