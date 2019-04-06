# Genix masternode install script
# Edited by Twinky
VERSION="1.0.0.0"
NODEPORT='43649'
RPCPORT='4455'

# Useful variables
declare -r DATE_STAMP="$(date +%y-%m-%d-%s)"
declare -r SCRIPT_LOGFILE="/root/log_inst_genix_node_${DATE_STAMP}_out.log"
declare -r SCRIPTPATH=$( cd $(dirname ${BASH_SOURCE[0]}) > /dev/null; pwd -P )
declare -r WANIP=$(curl -s4 "https://ipecho.net/plain")

function print_greeting() {
	echo -e "[0;35m Genix masternode install script[0m\n"
}


function print_info() {
	echo -e "[0;35m Install script version:[0m ${VERSION}"
	echo -e "[0;35m Your ip:[0m ${WANIP}"
	echo -e "[0;35m Masternode port:[0m ${NODEPORT}"
	echo -e "[0;35m RPC port:[0m ${RPCPORT}"
	echo -e "[0;35m Date:[0m ${DATE_STAMP}"
	echo -e "[0;35m Logfile:[0m ${SCRIPT_LOGFILE}"
}


function install_packages() {
	echo "Installing dependencies..."
	sudo add-apt-repository -yu ppa:bitcoin/bitcoin  &>> ${SCRIPT_LOGFILE}
	sudo apt-get -y update &>> ${SCRIPT_LOGFILE}
  	sudo apt-get -y upgrade &>> ${SCRIPT_LOGFILE}
 	sudo apt-get -y install unzip &>> ${SCRIPT_LOGFILE}
	sudo apt-get -y install wget make automake autoconf build-essential libtool autotools-dev \
	git nano python-virtualenv pwgen virtualenv \
	pkg-config libssl-dev libevent-dev bsdmainutils software-properties-common \
	libboost-all-dev libminiupnpc-dev libdb4.8-dev libdb4.8++-dev &>> ${SCRIPT_LOGFILE}
	sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y &>> ${SCRIPT_LOGFILE}
	sudo apt-get -y update &>> ${SCRIPT_LOGFILE}
	sudo apt-get -y install gcc-4.9 &>> ${SCRIPT_LOGFILE}
	sudo apt-get -y upgrade libstdc++6 &>> ${SCRIPT_LOGFILE}
        sudo apt-get -y install libzmq3-dev &>> ${SCRIPT_LOGFILE}
	echo "Install done..."
}


function swaphack() {
	echo "Setting up disk swap..."
	free -h
	rm -f /var/genix_node_swap.img
	touch /var/genix_node_swap.img
	dd if=/dev/zero of=/var/genix_node_swap.img bs=1024k count=2000 &>> ${SCRIPT_LOGFILE}
	chmod 0600 /var/genix_node_swap.img
	mkswap /var/genix_node_swap.img &>> ${SCRIPT_LOGFILE}
	free -h
	echo "Swap setup complete..."
}


function remove_old_files() {
	echo "Removing old files..."
	sudo killall genixd
	sudo rm -rf /root/genix
	sudo rm -rf /root/.genixcore
    	sudo rm -rf /usr/local/bin/genix*
	echo "Done..."
}


