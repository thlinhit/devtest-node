#!/bin/bash

# ARCHWAY_CHAIN="torii-1"
ARCHWAY_CHAIN="augusta-1"
ARCHWAY_MONIKER="LinhArchway"
ARCHWAY_WALLET="LinhWallet" 
HOMEDIR=~/.archway

# GENESIS_URL="https://github.com/archway-network/testnets/blob/torii/penultimate_genesis.json"
GENESIS_URL="https://rpc.augusta-1.archway.tech/genesis"


exists()
{
  command -v "$1" >/dev/null 2>&1
}

bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi

if exists go; then
	echo 'Skip golang installation because it is already installed'
else
    wget -q -O get-golang.sh https://raw.githubusercontent.com/thlinhit/devtest-node/main/common/get-golang.sh && chmod +x get-golang.sh && sudo /bin/bash get-golang.sh
fi
source $HOME/.bash_profile
sleep 2

# Install dependency
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu -y

# Install Archway
echo 'Install Archway from source'
git clone https://github.com/archway-network/archway
cd archway
git checkout main
make install


# set vars
echo 'Configure Archway'
echo 'export ARCHWAY_CHAIN='${ARCHWAY_CHAIN} >> $HOME/.bash_profile
echo 'export ARCHWAY_MONIKER='${ARCHWAY_MONIKER} >> $HOME/.bash_profile
echo 'export ARCHWAY_WALLET='${ARCHWAY_WALLET} >> $HOME/.bash_profile
echo 'export HOMEDIR='${HOMEDIR} >> $HOME/.bash_profile
source $HOME/.bash_profile
sleep 2


# init
echo 'Run Archwayd Init'
archwayd init ${ARCHWAY_MONIKER} --chain-id $ARCHWAY_CHAIN --home $HOME

# config
echo 'Run Archwayd config chain-id'
archwayd config chain-id $ARCHWAY_CHAIN

# perl -i -pe 's/^minimum-gas-prices = .+?$/minimum-gas-prices = "0august"/' $HOME/.archway/config/app.toml

SEEDS="2f234549828b18cf5e991cc884707eb65e503bb2@34.74.129.75:31076,c8890bcde31c2959a8aeda172189ec717fef0b2b@95.216.197.14:26656"
PEERS="332dea7332a0c4647a147a08bf50bb2038931e4c@81.30.158.46:26656,4e08eb9d62607d05e3fa3fa52d98a00014c8040b@162.55.90.254:26656,4a701d399a0cd4a577e5b30c9d3cc5d75854936e@95.214.53.132:26456,0c019ac4e4f39d95355926435e50a25ed589915f@89.163.151.226:26656,b65efc14137a426a795b5e78cf34def7e5240231@89.163.164.211:26656,33baa872768e12d4100bce5eb875b90b8739a1d4@185.214.134.154:46656,76862fd5ee017b7b46f65a7ac15da12bba12f7f1@49.12.215.72:26656"

sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.archway/config/config.toml
sed -i.bak -e "s/prometheus = false/prometheus = true/" $HOME/.archway/config/config.toml


# get genesis.json
echo 'Download Genesis URL'
if [ "$ARCHWAY_CHAIN" = "augusta-1" ]; then
    echo "Download genesis for chain augusta-1"
    sleep(2)
    curl -s ${GENESIS_URL} | jq '.result.genesis' > ~/.archway/config/genesis.json
else
    echo "Download genesis for chain torii"
    sleep(2)
    wget -q -O genesis.json ${GENESIS_URL}
    cp genesis.json $HOMEDIR/config/genesis.json
fi


# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="5000"
pruning_interval="10"

sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.archway/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.archway/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.archway/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.archway/config/app.toml

# reset
archwayd unsafe-reset-all

# wget -O addrbook.json https://api.nodes.guru/addrbook_archway.json
# mv addrbook.json $HOME/.archway/config/




# create service
echo 'Create service'
tee $HOME/archwayd.service > /dev/null <<EOF
[Unit]
Description=ARCHWAY
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which archwayd) start --x-crisis-skip-assert-invariants
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/archwayd.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable archwayd
sudo systemctl restart archwayd && journalctl -u archwayd -f -o cat
