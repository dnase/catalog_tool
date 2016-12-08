#!/bin/sh

for ruby in /opt/puppet/bin/ruby /opt/puppetlabs/puppet/bin/ruby
do
    if [ -x "$ruby" ]
    then
        cmdstr="#!${ruby}"
        sed -i "1s%.*%$cmdstr%" catalog.rb
        break
    fi
done

echo "configured script to run with $ruby"
