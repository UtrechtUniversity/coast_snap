#!/bin/bash

# stop the Falcon server
sudo systemctl stop falcon_snap
# stop gunicorn
sudo pkill gunicorn

# folder used to store uploaded web contents
upload_folder="/home/kaand006/uploads"
# folder used to store coastline snaps
snaps_folder="/home/kaand006/snaps"

# cd into working directory
cd /home/kaand006/apps/coast_snap
# pull repo
git fetch origin
git reset --hard origin/master

# after pulling we can start the Falcon server again
sudo systemctl start falcon_snap

# cd into assets folder
cd assets
# compile frontend resources
npm install
# cd back into main folder
cd ..
# fetch dependencies
mix deps.get --only prod
# compile application
UPLOADS_DIR=$upload_folder SNAPS_DIR=$snaps_folder MIX_ENV=prod mix compile
# migrate the database
MIX_ENV=prod mix ecto.migrate
# compile assets (js, css, images)
npm run deploy --prefix ./assets
MIX_ENV=prod mix phx.digest
# overwrite the previous release with this one
sudo UPLOADS_DIR=$upload_folder SNAPS_DIR=$snaps_folder MIX_ENV=prod mix release --overwrite
# stop the previous release
sudo /home/kaand006/apps/coast_snap/_build/prod/rel/coast_snap/bin/coast_snap stop
# and start the current one
sudo /home/kaand006/apps/coast_snap/_build/prod/rel/coast_snap/bin/coast_snap daemon

# now we start pulling in the Python app
home="/home/kaand006/apps"
python_dir="$home/coast_snap/priv/python"
models_home="$home/coastsnap_assets"

mkdir -p $python_dir
cd $python_dir
# pull CoastSnapPy.git if needed
if [ ! -z $1 ] && [[ "$1" == "pull_coastsnappy" ]]
then
      echo "pull"
      git clone git@github.com:mathvansoest/CoastSnapPy.git
else
      echo "dont pull"
fi
# copy models
mkdir -p "$python_dir/CoastSnapPy/Objects/egmond/strandtent/models"
cp "$models_home/egmond/strandtent/"* "$python_dir/CoastSnapPy/Objects/egmond/strandtent/models"
mkdir -p "$python_dir/CoastSnapPy/Objects/egmond/zilvermeeuw/models"
cp "$models_home/egmond/zilvermeeuw/"* "$python_dir/CoastSnapPy/Objects/egmond/zilvermeeuw/models"

# copy rest server to appropriate location
cp "$models_home/falcon/rest_server.py" "$python_dir/CoastSnapPy/CoastSnapPy"
cd "$python_dir/CoastSnapPy/CoastSnapPy"
sudo -b nohup /home/kaand006/anaconda3/envs/coastsnappy/bin/gunicorn rest_server:app --env OUTPUT_PATH=/home/kaand006 </dev/null >/dev/null 2>&1