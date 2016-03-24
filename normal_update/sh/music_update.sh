#! /bin/bash +x

source global_var.sh

if [ ! $# == 2 ]; then
    echo "Usage: $0 set_index Date"
    exit 1
fi

DATE=$2

set_index=$1
seq_num=$(($1 + 1))
set_list=$(seq $seq_num)
offset=$(($set_index * 1000000))

HASH_TABLE_SET=$OUTPUT_DIR/set$(($set_index))

#########################################functions######################################

function check_file() {
    if [ $# -ne 2 ]; then
        echo "Usage: check_file file msg"
        exit 1
    fi

    file=$1
    msg=$2
    if [ ! -f $file ]; then
        echo $msg
        exit 1
    fi
}

function check_return() {
    if [ $# -ne 2 ]; then
        echo "Usage: check_return ret msg"
        exit 1
    fi

    ret=$1
    msg=$2
    if [ $ret != "0" ]; then
        echo $msg
        exit 1
    fi
}

function get_qqmusic_ftr() {
    echo "... get upload file ..."
    rsync -az qspace@10.173.14.85::qq_music/upload_list/upload${DATE}_*.txt $WORKSPACE_DIR

    cd $WORKSPACE_DIR

    cat upload${DATE}_*.txt >> upload${DATE}.txt
    rm -f upload${DATE}_*.txt

    if [ /home/qspace/upload/emergency_upload_list.txt ]; then
        cat /home/qspace/upload/emergency_upload_list.txt >> upload${DATE}.txt
        rm -f $LIST_DIR/emergency_upload_list.txt
    fi

    sort upload$DATE.txt | uniq > tmp.txt
    mv tmp.txt upload$DATE.txt 

    count=`wc -l upload$DATE.txt | awk '{print $1}'`
    echo "... ftr nums: $count ..."
    if [ $count == "0" ]; then
        touch $BASE_DIR/update_finish.tag
        echo "no update ftr"
        return 1
    elif [ $count -gt 10000 ]; then
        echo "too many ftr, just exit to avoid updating too long time. "
        cat upload$DATE.txt >> $LIST_DIR/not_update_list.txt
        return 1
    fi

    #echo "... get id3 file ..."
    #rsync -az qspace@10.173.14.85::qq_music/id3_list/id3_${DATE}.txt $WORKSPACE_DIR
    #check_file "${WORKSPACE_DIR}/id3_${DATE}.txt" "no id3_${DATE}.txt"

    return 0
}

function download_ftr() {
    cd $WORKSPACE_DIR

    if [ -f all_ftr_id_uniq_$DATE.txt ]; then
	rm -f all_ftr_id_uniq_$DATE.txt
    fi

    for i in {0..13}
    do
        cat $OUTPUT_DIR/set${i}/ftr_id_uniq.txt >> all_ftr_id_uniq_$DATE.txt
    done

    cp $HASH_TABLE_SET/ftr_id_uniq.txt ftr_id_uniq_$DATE.txt

    $SRC_DIR/gen_download_list.py upload$DATE.txt download_$DATE.txt $FTR_DIR \
        all_ftr_id_uniq_$DATE.txt ftr_id_uniq_$DATE.txt

    $SRC_DIR/get_ftr.sh download_$DATE.txt $LOG_DIR/download_$DATE.log

    cut -f 1 download_$DATE.txt > ftr_id_$DATE.txt
}

function delete_useless_ftr(){
    cd $WORKSPACE_DIR

    $BIN_DIR/del_short_and_long_songs ftr_id_$DATE.txt $FTR_DIR/ short_id_$DATE.txt \
        long_id_$DATE.txt not_exist_id_$DATE.txt > $LOG_DIR/del_$DATE.log

    cat short_id_$DATE.txt long_id_$DATE.txt not_exist_id_$DATE.txt > del_id_$DATE.txt
    $SRC_DIR/del_id.py ftr_id_$DATE.txt del_id_$DATE.txt 
}

function filter_in_set(){
    cd $WORKSPACE_DIR

    #for i in ${set_list[@]}; do
    for i in {0..13} 
    do
        set_count=`wc -l $OUTPUT_DIR/set${i}/idmap.dat | awk '{print $1}'`
        if [ $set_count -gt 1 ]; then
            echo "filter in set $i"
            $BIN_DIR/cluster $CONF_DIR/cfg.$i $FTR_DIR/ ftr_id_$DATE.txt cluster_$DATE.$i > $LOG_DIR/cluster_$DATE.$i.log
        fi
    done 

    cat cluster_$DATE.* > cluster${DATE}.txt
    cut -f1 cluster${DATE}.txt > cluster_id_${DATE}.txt
    $SRC_DIR/del_id.py ftr_id_$DATE.txt cluster_id_${DATE}.txt
}

function filter_in_self() {
    cd $WORKSPACE_DIR

    #make self cluster
    $SRC_DIR/make_cluster_train_list.py ftr_id_$DATE.txt $FTR_DIR/ train_cluster_$DATE.tmp
    $BIN_DIR/GenInvertedIndex train_cluster_$DATE.tmp hashTable.tmp norm.tmp > $LOG_DIR/gen_$DATE.log
    check_return $? "GenInvertedIndex failed ..."

    $SRC_DIR/make_id_map_list.py train_cluster_$DATE.tmp id_map.tmp
    $BIN_DIR/cluster_delta $CONF_DIR/cfg.delta $FTR_DIR/ ftr_id_$DATE.txt id_map.tmp cluster_$DATE.delta > $LOG_DIR/cluster_delta_$DATE.log
    $SRC_DIR/merge_cluster_result.py cluster_$DATE.delta

    cut -f1 cluster_$DATE.delta > delta_id_$DATE.txt
    #$SRC_DIR/filter_in_id3.py id3_$DATE.txt cluster_$DATE.delta delta_id_$DATE.txt
}


function filter_not_unique_ftr() {
    cd $WORKSPACE_DIR

    cp $HASH_TABLE_SET/idmap.dat id_map_$DATE.txt

    echo "... filter not unique in sets ..."
    filter_in_set
    check_return $? "filter step one failed ..."

    echo "... filter not unique in self data ..."
    filter_in_self
    check_return $? "filter step two failed ..."
}

function train_delta() {
    cd $WORKSPACE_DIR

    $SRC_DIR/make_delta_train_list.py id_map_$DATE.txt $FTR_DIR/ $offset delta_id_$DATE.txt train_delta_$DATE.list

    $BIN_DIR/GenInvertedIndex train_delta_$DATE.list hashTable_delta.dat norm_delta.dat > $LOG_DIR/gen_$DATE.log
    check_return $? "GenInvertedIndex failed"
}

function merge_hash_table() {
    cd $WORKSPACE_DIR

    $BIN_DIR/MergeInvertedIndex $HASH_TABLE_SET/convertHashFile_new.dat $HASH_TABLE_SET/Norm.dat hashTable_delta.dat norm_delta.dat \
         hashTable_$DATE.dat norm_$DATE.dat
    check_return $? "MergeInvertedIndex failed"

    mv hashTable_$DATE.dat $HASH_TABLE_SET/convertHashFile_new.dat
    mv norm_$DATE.dat $HASH_TABLE_SET/Norm.dat
}


##########################################################################################################################

function Prepare(){

############get qq_music upload files#######
    echo "... get ftr ..."
    get_qqmusic_ftr
    check_return $? "get ftr end ..."

###########download ftr files###############
    echo "... download ftr ..."
    download_ftr
    check_return $? "download ftr failed ..."

##########delete useless ftr id#############
    echo "... filter ftr id ..."
    delete_useless_ftr
    check_return $? "delete useless ftr id failed ..."

    filter_not_unique_ftr
    check_return $? "filter not unique ftr id failed ..."
}

function train() {
#########train on today data################
    echo "... train delta hash table ..."
    train_delta
    check_return $? "train delta failed ..."

#########merge hash table###################
    echo "... merge hash table ..."
    merge_hash_table
    check_return $? "merge hash table failed ..."
}

function post_process() {
    cp $WORKSPACE_DIR/ftr_id_uniq_$DATE.txt $HASH_TABLE_SET/ftr_id_uniq.txt
    cp $WORKSPACE_DIR/id_map_$DATE.txt $HASH_TABLE_SET/idmap.dat

    #delete the temporary hash table
    rm -f $WORKSPACE_DIR/hashTable.tmp 
    rm -f $WORKSPACE_DIR/norm.tmp
    rm -f $WORKSPACE_DIR/hashTable_delta.dat
    rm -f $WORKSPACE_DIR/norm_delta.dat

    #copy the train list into the set directory
    cat $WORKSPACE_DIR/train_delta_$DATE.list | tail -n +1 >> $HASH_TABLE_SET/train_list.txt
    
    #back up 
    if [ -d $BACKUP_DIR/$DATE ]; then
        rm -rf $BACKUP_DIR/$DATE
    fi

    mkdir $BACKUP_DIR/$DATE

    mv $WORKSPACE_DIR/* $BACKUP_DIR/$DATE/

    if [ ! -d $LOG_DIR/$DATE ]; then
        mkdir $LOG_DIR/$DATE
    fi

    mv $LOG_DIR/*_$DATE* $LOG_DIR/$DATE/
}

function copy_hashTable() {
    for((i=0;i<60;i++));do
        if [ -f "$OUTPUT_DIR/upload_set/distribute.finish" ]; then
            break
        else
            sleep 600
        fi
    done

    if [ -f "$OUTPUT_DIR/upload_set/distribute.finish" ]; then
        rm -f $OUTPUT_DIR/upload_set/distribute.finish
        cp $HASH_TABLE_SET/*.dat $OUTPUT_DIR/upload_set/
        cp $HASH_TABLE_SET/svr.lst $OUTPUT_DIR/upload_set/
        touch $OUTPUT_DIR/upload_set/distribute.finish
    fi
}


########################################################MAIN################################################################

date

echo "Prepare the train list ..."
Prepare
check_return $? "Prepare failed ..."

echo "Training ..."
train 
check_return $? "Train failed ..."

echo "Post process ..."
post_process

echo "Copy set data to upload dir ..."
copy_hashTable

date

