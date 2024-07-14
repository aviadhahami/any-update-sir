#!/bin/bash


# Echo to a file with the current time stamp pre-upload
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
echo "some content" > ./$DATE.txt