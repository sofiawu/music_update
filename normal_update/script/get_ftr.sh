#! /bin/bash +x

while read l; do
    url=`echo $l |awk '{print $2}'`
    path=`echo $l |awk '{print $3}'`
    wget ${url} -a $2 -O ${path}
done < $1
