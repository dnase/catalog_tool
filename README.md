# catalog_tool
Puppet catalog tool to retrieve facts and catalogs from multiple masters when catalog diff is not working

in order for this to work in Puppet 3.8, edit puppet.conf on the master/CM and add "trusted_node_data = false" under the [main] section

Run `./config.sh` to automatically detect the location of Puppet's ruby binary and add it to the top of the script. This location differs between Puppet 4+ and older versions.
