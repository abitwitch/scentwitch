#!/bin/bash

cd "$(dirname "$0")";

curdir=$(pwd | xargs basename)
gitreponame=$(basename `sudo -u witch git rev-parse --show-toplevel`)
#static_dir="/var/www/html/public_static"
static_dir="/var/www/html/wp-content/uploads/staatic/deploy"
git_static_dir="$(pwd)/public_static"

if [ "$curdir" = "$gitreponame" ]; then
  while :
  do
    # loop infinitely
    static_dir_last_update=$(find $static_dir -type f -printf '%Ts\n' | sort -k1,1nr | head -1)
    git_static_dir_last_update=$(find $git_static_dir -type f -printf '%Ts\n' | sort -k1,1nr | head -1)
    if (( static_dir_last_update > git_static_dir_last_update)); then
      echo "Updateing git static folder"
      rsync -avu --delete $static_dir/ $git_static_dir
      #copy over 404 if exists
      [[ -e $git_static_dir/404_not_found/index.html ]] && cp $git_static_dir/404_not_found/index.html $git_static_dir/404.html
      sudo -u witch git pull
      gitdiff=$(sudo -u witch git diff --ignore-all-space -I"secret=.*\"")
      if [ "$gitdiff" != "" ]; then
        #Update lastrun
        sudo date +%s > ./lastrun
        #Git commit and push
        sudo -u witch git add -A
        sudo -u witch git commit -m "`date`"
        sudo -u witch git push
      else
        echo "No changes since last run."
      fi
    fi
    echo "sleeping for a minute..."
    sleep 60
  done
else
  echo "Error: Set current directory to the repo and then rerun."
  exit 1
fi
