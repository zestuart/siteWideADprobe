#!/bin/bash

function ncCheck {
	if [ ! -x /usr/bin/nc ] ; then
		echo "The nc executable was not found at /usr/bin/nc, or you don't have permission to execute it."
		while true; do
			read -p "Would you like to install homebrew?  This will allow you to install nc."
			case $yn in
				[Yy]* ) ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)" && brew install nc && echo "nc should now be installed!" ; break;;
				[Nn]* ) exit;;
				* ) echo "y/n!";;
			esac
		done
	fi
}

function networkCheck {
ipCheck=$(ifconfig | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
	if [[ $ipCheck == 127\.0\.0\.1 ]] ; then 
		while true; do
		    read -p "The only valid IP in your config is localhost: it looks like you have no network connection.  Check again? (y/n)" yn
		    case $yn in
		        [Yy]* ) networkCheck ; break;;
		        [Nn]* ) exit;;
		        * ) echo "y/n!";;
		    esac
		done
	fi
}

function dnsCheck {
	domain=$(cat /etc/resolv.conf | grep domain | awk '{print $2}')
	if [[ -z $domain ]] ; then
		echo "No AD domain information found in DNS."
	fi
}

function infoGather {
	dcCount=$(dig a $domain | grep ANSWER | awk '{print $10}' | sed 's/,$//')
	dcList=$(dig a $domain | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n $dcCount)
}


function dcCheck {
	echo "All discovered DCs for $domain will have the following services tested for availability:"
	echo "DNS, LDAP, DHCP."

	for i in ${dcList[@]}; do
		echo "Testing $i..."
		pingCheck=$(ping -c 1 $i)
		if [ "$?" -eq "0" ]; then
			goodCount=$[$goodCount+1]
			dns=$(nc -z $i 53)
			if [ "$?" -eq "0" ]; then
				echo "DNS available."
			else
				echo "Error: could not probe DNS port (TCP 53)."
			fi

			ldap=$(nc -z $i 389)
			if [ "$?" -eq "0" ]; then
				echo "LDAP available."
			else
				echo "Error: could not probe LDAP port (TCP 389)."
			fi

			dhcp=$(nc -zu $i 67)
			if [ "$?" -eq "0" ]; then
				echo "DHCP available."
			else
				echo "Error: could not probe DHCP port (TCP 67)."
			fi
	        echo "------*------"
		else
			badCount=$[$badCount+1]
			echo "Ping to $i failed."
			echo "------*------"
	    fi
	done
}

function report {
	if [ -z $goodCount ] ; then
		goodCount=0
	fi
	if [ -z $badCount ] ; then
		badCount=0
	fi
	if [[ $dcCount > 1 ]] ; then
		pluralQ="Out of $dcCount DCs,"
	else
		pluralQ="Out of $dcCount DC,"
	fi
	if [[ $dcCount == $goodCount ]] ; then 
		sentenceEnd=\.
	else
		sentenceEnd=", and $badCount did not."
	fi
	echo "$pluralQ $goodCount responded to ping$sentenceEnd"
}

ncCheck
networkCheck
if [ -z "$1" ] ; then 
	dnsCheck
else
	domain=$1
fi
infoGather
dcCheck
report
