#! /bin/bash -x

#the root dir -> /data1/music_update/
BASE_DIR=`cd "$(dirname "$0")"; cd ..; cd ..; pwd`

#output dir -> /data1/music_update/output/
OUTPUT_DIR=$BASE_DIR/normal_update/output

#codes dir -> /data1/music_update/src/
SRC_DIR=$BASE_DIR/normal_update/src

#execute program dir -> /data1/music_update/src/
BIN_DIR=$BASE_DIR/bin

#/data1/music_update/list
LIST_DIR=$BASE_DIR/normal_update/list

#configure file dir -> /data1/music_update/conf/
CONF_DIR=$BASE_DIR/normal_update/conf

#log dir -> /data1/music_update/log/
LOG_DIR=$BASE_DIR/normal_update/log

#/data1/music_update/ftr
FTR_DIR=$BASE_DIR/ftr

#/data1/music_update/workspace
WORKSPACE_DIR=$BASE_DIR/normal_update/workspace

#/data1/music_update/backup
BACKUP_DIR=$BASE_DIR/normal_update/backup

PYTHON=/usr/local/environment/python/bin/python
