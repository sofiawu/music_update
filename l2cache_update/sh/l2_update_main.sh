#! /bin/bash +x

#This script is used to download tdw files
#Author : sofiawu
#Last Change Date: 2016.02.02

PYTHON=/usr/local/environment/python/bin/python

#################

BASE_DIR=` cd "$(dirname "$0")"; cd ..; cd ..; pwd`

export JAVA_HOME=$BASE_DIR/software/jdk1.6.0_37

HADOOP_HOME=$BASE_DIR/software/hadoop-0.20.1-client

L2_UPDATE_DIR=$BASE_DIR/l2cache_update

FTR_DIR=$BASE_DIR/ftr

BIN_DIR=$BASE_DIR/bin

##

WORKSPACE_DIR=$L2_UPDATE_DIR/workspace

SH_DIR=$L2_UPDATE_DIR/sh

DATA_DIR=$L2_UPDATE_DIR/data

LOG_DIR=$L2_UPDATE_DIR/log

BACKUP_DIR=$L2_UPDATE_DIR/backup

if [ $# -eq 0 ]; then
    TIME_NOW=`date -d 1 day ago +"%Y%m%d"`
else
    TIME_NOW=$1
fi

#The path for saving tdw data
TDW_DATA_DIR=$L2_UPDATE_DIR/tdw_data
if [ ! -d $TDW_DATA_DIR/${TIME_NOW} ]; then
    mkdir $TDW_DATA_DIR/${TIME_NOW}
else
    rm -rf $TDW_DATA_DIR/*
fi


#####################################functions#####################################

function get_tdw_data() {
	$HADOOP_HOME/bin/hadoop fs -Dfs.default.name=hdfs://tl-if-nn-tdw.tencent-distribute.com:54310 -Dhadoop.job.ugi=tdw_sofiawu:wuminhui,g_wxg_weixin_common -get /stage/outface/WXG/g_wxg_wxt_wx_pr_scan_images/log_10467/$TIME_NOW/* $TDW_DATA_DIR/${TIME_NOW}/

	cat $TDW_DATA_DIR/${TIME_NOW}/* > $WORKSPACE_DIR/tdw_data.$TIME_NOW

	cut -f1 $WORKSPACE_DIR/tdw_data.$TIME_NOW > $WORKSPACE_DIR/music_id.$TIME_NOW
} 


function get_top4k() {
	cd $WORKSPACE_DIR

	head -n 4228 music_id.$TIME_NOW > top_4k_music_id.$TIME_NOW
	$PYTHON $SH_DIR/make_train_list.py $FTR_DIR top_4k_music_id.$TIME_NOW top_4k_train_list.$TIME_NOW $DATA_DIR/top4k/top4k_idmap.dat 99000000

	$BIN_DIR/GenInvertedIndex top_4k_train_list.$TIME_NOW $DATA_DIR/top4k/top4k_hashTable.dat $DATA_DIR/top4k/top4k_norm.dat > $LOG_DIR/top4k_gen_$TIME_NOW.log
}

function get_top20w() {
	cd $WORKSPACE_DIR

	cat music_id.$TIME_NOW | tail +n 4229 | head -n 200000 > top_20w_music_id.$TIME_NOW
	$PYTHON $SH_DIR/make_train_list.py $FTR_DIR top_20w_music_id.$TIME_NOW top_20w_train_list.$TIME_NOW $DATA_DIR/top20w/idmap.dat 0

	$BIN_DIR/GenInvertedIndex top_20w_train_list.$TIME_NOW $DATA_DIR/top20w/convertHashFile_new.dat $DATA_DIR/top20w/Norm.dat > $LOG_DIR/top20w_gen_$TIME_NOW.log
}

function rsync_top4k() {
	rsync -az $DATA_DIR/top4k/* qspace@10.193.14.24::top4k
}

function rsync_top20w() {
	while read line 
	do
		ip=`echo $line | awk '{print $1}'`
		location=`echo $line | awk '{print $2}'`

		#rsync data
		rsync -az $DATA_DIR/top20W/* qspace@$ip::l2pushdata

		#restart server
		if [ $? == 0 ]; then
			/home/qspace/bin/btssh -D $location qspace@$ip "nohup mv /home/qspace/data/convertHashFile_new.dat /home/qspace/data/l2pushdata/convertHashFile_new.bak &"
			sleep 30
			/home/qspace/bin/btssh -D $location qspace@$ip "nohup mv /home/qspace/data/idmap.dat /home/qspace/data/l2pushdata/idmap.bak &"
			sleep 30
			/home/qspace/bin/btssh -D $location qspace@$ip "nohup mv /home/qspace/data/Norm.dat /home/qspace/data/l2pushdata/Norm.bak &"
			sleep 30
			
			sleep 30

			/home/qspace/bin/btssh -D $location qspace@$ip "nohup mv /home/qspace/data/l2pushdata/convertHashFile_new.dat /home/qspace/data/ &"
			sleep 30
			/home/qspace/bin/btssh -D $location qspace@$ip "nohup mv /home/qspace/data/l2pushdata/idmap.dat /home/qspace/data/ &"
			sleep 30
			/home/qspace/bin/btssh -D $location qspace@$ip "nohup mv /home/qspace/data/l2pushdata/Norm.dat /home/qspace/data/ &"
			sleep 30

			sleep 30

			/home/qspace/bin/btssh -D $location qspace@$ip "nohup /home/qspace/mmsprmusicsprl2cache/bin/mmsprsvrConsole restart &"
		fi
	done < $SH_DIR/l2cache_servers.txt
}

function post_process() {
    if [ -d $BACKUP_DIR/$TIME_NOW ]; then
        rm -rf $BACKUP_DIR/$TIME_NOW
    fi

    mkdir $BACKUP_DIR/$TIME_NOW

    mv $WORKSPACE_DIR/* $BACKUP_DIR/$TIME_NOW/

    if [ ! -d $LOG_DIR/$TIME_NOW ]; then
        mkdir $LOG_DIR/$TIME_NOW
    fi

    mv $LOG_DIR/*_$TIME_NOW* $LOG_DIR/$TIME_NOW/
}

#####################################main###########################################

date

rm -f $BASE_DIR/l2cache_update.finish

echo "... download tdw data ..."
get_tdw_data
if [ $? != 0 ]; then
	echo "	download tdw data failed ..."
	exit 1
fi

echo "... generate top 4k hash table ..."
#get_top4k
if [ $? != 0 ]; then
	echo "	get top 4k failed ..."
	exit 1
fi

echo "... generate top 20w hash table ..."
#get_top20w
if [ $? != 0 ]; then
	echo "	get top 20w failed ..."
	exit 1
fi

#touch $BASE_DIR/l2cache_update.finish

echo "... rsync data to top 4k ..."
#rsync_top4k

echo "... rsync data to top 20w ..."
#rsync_top20w

#post_process

date











