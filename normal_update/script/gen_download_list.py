#!/usr/bin/env python
#coding: utf-8

import sys

if __name__=='__main__':
    if len(sys.argv) != 6:
        print 'Usage : %s <url_list> <download_list> <prefix> <all_id> <set_ftr_id>' % sys.argv[0]
        sys.exit(1)
	
    #read the id existed
    f = open(sys.argv[4], 'r')
    all_id_set = set()
    for l in f:
        id = int(l.strip())
        all_id_set.add(id)
    f.close()


    f_in = open(sys.argv[1], 'r') #in file
    f_out = open(sys.argv[2], 'w') #out file
    f_set = open(sys.argv[5], 'a')
    prefix = sys.argv[3] #download dir

    for l in f_in:
        fields = l.strip().split('/')
        id = int(fields[-1].strip('.ftr')) #ftr id

        if id not in all_id_set:
            path = '%s/%d/%d/%d.ftr' %(prefix, id%200, id/100%200, id)
            f_out.write('%d\t%s\t%s\n' %(id, l.strip(), path))
            f_set.write('%d\n' %id)

    f_in.close()
    f_out.close()
    f_set.close()



