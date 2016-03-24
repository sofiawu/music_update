#!/usr/bin/env python
#coding: utf-8

import sys

if __name__=='__main__':
    if len(sys.argv) != 6:
        print 'Usage : %s <ftr_prefix> <music_id_list> <train_list> <idmap> <offset>' % sys.argv[0]
        exit(1)

    offset = int(sys.argv[5])

    f_in = open(sys.argv[2], 'r')
    f_out = open(sys.argv[3], 'w')
    f_idmap_out = open(sys.argv[4], 'w')

    f_out.write('%d\n' %offset)

    count = 0
    for line in f_in:
        try:
            music_id = int(line.strip())
            track_id = music_id + 30000000

            ftr_path = '%s/%d/%d/%d.ftr' %(sys.argv[1], track_id % 200, track_id / 100 % 200, track_id)
            f_out.write('%d\t%s\n' %(count, ftr_path))
            f_idmap_out.write('%d\t%d\n' %(offset + count, track_id))

            count = count + 1
        except ValueError:
            print line

    f_in.close()
    f_out.close()
    f_idmap_out.close()

        

