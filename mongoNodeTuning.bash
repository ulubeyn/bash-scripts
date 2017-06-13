#!/bin/bash
# Mongodb Server Tuning Script FD

# Process and User Limits
# Filesystem Max Open Files
echo "[*] Checking process and user limits..."
echo "[*] Checking filesystem max open files limits..."

egrep -v '^#|^$' /etc/security/limits.conf > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
	echo "*       soft    fsize   unlimited" >> /etc/security/limits.conf
	echo "*       hard    fsize   unlimited" >> /etc/security/limits.conf
	echo "*       soft    cpu     unlimited" >> /etc/security/limits.conf
	echo "*       hard    cpu     unlimited" >> /etc/security/limits.conf
	echo "*       soft    as      unlimited" >> /etc/security/limits.conf
	echo "*       hard    as      unlimited" >> /etc/security/limits.conf
	echo "*       soft    nofile  64000" >> /etc/security/limits.conf
	echo "*       hard    nofile  64000" >> /etc/security/limits.conf
	echo "*       soft    nproc   64000" >> /etc/security/limits.conf
	echo "*       hard    nproc   64000" >> /etc/security/limits.conf
	echo "root       soft    fsize   unlimited" >> /etc/security/limits.conf
	echo "root       hard    fsize   unlimited" >> /etc/security/limits.conf
	echo "root       soft    cpu     unlimited" >> /etc/security/limits.conf
	echo "root       hard    cpu     unlimited" >> /etc/security/limits.conf
	echo "root       soft    as      unlimited" >> /etc/security/limits.conf
	echo "root       hard    as      unlimited" >> /etc/security/limits.conf
	echo "root       soft    nofile  64000" >> /etc/security/limits.conf
	echo "root       hard    nofile  64000" >> /etc/security/limits.conf
	echo "root       soft    nproc   64000" >> /etc/security/limits.conf
	echo "root       hard    nproc   64000" >> /etc/security/limits.conf
fi
sleep 2;


# No swap space or swap device found in /proc/swaps
# Swap Partition not found in /etc/fstab
echo "[*] Checking swap areas..."

egrep -v '^Filename' /proc/swaps > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
	if [ -f "/swapfile" ]
	then
		chmod 0600 /swapfile
		swapon /swapfile
	else
		echo "[*]	No swap partition found."
		echo "[*] 	Creating new swap partition..."
		dd if=/dev/zero of=/swapfile bs=1M count=4096
		mkswap /swapfile
		chmod 0600 /swapfile
		swapon /swapfile
		echo "/swapfile    none    swap    sw    0   0" >> /etc/fstab
	fi
fi
sleep 2;


# High Disk Readahead detected
echo "[*] Checking disk readahead for block devices..."

egrep 'blockdev' /etc/rc.local > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
	egrep '^/dev/mapper' /proc/mounts | egrep -v ' / ' | awk '{print $1}' | xargs -i% /sbin/blockdev --setra 0 %
	sed -i '/exit 0/d' /etc/rc.local
	egrep '^/dev/mapper' /proc/mounts | egrep -v ' / ' | awk '{print $1}' | xargs -i% echo "blockdev --setra 0 % " >> /etc/rc.local
	echo "exit 0" >> /etc/rc.local
fi
sleep 2;


# Transparent Hugepages (THP) Khugepaged Defrag
# Transparent Hugepages (THP) Defrag
echo "[*] Checking transparent hugepages (THP) on kernel..."

egrep 'transparent_hugepage/enabled' /etc/rc.local > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
	sed -i '/exit 0/d' /etc/rc.local
	cat<<EOF >> /etc/rc.local
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
EOF
	if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   		echo never > /sys/kernel/mm/transparent_hugepage/enabled
	fi

	echo "exit 0" >> /etc/rc.local
fi

egrep 'transparent_hugepage/defrag' /etc/rc.local > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
	sed -i '/exit 0/d' /etc/rc.local
	cat<<EOF >> /etc/rc.local
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
EOF
	if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   		echo never > /sys/kernel/mm/transparent_hugepage/defrag
	fi

	echo "exit 0" >> /etc/rc.local
fi

egrep 'khugepaged/defrag' /etc/rc.local > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
        sed -i '/exit 0/d' /etc/rc.local
        cat<<EOF >> /etc/rc.local
if test -f /sys/kernel/mm/transparent_hugepage/khugepaged/defrag; then
  echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
fi
EOF
	if test -f /sys/kernel/mm/transparent_hugepage/khugepaged/defrag; then
  		echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
	fi

        echo "exit 0" >> /etc/rc.local
fi

sleep 2;


# Kernel Max PID
echo "[*] Checking kernel max pid value..."
egrep 'kernel.pid_max' /etc/sysctl.conf > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
	echo "kernel.pid_max=64000" >> /etc/sysctl.conf
fi
sleep 2;

# Kernel Max thread count
echo "[*] Checking kernel max hhread value..."
egrep 'kernel.threads-max' /etc/sysctl.conf > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
	echo "kernel.threads-max=64000" >> /etc/sysctl.conf
fi
sleep 2;


# TCP Keepalive setting is higher than recommended
echo "[*] Checking TCP keepalive times..."
egrep 'net.ipv4.tcp_keepalive_time' /etc/sysctl.conf > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
	echo "net.ipv4.tcp_keepalive_time=120"  >> /etc/sysctl.conf
fi
sysctl -p  > /dev/null 2>&1
sleep 2;

echo "[*] OS Tuning completed. Please reboot the server!!"
