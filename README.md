# catalog_tool
This is a Puppet catalog tool to retrieve facts and catalogs from multiple masters when the catalog diff tool by itself is not feasible (such as cases where the old Puppet infrastructure is inaccessible from the new one).

You will need to edit the ACL for `/catalog` in `auth.conf` to allow the node from which the script will be run to fetch catalogs for other nodes. 

In order for this to work in Puppet 3.8, edit puppet.conf on the master/CM and add "trusted_node_data = false" under the [main] section.

Run `./config.sh` to automatically detect the location of Puppet's ruby binary and add it to the top of the script. This location differs between Puppet 4+ and older versions.

The pson and yaml files are stored by default in `/tmp/cache/<node certname>`.
