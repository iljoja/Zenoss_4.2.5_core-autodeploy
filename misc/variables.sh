#!/bin/bash
##########################################
# Version: 01o
#   Notes: updated check-log
##########################################

# Path Variables
	export ZENHOME=/usr/local/zenoss
	export PYTHONPATH=/usr/local/zenoss/lib/python
	export PATH=/usr/local/zenoss/bin:$PATH
	export INSTANCE_HOME=$ZENHOME

# Variables
supos="echo ...Supported OS detected."

# Functions
multiverse-verify () {
        MVCHECK=$(cat /etc/apt/sources.list | grep ^#* | grep multiverse | grep -c "#deb")
        if [ $MVCHECK -ne "0" ]; then
                echo && echo "...it appears that the Multiverse repo's are disabled, they are required, stopping script" && exit 0
        fi      }

check-log () {
        if grep -q "Cannot allocate memory" script-log.txt
                then    echo "...Your server doesn't have enough RAM, 3GB is the recommended minimum." && exit 0
	elif grep -q "/usr/local/zenoss/lib/libxml2.so.2: no version information available" script-log.txt
		then	echo "...Looks like you are upgrading from 4.2.3, let me fix a few files!"
			service zenoss stop
			mv /usr/local/zenoss/lib/libxml2.so.2 /usr/local/zenoss/lib/libxml2.so.2.old
			mv /usr/local/zenoss/lib/libxml2.so /usr/local/zenoss/lib/libxml2.so.old
			mv /usr/local/zenoss/lib/libz.so /usr/local/zenoss/lib/libz.so.old
			mv /usr/local/zenoss/lib/libz.so.1 /usr/local/zenoss/lib/libz.so.1.old
			service zenoss start
        else    echo "...Check log didn't find any errors"
        fi      }

menu-os () {
	echo && echo "...Non Supported OS detected...would you like to continue anyways?"
	PS3='(Press 1 or 2): '
	options=("Yes" "No")
	select opt in "${options[@]}"
	do case $opt in "Yes") echo "...continuing script with Non Supported OS...good luck!"
	break ;;
	"No") echo "...stopping script" && exit 0
	break ;; *) echo invalid option;; esac
	done }

detect-os () {
	if grep -q "Ubuntu 13" /etc/issue.net
		then    $supos && curos="ubuntu"
        elif grep -q "Ubuntu 14" /etc/issue.net
                then    $supos && curos="ubuntu" && idos="14"
	elif grep -q "Ubuntu 12" /etc/issue.net
		then    $supos && curos="ubuntu"
	elif grep -Fxq "Debian GNU/Linux 7" /etc/issue.net
	then    $supos && curos="debian"
	else    menu-os
	fi      }

mysql-conn_test () {
	mysql -u root -e "show databases;" > /tmp/mysql.txt 2>> /tmp/mysql.txt
	if grep -Fxq "Database" /tmp/mysql.txt
		then    echo "...MySQL connection test successful." && mysqlcred="no" MYSQLUSER="root" && MYSQLPASS="" && echo
		else    echo && echo "...Mysql connection failed...starting credentials menu." && echo && mysql-cred
	fi      }

mysql-cred () {
	echo "Enter your MySQL credentials for the root user"
	read -p "...password: " password
	echo & echo "Testing MySQL Connection..."
	mysql -uroot -p$password -e "show databases;" > /tmp/mysql.txt 2>> /tmp/mysql.txt
	if grep -Fxq "Database" /tmp/mysql.txt
		then echo "...MySQL connection test successful." && mysqlcred="yes" && MYSQLUSER="root" && MYSQLPASS=$password && echo
		else echo "...Mysql connection failed." && exit 0
	fi	}

detect-arch () {
if uname -m | grep -Fxq "x86_64"
        then    echo "...Correct Arch detected."
        else    echo "...Incorrect Arch detected...stopped script" && exit 0
fi	}

detect-user () {
if [ `whoami` != 'zenoss' ];
        then    echo "...Detect user checks passed."
        else    echo "...This script should not be ran by the zenoss user" && exit 0
fi	}

debian-testing-repo () {
cp /etc/apt/sources.list /etc/apt/sources.list.orig
wget -N https://raw.github.com/hydruid/zenoss/master/core-autodeploy/4.2.5/misc/debian-testing-repo.list -P /root/
mv /root/debian-testing-repo.list /etc/apt/sources.list
apt-get update
apt-get -t testing install libc6 libc6-dev -y
cp /etc/apt/sources.list.orig /etc/apt/sources.list
apt-get update
	}

pkg-fix () {
apt-get -f install
        }

os-fixes () {
        if grep -q "Ubuntu 13" /etc/issue.net
                then    cd /usr/local/zenoss/lib/python/pynetsnmp
			mv netsnmp.py netsnmp.py.orig
			wget https://raw.github.com/hydruid/zenoss/master/core-autodeploy/4.2.5/misc/netsnmp.py
			chown zenoss:zenoss netsnmp.py
			echo "...Specific OS fixes complete."
        elif grep -q "Ubuntu 14" /etc/issue.net
                then    cd /usr/local/zenoss/lib/python/pynetsnmp
                        mv netsnmp.py netsnmp.py.orig
                        wget https://raw.github.com/hydruid/zenoss/master/core-autodeploy/4.2.5/misc/netsnmp.py
                        chown zenoss:zenoss netsnmp.py
                        echo "...Specific OS fixes complete."
	elif grep -q "Ubuntu 16" /etc/issue.net
                then    cd /usr/local/zenoss/lib/python/pynetsnmp
                        mv netsnmp.py netsnmp.py.orig
                        wget https://raw.github.com/hydruid/zenoss/master/core-autodeploy/4.2.5/misc/netsnmp.py
                        chown zenoss:zenoss netsnmp.py
                        echo "...Specific OS fixes complete."
	elif grep -q "Ubuntu 18" /etc/issue.net
                then    cd /usr/local/zenoss/lib/python/pynetsnmp
                        mv netsnmp.py netsnmp.py.orig
                        wget https://raw.github.com/hydruid/zenoss/master/core-autodeploy/4.2.5/misc/netsnmp.py
                        chown zenoss:zenoss netsnmp.py
                        echo "...Specific OS fixes complete."
        elif grep -q "Ubuntu 12" /etc/issue.net
                then    echo "...No specific OS fixes needed."
        elif grep -Fxq "Debian GNU/Linux 7" /etc/issue.net
                then    echo "...No specific OS fixes needed."
        else	echo "...No specific OS fixes needed."
        fi      }

hostname-verify () {
	HOSTVERIFY=$(cat /etc/hostname)
        if grep -q $HOSTVERIFY /etc/hosts
                then    echo "...Detect hostname checks passed."
        else    echo "...The hostname for this server should be in /etc/hosts or rabbit will not play nice!"
		echo "...stopping script" && exit 0
        fi      }
