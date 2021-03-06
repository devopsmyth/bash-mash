#!/bin/bash
<<<<<<< HEAD
=======

# NOT WORKING ENTIRELY NEEDS MORE TESTING

>>>>>>> a2917f57a50afef94cb68f3d955d84cbbc6938d4
# USAGE: ./netreload
# PURPOSE: reload all network interfaces for proxmox; especially useful when openvswitching is used

# strict error exits
#set -e

# variables for network/interfaces files
ONET=/etc/network/interfaces
NNET=/etc/network/interfaces.new
<<<<<<< HEAD
NET="10.0.120.1"
=======
NET="<IP ADDRESS>"
>>>>>>> a2917f57a50afef94cb68f3d955d84cbbc6938d4
REVNET_RESULT=""
SAVNET_RESULT=""
CHGNET_RESULT=""
RSTNET_RESULT=""
TSTNET_RESULT=""
QSTION_RESULT=""
ANSWER=""

revertnet () {
	# code for reverting to old network interfaces file
	echo "some code for reverting to old network interfaces file"
	if [ -f $ONET.OLD ]; then
		echo "cp'ing $ONET to /etc/network/interfaces"
		command cp $ONET.OLD $ONET
		restartnet
		REVNET_RESULT=0
	else
		echo "$ONET.OLD doesn't exist"
		REVNET_RESULT=1
	fi
}

savenet () {
	# some code for saving network interface files
	echo "saving $ONET"
	
	command cp "$ONET" "$ONET.OLD"
	
	[ -f "$ONET.OLD" ] && SAVNET_RESULT=0 || SAVNET_RESULT=1
}

changenet () {
	# some code for changing network/interfaces file to new version
	echo "changing $NNET to $ONET"

	command cp "$NNET" "$ONET"
	NDIFF_RESULT="$(netdiff $ONET $NNET)"
	if [ "$NDIFF_RESULT" ]; then
		CHGNET_RESULT=1
	else
		CHGNET_RESULT=0
	fi
}

restartnet () {
	# some code for restarting networking service and ifup|down interfaces
	echo "restartnet function"
	
    NICS="$(egrep 'e[a-z]{2}[0-9]|vmbr[0-9]{1,4}' /proc/net/dev | awk '{ print $1 }' | tr -d :)"
    for NIC in $NICS; do
        ifdown $NICS
        sleep 1
        ifup $NIC
        sleep 2
    done
    command /etc/init.d/networking stop && sleep 5 && /etc/init.d/networking start &

    # ifup ovs bridges a second time
    for NIC in $NICS; do
        case $NIC in
            vmbr*) echo "vmbridge up $NIC";
                ifup $NIC;;
            *) echo "not vmbridge interface $NIC";;
        esac
    done

	RSTNET_RESULT=0
}

testnet () {
	# some code for testing network connectivity
	local NET=$1
	echo "testnet function"
	local PING_RESULT="$(command ping -c 1 $NET > /dev/null ; echo $?)"
	if [ $PING_RESULT ]; then
		TSTNET_RESULT=0
        echo "network ping success from testnet()"
	elif [ $PING_RESULT == 2 ]; then
		TSTNET_RESULT=1
	else
		TSTNET_RESULT=1
	fi
}

netdiff () {
	# some code for testing if there are network changes present
	# check how many variables were passed
	local FILE1=$1
	local FILE2=$2
	if [ "$#" != 2 ]; then
		echo "must pass 2 filenames to function"
		return 255
	fi
	
	# check to see if files exist
	[ -f $FILE1 -a -f $FILE2 ] && echo "files exist!" || echo "files don't exist!"; return 254

	# check for file differences and return 0 for different and 1 for same
	if [ "$(diff $1 $2)" ]; then
		echo "files are different!"
		return 0
	else
		echo "files are same!"
		return 1
	fi
}

question () {
	# some code for querying the user for input
	if [ "$#" != 1 ]; then
		echo "passed more than one argument to question function"
	else
		local Q=$1
		read -p "$Q [y,n]" ANSWER
		if [[ "$ANSWER" == "y" || "$ANSWER" == "Y" ]]; then
			QSTION_RESULT=0
		else
			QSTION_RESULT=1
		fi
	fi
}

NDIFF_RESULT="$(netdiff $ONET $NNET)"
if [ "$NDIFF_RESULT" ]; then
	echo "files are different"
fi

question 'copy new network/interfaces to old?'
if [ $QSTION_RESULT ]; then
	echo "question result $QSTION_RESULT"
	#savenet
fi

if [ $SAVNET_RESULT ]; then
	echo "saved $ONET successfully"
fi

question "change interfaces.new to interfaces?"
if [ $QSTION_RESULT ]; then
    echo "question result $QSTION_RESULT"
    echo "changing interfaces.new to interfaces"
    #changenet
fi

if [ $CHGNET_RESULT ]; then
	echo "$? is var ? and : $CHGNET_RESULT is chgnet_result"
	#restartnet
	testnet $NET
	echo "$TSTNET_RESULT is testnet result"
	if [ $TSTNET_RESULT ]; then
		echo "ping test success"
		echo "exiting script"
	else
		echo "ping test failed"
		echo "reverting networks"
		#revertnet
	fi
fi