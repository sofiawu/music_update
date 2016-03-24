#!/usr/bin/env python

import sys

if __name__=='__main__':

    if len(sys.argv) < 3:
        print 'Usage: %s <old_list> <new_list>' \
            % sys.argv[0]
        exit(1)

    old_list = open(sys.argv[1], 'r')
    new_list = open(sys.argv[2], 'w')

    offset = old_list.readline()
    offset = int(offset)

    for line in old_list:
        fields1 = line.split()
        
        if len(fields1) != 2:
            continue

        fields2 = fields1[1].split('/')

        id = int(fields1[0]) + offset

        tmp = '%d\t%s\n' % (id, fields2[-1].rstrip('.ftr'))
        new_list.write(tmp)

    new_list.close()
    old_list.close()
