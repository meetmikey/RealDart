#!/bin/sh

ps aux | grep "node" | grep "grunt" | grep -v "grep" | awk '{print $2}' | xargs kill -9