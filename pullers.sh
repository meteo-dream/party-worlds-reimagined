#!/bin/sh
git reset --hard
cd engine
git reset --hard
cd ..
git pull
git submodule update --remote
