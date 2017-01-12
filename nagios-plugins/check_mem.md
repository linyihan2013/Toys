
check_mem is a bash script that checks buffer, cache and used memory with performance data enable
root@localhost # ./check_mem 
[MEMORY] Total: 7713 MB - Used: 2402 MB - 31% [SWAP] Total: 8189 MB - Used: 0 MB - 0% | MTOTAL=8087736320;;;; MUSED=2516549632;;;; MCACHE=2323607552;;;; MBUFFER=140218368;;;; STOTAL=8587833344;;;; SUSED=0;;;; 

To use it with nrpe: 

add command: 

# check_nrpe_memory 
define command { 
command_name check_nrpe_memory 
command_line $USER1$/check_nrpe -H $HOSTADDRESS$ -c memory 
} 


define service: 

# Memory 
define service { 
use default-service 
host_name some_host 
service_description Memory Usage 
check_command check_nrpe_memory 
} 

and define nrpe command: 

command[memory]=/opt/plugins/check_mem -w 80 -c 90 
