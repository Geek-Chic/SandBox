#!/bin/bash

# File Name:start.sh
# Description: run the docker
# @Author: evil
# Created Time:Tue 10 Feb 2015 02:26:31 PM CST

MyHost=evil
sudo docker build -t ${MyHost}/centos6 .
sudo docker run  -t -i ${MyHost}/centos6 /bin/bash
