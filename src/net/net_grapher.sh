#!/bin/sh -x

RRD=net.rrd

if  [ ! -e $RRD ] ;
then
    echo Creating database...
    rrdtool create net.rrd \
        --step 300 \
        --start 0 \
        DS:input:COUNTER:600:U:U \
        DS:output:COUNTER:600:U:U \
        RRA:AVERAGE:0.5:1:600 \
        RRA:AVERAGE:0.5:6:700 \
        RRA:AVERAGE:0.5:24:775 \
        RRA:AVERAGE:0.5:288:797 \
        RRA:MAX:0.5:1:600 \
        RRA:MAX:0.5:6:700 \
        RRA:MAX:0.5:24:775 \
        RRA:MAX:0.5:444:797
fi

eval `grep venet0 /proc/net/dev | awk -F: '{print $2}' | \
       awk '{printf"CTIN=%s\nCTOUT=%s\n", $1, $9}'`

rrdtool update $RRD N:$CTIN:$CTOUT

CTID=$(echo $RRD | sed 's/.rrd$//')

# list of intervals, 1d = last day, 1w = last week and so on
for INT in 1h 1d 1w 1m 1y;
do
    /usr/bin/rrdtool graph images/${CTID}-${INT}.png \
        --start now-$INT --end now \
        -w 650 -h 250 \
        --title "Network Throughput - Interval $INT" \
        --color CANVAS#555555 \
        --color BACK#555555 \
        --color FONT#ffffff \
        --border 0 \
        DEF:in=$RRD:input:AVERAGE \
        DEF:out=$RRD:output:AVERAGE \
        CDEF:KB_out=out,1024,/ \
        VDEF:KB_out_max=KB_out,MAXIMUM \
        CDEF:KB_in=in,1024,/ \
        CDEF:KB_in1=KB_in,-1,* \
        VDEF:KB_in_max=KB_in,MAXIMUM \
        VDEF:KB_out_ave=KB_out,AVERAGE \
        VDEF:KB_in_ave=KB_in,AVERAGE \
        AREA:KB_out#0081EB:"eth0 out" \
        AREA:KB_in1#aea:"eth0 in" \
        GPRINT:KB_out_max:"max out\: %.2lf KB/s" \
        GPRINT:KB_out_ave:"ave out\: %.2lf KB/s" \
        GPRINT:KB_in_max:"max in\: %.2lf KB/s" \
        GPRINT:KB_in_ave:"ave in\: %.2lf KB/s"
done
