#!/bin/bash
#Argument order = pi -d date1~date2 -t time1~time2 -x plottype 

usage()
{
cat << EOF
usage: $0 options

This script plots the owping data.

OPTIONS:
   -h      Show this message
   -d	   BeginDate~EndDate
   -t      BeginTime~EndTime 
   -x      Plot type. Can be l (LOSS), d (DELAY), j (JITTER).
EOF
}
  
fileSetUp()
{
/bin/cat << EOM > $GNUFILE
set terminal canvas dashed size 800,640 rounded enhanced fsize 10 lw 0.8 fontscale 1 name "gnuplot_canvas" mouse jsdir "http://perfsonar-lab.nts.wustl.edu.nts.wustl.edu/test/index.html/"
set grid layerdefault   lt 0 linecolor 0 linewidth 0.500,lt 0 linecolor 0 linewidth 0.500
set xzeroaxis
set ytics  norangelimit
set autoscale
set xdata time 
set timefmt "%Y-%m-%dT%H:%M:%S"
set format x "%b%d\n%H:%M"
set title "Owping $PLOT_TITLE" font "/usr/share/fonts/liberation/LiberationSans-Regular.ttf,12"
EOM
}

LAST_MIN=$(($(/bin/date +%M)-1))
if [ "${LAST_MIN}" -ge "0" ]; then
    if [ "${LAST_MIN}" -lt "10" ]; then
	TIME_DEFAULT="00:00~$(/bin/date +%H):0${LAST_MIN}"
    else
	TIME_DEFAULT="00:00~$(/bin/date +%H):${LAST_MIN}"
    fi
else
    LAST_HOUR=$(($(/bin/date +%H)-1))
    TIME_DEFAULT="00:00~${LAST_HOUR}:59"
fi
DATE_DEFAULT="$(/bin/date +%m-%d-%y)"
PLOTX="0"
OPTIND=2
DATE_ARGV=""
TIME_ARGV=""
FILESET="/usr/local/bin/owping/allFiles.txt"
GNUFILE="/usr/local/bin/owping/gnu_script.gpl"
FILEOUT="/usr/local/bin/owping/$1.js"
FILEDAT="/usr/local/bin/owping/data"
while getopts “:hd:t:x:” OPTION; do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         t)
             TIME_ARGV=$OPTARG
             ;;
         d)
             DATE_ARGV=$OPTARG
             ;;
         x)
             PLOTX=$OPTARG
             ;;
         \?)
             usage
	     exit 1
             ;;
	 :)
	     echo "Missing option argument for -$OPTARG" >&2; 
	     exit 1;;
         *) 
	     echo "Unimplemented option: -$OPTARG" >&2; 
	     exit 1;;
     esac
done
DATE1=$(echo $DATE_ARGV | cut -f1 -d~)
DATE2=$(echo $DATE_ARGV | cut -f2 -d~)
if [ "$DATE1" == "" ]; then
    DATE1=$DATE_DEFAULT
fi
if [ "$DATE2" == "" ]; then
    DATE2=$DATE_DEFAULT
fi
TIME1="T$(echo $TIME_ARGV | cut -f1 -d~)"
TIME2="T$(echo $TIME_ARGV | cut -f2 -d~)"
if [ "$TIME1" == "T" ]; then
    TIME1="T$(echo $TIME_DEFAULT | cut -f1 -d~)"
fi
if [ "$TIME2" == "T" ]; then
    TIME2="T$(echo $TIME_DEFAULT | cut -f2 -d~)"
fi
echo "${TIME1}~${TIME2}"
FILE1="/var/log/owlogs/$1/$DATE1.log"
FILE2="/var/log/owlogs/$1/$DATE2.log"
ls "/var/log/owlogs/$1/" > $FILESET
beginTime=$(cat $FILE1 | grep -n $TIME1 | head -1 | cut -f1 -d:)
endTime=$(cat $FILE2 | grep -n $TIME2 | head -1 | cut -f1 -d:)
beginDate=$(cat $FILESET | grep -n $DATE1 | head -1 | cut -f1 -d:)
endDate=$(cat $FILESET | grep -n $DATE2 | head -1 | cut -f1 -d:)
day=$beginDate
column1=2
column2=$(($column1+1))
delayflag=0
PLOT_TITLE="Loss (%) vs Time"
if [ $PLOTX == 'j' ]; then
    column1=$(($column1+8))
    column2=$(($column1+1))
    PLOT_TITLE="Jitter (ms) vs Time"
elif [ $PLOTX == 'd' ]; then
    column1=$(($column1+2))
    column2=$(($column1+3))
    delayflag=1
    PLOT_TITLE="Delay (ms) vs Time"
fi
fileSetUp
begin=0
end=0
while [ "$day" -le "$endDate" ];do
    DAY=$(awk 'FNR == '${day}' {print $'1'}' < $FILESET)
    begin=1
    FILE1="/var/log/owlogs/$1/$DAY"
    end=$(wc -l $FILE1 | cut -f1 -d ' ')
    if [ "$day" == "$beginDate" ];then
	begin=$beginTime
	echo -n $beginTime
    fi
    if [ "$day" == "$endDate" ];then
	end=$endTime
	echo -n $endTime
    fi
    echo "$(sed -n ${begin},${end}p $FILE1 >> $FILEDAT)"
    day=$(($day+1))
done
echo "plot \"${FILEDAT}\" u 1:${column1} t \"Received from $1\" with lines lw 2, \"${FILEDAT}\" u 1:${column2} t \"Sent to $1\" with lines lw 2" >> $GNUFILE 
/usr/local/bin/gnuplot $GNUFILE > $FILEOUT
rm $FILEDAT
rm $GNUFILE
rm $FILESET
echo -n "success"