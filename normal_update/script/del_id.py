#!/usr/bin/env python
#coding: utf-8

import sys

if __name__=='__main__':
    if len(sys.argv) != 3:
        print 'Usage : %s <ftr_id_list> <del_id_list>' % sys.argv[0]
        exit(1)

    del_id_set = set()
    f = open(sys.argv[2], 'r')
    for line in f:
        try:
            id = int(line.strip())
            del_id_set.add(id)
        except:
            print 'convert error'

    f.close()

    ftr_id_list = []
    f = open(sys.argv[1], 'r')
    for line in f:
        try:
            id = int(line.strip())
            if id not in del_id_set:
                ftr_id_list.append(id)
        except:
            print 'convert error'

    f.close()

    f = open(sys.argv[1], 'w')
    for id in ftr_id_list:
        f.write('%d\n' % id)

    f.close()
