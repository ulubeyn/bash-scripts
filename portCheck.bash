#!/bin/bash
#title		:portCheck.bash
#description	:This script will check given port is open or not for specified ip address
#authors	:fatihdasgin, ulubeyn
#usage		:bash portCheck.bash -i <ip address> -p <port>

function usage(){
	echo "Usage: $0 -i <ip address> -p <port>"; exit 129
}

function isIpValid(){
	ipToCheck=$1
	if [[ $ipToCheck =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
	then
		temp=$IFS
		IFS='.'
		ipToCheck=($ipToCheck)
		IFS=$temp
		if ! [[ ${ipToCheck[0]} -le 255 && ${ipToCheck[1]} -le 255 && ${ipToCheck[2]} -le 255 && ${ipToCheck[3]} -le 255 ]] 
		then
			echo "IP is not valid!"; usage; exit 1
		fi
	else
		echo "IP is not valid!"; usage; exit 1
	fi
}

function isPortValid(){
	portToCheck=$1
	if [[  $portToCheck =~ ^[0-9]{1,5}$ ]]
	then
		if ! [[ $portToCheck -gt 0 && $portToCheck -lt 65536 ]]
		then
			echo "Port is not valid"; usage;  exit 2
		fi
	else
		echo "Port is not valid"; usage; exit 2
	fi
}

while getopts i:p: ARGS; do
        case $ARGS in
                i)
                        ip=$OPTARG
                  ;;
                p)
                        port=$OPTARG
                  ;;
                \?)
                        usage
                ;;
  	esac
done

if ! [ -n "$ip" ] || ! [ -n "$port" ]
then
	usage
fi

isIpValid $ip
isPortValid $port

timeout 2 bash -c "</dev/tcp/$ip/$port"

if [ $? -eq 0 ]
then
	echo "Port is open!"
else
	echo "Port is closed!"
fi
