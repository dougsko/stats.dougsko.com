#!/bin/bash
#
# run all the graphing scripts
#

cd /var/www/stats.dougsko.com/htdocs
for i in `find . -maxdepth 1 -mindepth 1 -type d`; 
do 
    pushd $i
    for i in *.sh;
    do
        sh $i
    done
    popd
done
