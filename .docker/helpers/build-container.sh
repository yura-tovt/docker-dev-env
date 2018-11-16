#!/usr/bin/env bash
docker build --build-arg UID=1000 --no-cache --tag %IMAGE NAME%:0.1 .
docker create --volume %FULL PATH TO PROJECT FOLDER%:/var/www/app --publish 8099:80 --publish 8098:81 --name %IMAGE NAME%
