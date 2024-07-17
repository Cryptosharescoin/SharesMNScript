#!/bin/bash

#stop_daemon function
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


echo "Your CRYPTOSHARES Masternode Will be Updated To The Latest Version v2.2.0 Now" 
sudo apt-get -y install unzip

#remove crontab entry to prevent daemon from starting
crontab -l | grep -v 'sharesauto.sh' | crontab -

#Stop sharesd by calling the stop_daemon function
stop_daemon

rm -rf /usr/local/bin/shares*
mkdir SHARES_2.2.0
cd SHARES_2.2.0
wget https://github.com/Cryptosharescoin/shares/releases/download/v2.2.0/shares-2.2.0-linux-16.04.tar.gz
tar -xzvf shares-2.2.0-linux-16.04.tar.gz
mv sharesd /usr/local/bin/sharesd
mv shares-cli /usr/local/bin/shares-cli
chmod +x /usr/local/bin/cryptoshares*
rm -rf ~/.shares/blocks
rm -rf ~/.shares/chainstate
rm -rf ~/.shares/sporks
rm -rf ~/.shares/evodb
rm -rf ~/.shares/zerocoin
rm -rf ~/.shares/peers.dat
cd ~/.shares/
wget https://github.com/Cryptosharescoin/shares/releases/download/v2.2.0/bootstrap.zip
unzip bootstrap.zip

cd ..
rm -rf ~/.shares/bootstrap.zip ~/SHARES_2.2.0

# add new nodes to config file
sed -i '/addnode/d' ~/.shares/shares.conf

echo "addnode=208.167.249.234
addnode=173.199.119.55
addnode=104.238.131.131
addnode=207.148.18.27
addnode=45.77.222.79
addnode=108.61.81.41" >> ~/.shares/shares.conf

#start sharesd
sharesd -daemon

printf '#!/bin/bash\nif [ ! -f "~/.shares/cryptoshares.pid" ]; then /usr/local/bin/sharesd -daemon ; fi' > /root/sharesauto.sh
chmod -R 755 /root/sharesauto.sh
#Setting auto start cron job for CRYPTOSHARES
if ! crontab -l | grep "sharesauto.sh"; then
    (crontab -l ; echo "*/5 * * * * /root/sharesauto.sh")| crontab -
fi

echo "Masternode Updated!"
echo "Please wait a few minutes and start your Masternode again on your Local Wallet"