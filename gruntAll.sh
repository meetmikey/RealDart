#!/bin/sh

cd $REAL_DART_HOME

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