interface=""
RESULT=""

received_bytes=""
old_received_bytes=""
transmitted_bytes=""
old_transmitted_bytes=""


function help {
    echo " check_net_io - Nagios network I/O check script"
    echo ""
    echo " Usage: check_net_io {-i} [-h]"
    echo ""
    echo "           -i  Interface to check (e.g. eth0)"
    echo "           -h  Show this page"
    echo ""
	exit 1
}

# This function parses /proc/net/dev file searching for a line containing $interface data.
# Within that line, the first and ninth numbers after ':' are respectively the received and transmited bytes.
function get_bytes
{
    line=$(cat /proc/net/dev | grep $interface | cut -d ':' -f 2 | awk '{print "received_bytes="$1, "transmitted_bytes="$9}')   
    eval $line
}

# Function which calculates the speed using actual and old byte number.
# Speed is shown in KByte per second when greater or equal than 1 KByte per second.
# This function should be called each second.
function get_velocity
{
    value=$1
    old_value=$2

    let vel=$value-$old_value
	echo -n "$vel";
}

# Write output and return result
function output {
    echo -en $RESULT
    exit $EXIT_STATUS
}

# Handle command line option
while getopts i:h myarg; do
    case $myarg in
        h|\?)
            help
			;;
        i)
            interface=$OPTARG
			;;
    esac
done

get_bytes
old_received_bytes=$received_bytes
old_transmitted_bytes=$transmitted_bytes
sleep 1;
# Get new transmitted and received byte number values.
get_bytes

# Calculates speeds.
vel_recv=$(get_velocity $received_bytes $old_received_bytes)
vel_trans=$(get_velocity $transmitted_bytes $old_transmitted_bytes)
    
vel_recvKB=$(echo "scale=1; $vel_recv/1024.0" | bc ) # Convert to decimal
vel_transKB=$(echo "scale=1; $vel_trans/1024.0" | bc ) # Convert to decimal 

let vel_total=$vel_recv+$vel_trans
vel_totalKB=$(echo "scale=1; $vel_total/1024.0" | bc ) # Convert to decimal  

RESULT="NET I/O OK - $interface DOWN: $vel_recvKB KB/s UP: $vel_transKB KB/s TOTAL: $vel_totalKB KB/s | DOWN=${vel_recvKB}KB/s; UP=${vel_transKB}KB/s; TOTAL=${vel_totalKB}KB/s;"
exitstatus=$STATE_OK

# Quit and return information and exit status
output
