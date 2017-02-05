PROGNAME=`basename $0`

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3
hostname="localhost"
port=80
status_page="nginx_status"
secure=0

print_help() {
    echo ""
    echo "$PROGNAME is a Nagios plugin to check whether nginx is running."
    echo "It also parses the nginx's status page to get requests and"
    echo "connections per second. You"
    echo "may have to alter your nginx configuration so that the plugin"
    echo "can access the server's status page."
    echo "The plugin is highly configurable for this reason. See below for"
    echo "available options."
    echo ""
    echo "$PROGNAME -H localhost -P 80 -s nginx_statut [-w INT] [-c INT] [-S]"
    echo ""
    echo "Options:"
    echo "  -H/--hostname)"
    echo "     Defines the hostname. Default is: localhost"
    echo "  -P/--port)"
    echo "     Defines the port. Default is: 80"
    echo "  -s/--status-page)"
    echo "     Name of the server's status page defined in the location"
    echo "     directive of your nginx configuration. Default is:"
    echo "     nginx_status"
    echo "  -S/--secure)"
    echo "     In case your server is only reachable via SSL, use this"
    echo "     this switch to use HTTPS instead of HTTP. Default is: off"
    echo "  -w/--warning)"
    echo "     Sets a warning level for requests per second. Default is: off"
    echo "  -c/--critical)"
    echo "     Sets a critical level for requests per second. Default is:"
	echo "     off"
    exit $ST_UK
}

while test -n "$1"; do
    case "$1" in
        -help|-h)
            print_help
            exit $ST_UK
            ;;
        --hostname|-H)
            hostname=$2
            shift
            ;;
        --port|-P)
            port=$2
            shift
            ;;
        --status-page|-s)
            status_page=$2
            shift
            ;;
        --secure|-S)
            secure=1
            ;;
        --warning|-w)
            warning=$2
            shift
            ;;
        --critical|-c)
            critical=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_help
            exit $ST_UK
            ;;
        esac
    shift
done

get_wcdiff() {
    if [ ! -z "$warning" -a ! -z "$critical" ]
    then
        wclvls=1

        if [ ${warning} -ge ${critical} ]
        then
            wcdiff=1
        fi
    elif [ ! -z "$warning" -a -z "$critical" ]
    then
        wcdiff=2
    elif [ -z "$warning" -a ! -z "$critical" ]
    then
        wcdiff=3
    fi
}

val_wcdiff() {
    if [ "$wcdiff" = 1 ]
    then
        echo "Please adjust your warning/critical thresholds. The warning \
must be lower than the critical level!"
        exit $ST_UK
    elif [ "$wcdiff" = 2 ]
    then
        echo "Please also set a critical value when you want to use \
warning/critical thresholds!"
        exit $ST_UK
    elif [ "$wcdiff" = 3 ]
    then
        echo "Please also set a warning value when you want to use \
warning/critical thresholds!"
        exit $ST_UK
    fi
}

get_status() {
    if [ "$secure" = 1 ]
    then
        wget_opts="-O- -q -t 3 -T 3 --no-check-certificate"
        out1=`wget ${wget_opts} http://${hostname}:${port}/${status_page}`
        sleep 1
        out2=`wget ${wget_opts} http://${hostname}:${port}/${status_page}`
    else        
        wget_opts="-O- -q -t 3 -T 3"
        out1=`wget ${wget_opts} http://${hostname}:${port}/${status_page}`
        sleep 1
        out2=`wget ${wget_opts} http://${hostname}:${port}/${status_page}`
    fi

    if [ -z "$out1" -o -z "$out2" ]
    then
        echo "UNKNOWN - Local copy of $status_page is empty."
        exit $ST_UK
    fi
}

get_vals() {
    tmp1_reqpsec=`echo ${out1}|awk '{print $10}'`
    tmp2_reqpsec=`echo ${out2}|awk '{print $10}'`
    reqpsec=`expr $tmp2_reqpsec - $tmp1_reqpsec`

    tmp1_conpsec=`echo ${out1}|awk '{print $9}'`
    tmp2_conpsec=`echo ${out2}|awk '{print $9}'`
    conpsec=`expr $tmp2_conpsec - $tmp1_conpsec`

	active_conn=`echo ${out2}|awk '{print $3}'`
}

do_output() {
    output="$active_conn active connections, $reqpsec requests per second, $conpsec \
connections per second"
}

do_perfdata() {
    perfdata="'ActiveConns'=$active_conn 'ReqPerSec'=$reqpsec 'ConPerSec'=$conpsec"
}

# Here we go!
get_wcdiff
val_wcdiff

get_status
get_vals
do_output
do_perfdata

if [ -n "$warning" -a -n "$critical" ]
then
    if [ "$reqpsec" -ge "$warning" -a "$reqpsec" -lt "$critical" ]
    then
        echo "NGINX WARNING - ${output} | ${perfdata}"
	exit $ST_WR
    elif [ "$reqpsec" -ge "$critical" ]
    then
        echo "NGINX CRITICAL - ${output} | ${perfdata}"
	exit $ST_CR
    else
        echo "NGINX OK - ${output} | ${perfdata} ]"
	exit $ST_OK
    fi
else
    echo "NGINX OK - ${output} | ${perfdata}"
    exit $ST_OK
fi
