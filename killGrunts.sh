#!/bin/sh

echoPrefix="killGrunts:"

echo "$echoPrefix starting..."

gruntProcessIds=$(ps aux | grep "node" | grep "grunt" | grep -v "grep" | awk '{print $2}')

if [ -z "$gruntProcessIds" ]
then
  echo "$echoPrefix no running grunts."
else
  echo $gruntProcessIds | xargs kill -9
fi

echo "$echoPrefix done."