#!/bin/bash

function usage() {
	echo "Usage: bash "$(basename $0) "<nodeIp>"
}

function brokenIndices () {
	
	for indice in $(curl -s $ip:9200/_cat/indices | egrep 'red|yellow' | awk '{print $3}'); do
		brIndices+=($indice)
	done
}

function brokenShards () {

	nodeName=$1
	
	for indice in "${brIndices[@]}"; do
		for shardNumber in $(curl -s $ip:9200/_cat/shards | egrep $indice | egrep -i 'UNASSIGNED' | awk '{print $2}'); do
			reRoute $indice $shardNumber $nodeName
		done
		
	done
}

function reRoute () {
	indiceName=$1
	shardNu=$2
	nodeName=$3

	curl -XPOST  $ip:9200/_cluster/reroute -d '
	{
	    "commands" : [
	        {
	          "allocate_replica" : {
	                "index" : "'"$indice"'",
	                "shard" : "'"$shardNumber"'",
	                "node" : "'"$nodeName"'"
	          }
	        }
	    ]
	}'

}

function main () {

	curl -s $ip:9200/_cluster/health | grep '"status":"green"' &> /dev/null

	if [ $? -eq 0 ]; then
		echo "[+] Cluster Status is green"
		exit 0
	fi

	nodeName=$(curl -s $ip:9200/ | grep '"name"' | awk '{print $3}' | sed -e 's/^\"//' -e 's/\"\,$//')
	declare -a brIndices=()
	declare -a brShards=()
	brokenIndices
	brokenShards $nodeName

}

if [ $# -ne 1 ];
then
	usage
	exit 1
fi

ip=$1
main
