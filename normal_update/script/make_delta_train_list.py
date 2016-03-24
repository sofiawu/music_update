#!/usr/bin/env python
#coding: utf-8

import sys

if __name__=='__main__':
    if len(sys.argv) != 6:
        print 'Usage : %s <id_map> <pre_ftr_path> <offset> <delta_id> <train_list>' % sys.argv[0]
        exit(1)

    id_map = {}
    max_id = 0
    f = open(sys.argv[1], 'r')
    for line in f:
        fields = line.strip().split('\t')
        if len(fields) != 2:
            continue

        try:
            docID = int(fields[0])
            musicID = int(fields[1])
            id_map[docID] = musicID
            if max_id < docID:
                max_id = docID
        except:
            print 'convert error'
            continue

    f.close()

    f_id_map = open(sys.argv[1], 'a')
    f_in = open(sys.argv[4], 'r')
    f_out = open(sys.argv[5], 'w')

    count = 1
    offset = int(sys.argv[3])

    f_out.write('%d\n' %offset)
    for line in f_in:
        fields = line.strip().split('\t')

        try:	
            trackid = int(fields[0])
            docid = max_id + count

            path = '%s/%d/%d/%d.ftr' %(sys.argv[2], trackid % 200, trackid / 100 % 200, trackid)
            f_out.write('%d\t%s\n' %(docid - offset, path))
            f_id_map.write('%d\t%d\n' %(docid, trackid))
            count = count + 1
        except:
            print "convert error"
            continue


    f_in.close()
    f_out.close()
    f_id_map.close()

        

