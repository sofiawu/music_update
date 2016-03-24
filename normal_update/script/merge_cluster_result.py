#!/usr/bin/env python

import sys

def addWord(theIndex, key, value):
    theIndex.setdefault(key, []).append(value)

def addFile(f_name, result):
    f = open(f_name, 'r')
    for line in f:
        fields = line.strip().split('\t')
        if len(fields) > 1:
            for id in fields[1:]:
                addWord(result, fields[0], id)
    f.close()

if __name__=='__main__':
    if len(sys.argv) != 2:
        print 'Usage: %s <cluster_reslut>' % sys.argv[0]
        exit(1)

    merge_result = {}
    addFile(sys.argv[1], merge_result)

    for (key,value) in merge_result.items():
       if not merge_result.has_key(key):
            continue

       for id in value:
            if id == key:
                continue

            if merge_result.has_key(id):
                if key not in merge_result[id]:
                    merge_result[key].remove(id)
                else:
                    merge_result.pop(id)
            else:
                merge_result[key].remove(id)

    f = open(sys.argv[1], 'w')
    for value in merge_result.values():
        if len(value) == 0:
            continue
        f.write(value[0])
        for i in range(1, len(value)):
            f.write('\t%s' %value[i])

        f.write('\n')

    f.close()
