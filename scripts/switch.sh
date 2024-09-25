#!/usr/bin/env bash

curl -X PATCH "http://[fd00::2:8000:0:2]:8080/rules/switch/$1/$2"