function download_wallet() {
	echo "Downloading wallet..."
	mkdir /root/genix
	mkdir /root/.genixcore
    	cd genix
	wget "https://github.com/Twinky-kms/genix-1/releases/download/v0.2.0.2b/ubuntu-mn-package.zip"
	unzip ubuntu-mn-package.zip -d /root/genix/
	chmod +x /root/genix/*
	mv /root/genix/* /usr/local/bin/
	rm -rf /root/genix/
	echo "Done..."
}


function configure_firewall() {
	echo "Configuring firewall rules..."
	apt-get -y install ufw			&>> ${SCRIPT_LOGFILE}
	# disallow everything except ssh and masternode inbound ports
	ufw default deny			&>> ${SCRIPT_LOGFILE}
	ufw logging on				&>> ${SCRIPT_LOGFILE}
	ufw allow ssh/tcp			&>> ${SCRIPT_LOGFILE}
	ufw allow 43649/tcp			&>> ${SCRIPT_LOGFILE}
	ufw allow 4455/tcp			&>> ${SCRIPT_LOGFILE}
	# This will only allow 6 connections every 30 seconds from the same IP address.
	ufw limit OpenSSH			&>> ${SCRIPT_LOGFILE}
	ufw --force enable			&>> ${SCRIPT_LOGFILE}
	echo "Done..."
}


function configure_masternode() {
	echo "Configuring masternode..."
	conffile=/root/.genixcore/genix.conf
	PASSWORD=`pwgen -1 20 -n` &>> ${SCRIPT_LOGFILE}
	if [ "x$PASSWORD" = "x" ]; then
	    PASSWORD=${WANIP}-`date +%s`
	fi
	echo "Loading and syncing wallet..."
	echo "    if you see *error: Could not locate RPC credentials* message, do not worry"
	genix-cli stop
	echo "It's okay."
	sleep 10
	echo -e "rpcuser=genixuser\nrpcpassword=${PASSWORD}\nrpcport=${RPCPORT}\nrpcallowip=127.0.0.1\nport=${NODEPORT}\nexternalip=${WANIP}\nlisten=1\nmaxconnections=250" >> ${conffile}
	echo ""
	echo -e "[0;35m==================================================================[0m"
	echo -e "     DO NOT CLOSE THIS WINDOW OR TRY TO FINISH THIS PROCESS"
	echo -e "                        PLEASE WAIT 2 MINUTES"
	echo -e "[0;35m==================================================================[0m"
	echo ""
	genixd -daemon
	echo "2 MINUTES LEFT"
	sleep 60
	echo "1 MINUTE LEFT"
	sleep 60
	masternodekey=$(genix-cli masternode genkey)
	genix-cli stop
	sleep 20
	echo "Creating masternode config..."
	echo -e "daemon=1\nmasternode=1\nmasternodeprivkey=$masternodekey" >> ${conffile}
	echo "Done...Starting daemon..."
	genixd -daemon
}

function addnodes() {
	echo "Adding nodes..."
	conffile=/root/.genixcore/genix.conf
	echo -e "\addnode=45.77.125.15" >> ${conffile}
	echo -e "addnode=198.12.95.122" >> ${conffile}
	echo -e "addnode=149.28.56.171" >> ${conffile}
	echo "Done..."
}


function show_result() {
	echo ""
	echo -e "[0;35m==================================================================[0m"
	echo "DATE: ${DATE_STAMP}"
	echo "LOG: ${SCRIPT_LOGFILE}"
	echo "rpcuser=genixuser"
	echo "rpcpassword=${PASSWORD}"
	echo ""
	echo -e "[0;35m INSTALLED WITH VPS IP: ${WANIP}:${NODEPORT} [0m"
	echo -e "[0;35m INSTALLED WITH MASTERNODE PRIVATE GENKEY: ${masternodekey} [0m"
	echo "[0;35m Copy to local Masternode.conf: ${WANIP}:${NODEPORT} ${masternodekey} [0m"
	echo -e "If you get \"Masternode not in masternode list\" status, don't worry,\nyou just have to start your MN from your local wallet and the status will change"
	echo -e "[0;35m==================================================================[0m"
	echo -e "[0;35mCheck your node with command: genix-cli masternode status[0m"
	echo -e "[0;35mStop your node with command: genix-cli stop[0m"
	echo -e "[0;35mStart your node with command: genixd[0m"
	echo -e "[0;35m==================================================================[0m"
}


function cleanup() {
	echo "Cleanup..."
	apt-get -y autoremove 	&>> ${SCRIPT_LOGFILE}
	apt-get -y autoclean 		&>> ${SCRIPT_LOGFILE}
	echo "Done..."
}


#Setting auto start cron job for wikid
cronjob="@reboot sleep 30 && genixd"
crontab -l > tempcron
if ! grep -q "$cronjob" tempcron; then
    echo -e "Configuring crontab job..."
    echo $cronjob >> tempcron
    crontab tempcron
fi
rm tempcron


# Flags
compile=0;
swap=0;
firewall=0;


#Bad arguments
if [ $? -ne 0 ];
then
    exit 1
fi


# Check arguments
while [ "$1" != "" ]; do
    case $1 in
        -sw | --swap )
            swap=1
            ;;
        -f | --firewall )
            firewall=1
            ;;
        -n | --addnodes )
            addnodes=1
            ;;
        * )
            exit 1
    esac
    if [ "$#" -gt 0 ]; then shift; fi
done


# main routine
print_greeting
print_info
install_packages
if [ "$swap" -eq 1 ]; then
	swaphack
fi

if [ "$firewall" -eq 1 ]; then
	configure_firewall
fi

remove_old_files
download_wallet
addnodes
configure_masternode

show_result
cleanup
echo "All done!"
cd ~/
sudo rm /root/genix_ubuntu_install.sh
