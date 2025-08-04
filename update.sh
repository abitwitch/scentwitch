#!/bin/bash

cd "$(dirname "$0")";

curdir=$(pwd | xargs basename)
gitreponame=$(basename `sudo -u crow git rev-parse --show-toplevel`)

if [ "$curdir" = "$gitreponame" ]; then
    #Clean git repo
    sudo find ./ -mindepth 1 ! -regex '^./.git\(/.*\)?' | grep -v '^./.github*' | grep -v './clean.sh' | grep -v './update.sh'  | grep -v './README.md' | grep -v './lastrun' | grep -v './.gitignore' | xargs sudo rm -rf
    #Clean prev run of static site
    sudo rm -r /var/www/html/crow.local-static/
    #Create static version of site
    cd /var/www/html
    yes | sudo ./wpstatic
    cd -
    #Copy static site to git repo
    sudo cp /var/www/html/crow.local-static/* . -r
    sudo -u crow git pull
    gitdiff=$(sudo -u crow git diff --ignore-all-space -I"secret=.*\"")
    if [ "$gitdiff" != "" ]; then
        #Update lastrun
        sudo date +%s > ./lastrun
        #Git commit and push
        sudo -u crow git add -A
        sudo -u crow git commit -m "`date`"
        sudo -u crow git push
    else
        echo "No changes since last run."
    fi
else
    echo "Error: Set current directory to the repo and then rerun."
    exit 1
fi
