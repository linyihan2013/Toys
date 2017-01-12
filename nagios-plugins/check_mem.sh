#!/usr/bin/env bash

#Set script name
SCRIPT=`basename ${BASH_SOURCE[0]}`

#Set default values
optMW=80
optMC=90

# help function
function printHelp {
  echo -e \\n"Help for $SCRIPT"\\n
  echo -e "Basic usage: $SCRIPT -w {warning} -c {critical}"\\n
  echo "Command switches are optional, default values for warning is 80% and critical is 90%"
  echo "-w - Sets warning value for Memory Usage. Default is 80%"
  echo "-c - Sets critical value for Memory Usage. Default is 90%"
  echo -e "-h  - Displays this help message"\\n
  echo -e "Example: $SCRIPT -w 80 -c 90"\\n
  exit 1
}

# regex to check is OPTARG an integer
re='^[0-9]+$'

while getopts :w:c:h FLAG; do
  case $FLAG in
    w)
      if ! [[ $OPTARG =~ $re ]] ; then
        echo "error: Not a number" >&2; exit 1
      else
        optMW=$OPTARG
      fi
      ;;
    c)
      if ! [[ $OPTARG =~ $re ]] ; then
        echo "error: Not a number" >&2; exit 1
      else
        optMC=$OPTARG
      fi
      ;;
    h)
      printHelp
      ;;
    \?)
      echo -e \\n"Option - $OPTARG not allowed."
      printHelp
      exit 2
      ;;
  esac
done

shift $((OPTIND-1))

array=( $(cat /proc/meminfo | egrep 'MemTotal|MemFree|Buffers|Cached|SwapTotal|SwapFree' |awk '{print $1 " " $2}' |tr '\n' ' ' |tr -d ':' |awk '{ printf("%i %i %i %i %i %i %i", $2, $4, $6, $8, $10, $12, $14) }') )

memTotal_k=${array[0]}
memTotal_b=$(($memTotal_k*1024))
memFree_k=${array[1]}
memFree_b=$(($memFree_k*1024))
memBuffer_k=${array[2]}
memBuffer_b=$(($memBuffer_k*1024))
memCache_k=${array[3]}
memCache_b=$(($memCache_k*1024))
memTotal_m=$(($memTotal_k/1024))
memFree_m=$(($memFree_k/1024))
memBuffer_m=$(($memBuffer_k/1024))
memCache_m=$(($memCache_k/1024))
memUsed_b=$(($memTotal_b-$memFree_b-$memBuffer_b-$memCache_b))
memUsed_m=$(($memTotal_m-$memFree_m-$memBuffer_m-$memCache_m))
memUsedPrc=$((($memUsed_b*100)/$memTotal_b))

message="MEMORY OK - Total: $memTotal_m MB - Used: $memUsed_m MB - Usaged: $memUsedPrc % | Memory Usage=$memUsedPrc %;;;;"


if [ $memUsedPrc -ge $optMC ]; then
  echo -e $message
  $(exit 2)
elif [ $memUsedPrc -ge $optMW ]; then
  echo -e $message
  $(exit 1)
else
  echo -e $message
  $(exit 0)
fi
