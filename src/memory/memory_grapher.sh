#!/bin/sh

RRD=memory.rrd

if  [ ! -e $RRD ] ;
then
    echo Creating database...
    rrdtool create $RRD \
        --step 300 \
        --start 0 \
        DS:total:GAUGE:600:U:U \
        DS:free:GAUGE:600:U:U \
        RRA:AVERAGE:0.5:1:600 \
        RRA:AVERAGE:0.5:6:700 \
        RRA:AVERAGE:0.5:24:775 \
        RRA:AVERAGE:0.5:288:797 \
        RRA:MAX:0.5:1:600 \
        RRA:MAX:0.5:6:700 \
        RRA:MAX:0.5:24:775 \
        RRA:MAX:0.5:444:797
fi

total=`cat /proc/meminfo|head -1|awk '{print $2}'`
free=`cat /proc/meminfo|head -2|tail -1|awk '{print $2}'`

rrdtool update $RRD N:$total:$free

CTID=$(echo $RRD | sed 's/.rrd$//')

# list of intervals, 1d = last day, 1w = last week and so on
for INT in 1h 1d 1w 1m 1y
do
    /usr/bin/rrdtool graph images/${CTID}-${INT}.png \
        --start now-$INT --end now \
        --base 1024 \
        -w 650 -h 250 \
        --title "Memory Usage - Interval $INT" \
        --color CANVAS#555555 \
        --color BACK#555555 \
        --color FONT#ffffff \
        --border 0 \
        DEF:total=$RRD:total:AVERAGE \
        DEF:free=$RRD:free:AVERAGE \
        CDEF:used=total,free,- \
        CDEF:percent_used=100,used,total,/,* \
        CDEF:used_MB=used,1024,/ \
        CDEF:total_MB=total,1024,/ \
        AREA:percent_used#0081EB:"Percent used" \
        VDEF:total_ave=total_MB,AVERAGE \
        VDEF:used_max=used_MB,MAXIMUM \
        VDEF:used_ave=used_MB,AVERAGE \
        GPRINT:used_max:"max\: %.02lf MB" \
        GPRINT:used_ave:"ave\: %.02lf MB" \
        GPRINT:total_ave:"total\: %.0lf MB"
done
