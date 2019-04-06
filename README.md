Masternodescripts

Masternode Install script for Genix ecosystem on Ubuntu VPS. This script configures a new vps, install dependencies, set up swapfile and cronjobs, and install Genix in the specified path for ease of use. It also create a logfile of the install in .genix folder. Ip:port and private key show at the end for easy copy/paste to control wallet.

Go to Vultr > Deploy new server you choose location, os, and add Server Hostname & Label. Nothing else needed. Click on the new servers name to find IP and root password To connect to your VPS you need https://www.putty.org/, https://mobaxterm.mobatek.net/download.html or another SSH client.

Log in to the vps with Putty/MobaXterm, with username root and the password from vultr. To paste the password you right click in the screen once. It will not show anything on the screen, so hit enter to log in.

Copy/paste and run following commands:

If the VPS is newly deployed, run these 3 lines first:

apt-get update
apt-get upgrade
reboot
To paste into a linux screen you right click in the screen once. After the reboot, log in again.

Now when all is ready, install Genix:

wget https://github.com/genix-project/masternode-setup-script/releases/download/v1.0/genix-mn-setup.sh

chmod +x genix-mn-setup.sh && bash genix-mn-setup.sh
While waiting for the script to finish, you can set up the local wallet:

Make a receive address called MN1
Send collateral 10,000 GENIX to the newly made address. Wait for confirmations.
Go to Settings > Advanced Options , and activate "Show Masternodes Tab"
Go to Tools > Debug Console, and enter following: masternode outputs This returns collateral_output_txid and collateral_output_index
Go to Tools > Open Masternode Configuration File The script prints a config line for this file. Add the config line like the example in the file, and add the returns from "masternode outputs" MN1 ip:port GENKEY collateral_output_txid collateral_output_index
Where the ip:port and GENKEY is retrieved from the finished VPS install. collateral_output_txid AND collateral_output_index is from the Debug console.

Save the file and restart your wallet. Wait until fully synchronized, then go to Masternode tab and start your Masternode.

You can check on the VPS with commands:

check: genix-cli masternode status
stop:  genix-cli stop
start: genixd
To see live output on the vps, use command: tail -f ~/.genix/debug.log
