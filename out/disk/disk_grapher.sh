#!/bin/sh

RRD=disk.rrd

if  [ ! -e $RRD ] ;
then
    echo Creating database...
    rrdtool create disk.rrd \
        --step 300 \
        --start 0 \
        DS:usage:GAUGE:600:U:U \
        RRA:AVERAGE:0.5:1:600 \
        RRA:AVERAGE:0.5:6:700 \
        RRA:AVERAGE:0.5:24:775 \
        RRA:AVERAGE:0.5:288:797 \
        RRA:MAX:0.5:1:600 \
        RRA:MAX:0.5:6:700 \
        RRA:MAX:0.5:24:775 \
        RRA:MAX:0.5:444:797
fi

usage=`df -h|head -2|tail -1|awk '{print $5}'|sed -e 's/%//'`

rrdtool update $RRD N:$usage

CTID=$(echo $RRD | sed 's/.rrd$//')

# list of intervals, 1d = last day, 1w = last week and so on
for INT in 1h 1d 1w 1m 1y
do
    /usr/bin/rrdtool graph images/${CTID}-${INT}.png \
        --start now-$INT --end now \
        -w 650 -h 250 \
        --title "Percent Disk Used - Interval $INT" \
        DEF:usage=$RRD:usage:AVERAGE \
        AREA:usage#aea:"Percent Used" \
        LINE1:usage#0e0 \
        VDEF:usage_max=usage,MAXIMUM \
        VDEF:usage_ave=usage,AVERAGE \
        GPRINT:usage_max:"max\: %.0lf%%" \
        GPRINT:usage_ave:"ave\: %.0lf%%" 
done
