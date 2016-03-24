#!/usr/bin/env python
#coding: utf-8

import sys

if __name__=='__main__':
    if len(sys.argv) != 4:
        print 'Usage : %s <id_list> <pre_ftr_path> <train_list>' % sys.argv[0]
        exit(1)

    f_id = open(sys.argv[1], 'r')
    f_train_list = open(sys.argv[3], 'w')
    f_train_list.write('%d\n' % 99000000)

    count = 0
    for line in f_id:
        try:
            id = int(line.strip())
            path = '%s/%d/%d/%d.ftr' %(sys.argv[2], id%200, id/100%200, id)
            f_train_list.write('%d\t%s\n' %(count, path))
            count += 1
        except:
            print 'convert error'

    f_id.close()
    f_train_list.close()

        

