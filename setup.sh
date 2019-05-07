#!/bin/bash

cd ~
echo "****************************************************************************"
echo "* Ubuntu 18.04 is the recommended opearting system for this install.       *"
echo "*                                                                          *"
echo "* This script will install and configure your GENIX masternodes.           *"
echo "****************************************************************************"
echo && echo && echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!                                                 !"
echo "! Make sure you double check before hitting enter !"
echo "!                                                 !"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo && echo && echo

echo "Do you want to install all needed dependencies (no if you did it before)? [y/n]"
read DOSETUP

if [[ $DOSETUP =~ "y" ]] ; then
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
  sudo apt-get install -y nano htop git
  sudo apt-get install -y software-properties-common
  sudo apt-get install -y build-essential libtool autotools-dev pkg-config libssl-dev
  sudo apt-get install -y libboost-all-dev
  sudo apt-get install -y libboost-system-dev
  sudo apt-get install -y libzmq3-dev
  sudo apt-get install -y libevent-dev
  sudo apt-get install -y libminiupnpc-dev
  sudo apt-get install -y autoconf
  sudo apt-get install -y automake unzip
  sudo add-apt-repository  -y  ppa:bitcoin/bitcoin
  sudo apt-get update
  sudo apt-get install -y libdb4.8-dev libdb4.8++-dev

  cd /var
  sudo touch swap.img
  sudo chmod 600 swap.img
  sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
  sudo mkswap /var/swap.img
  sudo swapon /var/swap.img
  sudo free
  sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
  cd

  wget https://github.com/genix-project/genix/releases/download/v0.2.0.2/genix-unix-64.tar.gz
  tar -xzf genix-unix-64.tar.gz
  chmod -R 755 genix-unix-64
  rm /usr/bin/genix*
  mv genix-unix-64/genix* /usr/bin
  rm -r genix-unix-64

  sudo apt-get install -y ufw
  sudo ufw allow ssh/tcp
  sudo ufw limit ssh/tcp
  sudo ufw logging on
  echo "y" | sudo ufw enable
  sudo ufw status

  mkdir -p ~/bin
  echo 'export PATH=~/bin:$PATH' > ~/.bash_aliases
  source ~/.bashrc
fi

## Setup conf
mkdir -p ~/bin


MNCOUNT=""
re='^[0-9]+$'
while ! [[ $MNCOUNT =~ $re ]] ; do
   echo ""
   echo "How many nodes do you want to create on this server?, followed by [ENTER]:"
   read MNCOUNT
done

for i in `seq 1 1 $MNCOUNT`; do
  echo ""
  echo "Enter alias for new node"
  read ALIAS

  echo ""
  echo "Enter port 43649 for node $ALIAS"
  read PORT

  echo ""
  echo "Enter masternode private key for node $ALIAS"
  read PRIVKEY

  echo ""
  echo "Configure your masternodes now!"
  echo "Type the IP of this server, followed by [ENTER]:"
  read IP

  echo ""
  echo "Enter RPC Port (Any valid free port: i.E. 17100)"
  read RPCPORT

  ALIAS=${ALIAS,,}
  CONF_DIR=~/.genixcore_$ALIAS

  # Create scripts
  echo '#!/bin/bash' > ~/bin/genixd_$ALIAS.sh
  echo "genixd -daemon -conf=$CONF_DIR/genix.conf -datadir=$CONF_DIR "'$*' >> ~/bin/genixd_$ALIAS.sh
  echo '#!/bin/bash' > ~/bin/genix-cli_$ALIAS.sh
  echo "genix-cli -conf=$CONF_DIR/genix.conf -datadir=$CONF_DIR "'$*' >> ~/bin/genix-cli_$ALIAS.sh
  echo '#!/bin/bash' > ~/bin/genix-tx_$ALIAS.sh
  echo "genix-tx -conf=$CONF_DIR/genix.conf -datadir=$CONF_DIR "'$*' >> ~/bin/genix-tx_$ALIAS.sh
  chmod 755 ~/bin/genix*.sh

  mkdir -p $CONF_DIR
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> genix.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> genix.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> genix.conf_TEMP
  echo "rpcport="`shuf -i 10000-30000 -n 1` >> genix.conf_TEMP
  echo "listen=1" >> genix.conf_TEMP
  echo "server=1" >> genix.conf_TEMP
  echo "daemon=1" >> genix.conf_TEMP
  echo "logtimestamps=1" >> genix.conf_TEMP
  echo "maxconnections=64" >> genix.conf_TEMP
  echo "masternode=1" >> genix.conf_TEMP
  echo "" >> genix.conf_TEMP

  echo "addnode=161.43.201.255" >> genix.conf_TEMP

  echo "" >> genix.conf_TEMP
  echo "port=$PORT" >> genix.conf_TEMP
  echo "externalip=$IP" >> genix.conf_TEMP
  echo "bind=$IP" >> genix.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> genix.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> genix.conf_TEMP
  sudo ufw allow $PORT/tcp

  mv genix.conf_TEMP $CONF_DIR/genix.conf

  sh ~/bin/genixd_$ALIAS.sh
done

echo "Do you want to install sentinel? (no if you did it before) [y/n]"
read SENTINELSETUP

if [[ $SENTINELSETUP =~ "y" ]] ; then
    echo "Starting sentinel setup.."

version=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
parsedVersion=$(echo "${version//./}")
new=$(tr -dc '0-9' <<< $parsedVersion | cut -c1-4)

if [[ "$new" -lt "3000" && "$new" -gt "2700" ]]
then
    echo "Valid version skipping py installation..."
else
    echo "Invalid version installing py..."
    sudo apt-get install -y python
fi

  cd ~

  sudo apt-get -y install virtualenv

  git clone https://github.com/Twinky-kms/sentinel.git

  echo "setting up sentinel..."

  echo "dash_conf=$CONF_DIR/genix.conf" >> sentinel.conf_TEMP
  echo "network=mainnet" >> sentinel.conf_TEMP
  echo "db_name=database/sentinel.db" >> sentinel.conf_TEMP
  echo "db_driver=sqlite" >> sentinel.conf_TEMP

  mv sentinel.conf_TEMP $HOME/sentinel/sentinel.conf

  cd ~/sentinel

    virtualenv ./venv
    ./venv/bin/pip install -r requirements.txt
    crontab -l | { cat; echo "* * * * * cd /root/sentinel/ && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1"; } | crontab -
    echo "all done"
fi
