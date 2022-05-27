#!/bin/bash

#stop_daemon function
function stop_daemon {
    if pgrep -x 'cryptosharesd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop cryptosharesd${NC}"
        cryptoshares-cli stop
        sleep 30
        if pgrep -x 'cryptosharesd' > /dev/null; then
            echo -e "${RED}cryptosharesd daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            sudo pkill -9 cryptosharesd
            sleep 30
            if pgrep -x 'cryptosharesd' > /dev/null; then
                echo -e "${RED}Can't stop cryptosharesd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}


echo "Your CRYPTOSHARES Masternode Will be Updated To The Latest Version v1.0.2 Now" 
sudo apt-get -y install unzip

#remove crontab entry to prevent daemon from starting
crontab -l | grep -v 'sharesauto.sh' | crontab -

#Stop cryptosharesd by calling the stop_daemon function
stop_daemon

rm -rf /usr/local/bin/cryptoshares*
mkdir SHARES_1.0.2
cd SHARES_1.0.2
wget https://github.com/Cryptosharescoin/shares/releases/download/1.0.2/shares-1.0.2-linux.tar.gz
tar -xzvf shares-1.0.2-linux.tar.gz
mv cryptosharesd /usr/local/bin/cryptosharesd
mv cryptoshares-cli /usr/local/bin/cryptoshares-cli
chmod +x /usr/local/bin/cryptoshares*
rm -rf ~/.cryptoshares/blocks
rm -rf ~/.cryptoshares/chainstate
rm -rf ~/.cryptoshares/sporks
rm -rf ~/.cryptoshares/zerocoin
rm -rf ~/.cryptoshares/peers.dat
cd ~/.cryptoshares/
wget https://github.com/Cryptosharescoin/shares/releases/download/1.0.2/bootstrap.zip
unzip bootstrap.zip

cd ..
rm -rf ~/.cryptoshares/bootstrap.zip ~/SHARES_1.0.2

# add new nodes to config file
sed -i '/addnode/d' ~/.cryptoshares/cryptoshares.conf

echo "addnode=208.167.249.234
addnode=173.199.119.55
addnode=207.148.18.27
addnode=45.77.222.79
addnode=108.61.81.41" >> ~/.cryptoshares/cryptoshares.conf

#start cryptosharesd
cryptosharesd -daemon

printf '#!/bin/bash\nif [ ! -f "~/.cryptoshares/cryptoshares.pid" ]; then /usr/local/bin/cryptosharesd -daemon ; fi' > /root/sharesauto.sh
chmod -R 755 /root/sharesauto.sh
#Setting auto start cron job for CRYPTOSHARES
if ! crontab -l | grep "sharesauto.sh"; then
    (crontab -l ; echo "*/5 * * * * /root/sharesauto.sh")| crontab -
fi

echo "Masternode Updated!"
echo "Please wait a few minutes and start your Masternode again on your Local Wallet"