#!/bin/bash
# CRYPTOSHARES Masternode Setup Script V2.3.0 for Ubuntu LTS
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash sharesauto.sh
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#TCP port
PORT=23190
RPC=23191

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'sharesd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop sharesd${NC}"
        shares-cli stop
        sleep 30
        if pgrep -x 'sharesd' > /dev/null; then
            echo -e "${RED}sharesd daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            sudo pkill -9 sharesd
            sleep 30
            if pgrep -x 'sharesd' > /dev/null; then
                echo -e "${RED}Can't stop sharesd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
genkey=$1
clear

echo -e "${GREEN} ------- CRYPTOSHARES MASTERNODE INSTALLER V2.3.0--------+
 |                                                  |
 |                                                  |::
 |       The installation will install and run      |::
 |        the masternode under a user SHARES.       |::
 |                                                  |::
 |        This version of installer will setup      |::
 |           fail2ban and ufw for your safety.      |::
 |                                                  |::
 +------------------------------------------------+::
   ::::::::::::::::::::::::::::::::::::::::::::::::::S${NC}"
echo "Do you want me to generate a masternode private key for you?[y/n]"
read DOSETUP

if [[ $DOSETUP =~ "n" ]] ; then
          read -e -p "Enter your private key:" genkey;
              read -e -p "Confirm your private key: " genkey2;
    fi

#Confirming match
  if [ $genkey = $genkey2 ]; then
     echo -e "${GREEN}MATCH! ${NC} \a" 
else 
     echo -e "${RED} Error: Private keys do not match. Try again or let me generate one for you...${NC} \a";exit 1
fi
sleep .5
clear

# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi
if [ -d "/var/lib/fail2ban/" ]; 
then
    echo -e "${GREEN}Packages already installed...${NC}"
else
    echo -e "${GREEN}Updating system and installing required packages...${NC}"

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano
sudo apt-get install unzip
fi

#Generating Random Password for  JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
if grep -q "SwapTotal" /proc/meminfo; then
    echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
    touch /var/swap.img
    chmod 600 swap.img
    dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
    mkswap /var/swap.img 2> /dev/null
    swapon /var/swap.img 2> /dev/null
    if [ $? -eq 0 ]; then
        echo '/var/swap.img none swap sw 0 0' >> /etc/fstab
        echo -e "${GREEN}Swap was created successfully!${NC} \n"
    else
        echo -e "${RED}Operation not permitted! Optional swap was not created.${NC} \a"
        rm /var/swap.img
    fi
fi
 
#Installing Daemon
cd ~
rm -rf /usr/local/bin/cryp*
wget https://github.com/Cryptosharescoin/shares/releases/download/v2.3.0/shares-2.3.0-linux.tar.gz
tar -xzvf shares-2.3.0-linux.tar.gz
sudo chmod -R 755 shares-cli
sudo chmod -R 755 sharesd
cp -p -r sharesd /usr/local/bin
cp -p -r shares-cli /usr/local/bin
rm -rf ~/.shares/blocks
rm -rf ~/.shares/chainstate
rm -rf ~/.shares/sporks
rm -rf ~/.shares/zerocoin
rm -rf ~/.shares/peers.dat

sudo mkdir ~/.shares-params
cd ~/.shares-params && wget https://github.com/Cryptosharescoin/shares/raw/main/params/sapling-output.params && wget https://github.com/Cryptosharescoin/shares/raw/main/params/sapling-spend.params
	
	
 shares-cli stop
 sleep 5
 #Create datadir
 if [ ! -f ~/.shares/shares.conf ]; then 
 	sudo mkdir ~/.shares
	
 fi

cd ~
clear
echo -e "${YELLOW}Creating shares.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.shares/shares.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
server=1
daemon=1

EOF

    sudo chmod 755 -R ~/.shares/shares.conf

    #Starting daemon first time just to generate masternode private key
    sharesd
sleep 7
while true;do
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(shares-cli createmasternodekey)
    if [ "$genkey" ]; then
        break
    fi
sleep 7
done
    fi
    
    #Stopping daemon to create shares.conf
    shares-cli stop
    sleep 5
cd ~/.shares && rm -rf blocks chainstate sporks zerocoin
cd ~/.shares && wget https://github.com/Cryptosharescoin/shares/releases/download/v2.3.0/bootstrap.zip
cd ~/.shares && unzip bootstrap.zip
sudo rm -rf ~/.shares/bootstrap.zip

	
# Create shares.conf
cat <<EOF > ~/.shares/shares.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
rpcport=$RPC
port=$PORT
listen=1
server=1
daemon=1

logtimestamps=1
maxconnections=256
masternode=1
externalip=$publicip:$PORT
masternodeaddr=$publicip:$PORT
masternodeprivkey=$genkey
addnode=208.167.249.234
addnode=173.199.119.55
addnode=104.238.131.131 
addnode=207.148.18.27
addnode=45.77.222.79
addnode=108.61.81.41

 
EOF
    sharesd -daemon
#Finally, starting daemon with new shares.conf
printf '#!/bin/bash\nif [ ! -f "~/.shares/cryptoshares.pid" ]; then /usr/local/bin/sharesd -daemon ; fi' > /root/sharesauto.sh
chmod -R 755 /root/sharesauto.sh
#Setting auto start cron job for CRYPTOSHARES
if ! crontab -l | grep "sharesauto.sh"; then
    (crontab -l ; echo "*/5 * * * * /root/sharesauto.sh")| crontab -
fi

echo -e "========================================================================
${GREEN}Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${GREEN}$publicip${NC}
Masternode Private Key: ${GREEN}$genkey${NC}
Now you can add the following string to the masternode.conf file 
======================================================================== \a"
echo -e "${GREEN}SHARES_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${GREEN}masternode.conf${NC} file and replace:
    ${GREEN}SHARES_mn1${NC} - with your desired masternode name (alias)
    ${GREEN}TxId${NC} - with Transaction Id from getmasternodeoutputs
    ${GREEN}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the CRYPTOSHARES network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'Is Synced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${GREEN}Node just started, not yet activated${NC} or
    ${GREEN}Node  is not in masternode list${NC}, which is normal and expected.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in shares.conf:
${GREEN}cat ~/.shares/shares.conf${NC}
Here is your shares.conf generated by this script:
-------------------------------------------------${GREEN}"
echo -e "${GREEN}SHARES_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
cat ~/.shares/shares.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit shares.conf, first stop the sharesd daemon,
then edit the shares.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the sharesd daemon back up:
to stop:              ${GREEN}shares-cli stop${NC}
to start:             ${GREEN}sharesd${NC}
to edit:              ${GREEN}nano ~/.shares/shares.conf${NC}
to check mn status:   ${GREEN}shares-cli getmasternodestatus${NC}
========================================================================
To monitor system resource utilization and running processes:
                   ${GREEN}htop${NC}
========================================================================
"