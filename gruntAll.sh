#!/bin/sh

echoPrefix="gruntAll:"

echo "$echoPrefix starting..."

cd $REAL_DART_HOME

./killGrunts.sh

cd client
grunt &
cd -

cd server/common
grunt &
cd -

cd server/tools
grunt &
cd -

cd server/web
grunt &
cd -

cd server/worker
grunt &
cd -

echo "$echoPrefix done."