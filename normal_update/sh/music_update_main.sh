#! /bin/bash +x

source global_var.sh


#check the current set index 
set_index=0
for i in {0..13}
do
	if [ -f "$CONF_DIR/set$i.index" ]; then 
		set_index=$i
		break
	fi
done

HASH_TABLE_SET=$OUTPUT_DIR/set${set_index}

DATE=$(date -d "1 day ago" +%Y%m%d)

#if l2 cache update is not finished, wait for some time
if [ ! -f $BASE_DIR/l2cache_update.finish ]; then
	sleep 120
fi

#recycle 
set_count=`wc -l $HASH_TABLE_SET/idmap.dat | awk '{print $1}'`
if [ $set_count -gt 490000 ]; then
	$BIN_DIR/GenInvertedIndex $HASH_TABLE_SET/train.txt $HASH_TABLE_SET/convertHashFile_new.dat $HASH_TABLE_SET/Norm.dat
	if [ $? == 0 ]; then
		cp $HASH_TABLE_SET/idmap.${set_index} $HASH_TABLE_SET/idmap.dat
		rm -f $HASH_TABLE_SET/ftr_id_uniq.txt
		touch $HASH_TABLE_SET/ftr_id_uniq.txt
	else
		exit 1
	fi
fi


#update
./music_update.sh $set_index $DATE
if [ $? != 0 ]; then
	echo "music update failed ..."
	exit 1
fi


#check current set
if [ ! -f "$HASH_TABLE_SET/idmap.dat" ]; then
	echo "file not exist"
	exit 1
fi

count=`wc -l $HASH_TABLE_SET/idmap.dat | awk '{print $1}'`
if [ $count -gt 500000 ]; then
	rm -f "$CONF_DIR/set${set_index}.index"

	set_index=$(($set_index + 1))
	if [ $set_index == 14 ]; then
		set_index=0
	fi
	
	touch "CONF_DIR/set${set_index}.index"
fi
