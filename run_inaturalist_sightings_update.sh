#!/bin/bash
source /home/vagrant/.bashrc
source /home/vagrant/.bash_profile
echo "stuff from run_accounting bash" >> /home/vagrant/cronlog
env >> /home/vagrant/cronlog
if ps -ef | grep -v grep | grep inaturalist_sightings:update ; then
  exit 0
else
  echo "Inside else"
  cd /home/vagrant/mainline/biosmart
  RAILS_ENV=development bundle exec rake inaturalist_sightings:update[,,5] 
  exit 0
fi
