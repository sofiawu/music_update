#! /bin/bash +x

source global_var.sh

#wait for copy finish
for((i=0;i<60;i++));do
    if [ -f "$OUTPUT_DIR/upload_set/distribute.finish" ]; then
        break
    else
        sleep 600
    fi
done

if [ ! -f "$OUTPUT_DIR/upload_set/distribute.finish " ]; then
	exit 1
fi

rm -f $OUTPUT_DIR/upload_set/distribute.finish

#distribute the latest hash table to server
if [ -f $HASH_TABLE_SET/svr.lst ]; then
	while read line
	do
		ip=`echo $line | awk '{print $1}'`
		location=`echo $line | awk '{print $2}'`

		rsync -av $HASH_TABLE_SET/*dat $line::Data/ 
		#if success restart server
		if [ $? == 0 ]; then
			/home/qspace/bin/btssh -D $location qspace@$ip "nohup /home/qspace/mmsprsvr/bin/mmsprsvrConsole restart &" 
		fi
	done < $OUTPUT_DIR/upload_set/svr.lst
fi

touch $OUTPUT_DIR/upload_set/distribute.finish
