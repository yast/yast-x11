#!/bin/sh

PATH=$PATH:/usr/lib/YaST2/bin
cd /usr/share/YaST2/clients

#y2base test_proposal '("hardware")' qt --nothreads -geometry 800x600
y2base test_proposal '("hardware")' qt -geometry 800x600
