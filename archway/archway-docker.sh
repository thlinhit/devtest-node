#!/bin/bash

exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
	echo 'Skip curl installation because it is already installed'
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi

if [ ! $NODENAME ]; then
		read -p "Enter node name: " NODENAME
		echo 'export NODENAME='\"${NODENAME}\" >> $HOME/.bash_profile
	fi
	if [ ! $WALLET ]; then
		read -p "Enter wallet name: " WALLET
		echo 'export WALLET='\"${WALLET}\" >> $HOME/.bash_profile
	fi
	. $HOME/.bash_profile
sudo apt update && apt install jq -y
if exists docker; then
	echo ''
else
  curl -fsSL https://raw.githubusercontent.com/thlinhit/devtest-node/main/common/get-docker.sh -o get-docker.sh && sh get-docker.sh
fi
echo 'export CHAIN_ID='augusta-1 >> $HOME/.bash_profile
source $HOME/.bash_profile
sleep 2

# Cleanup
echo 'Clean up the old installation'
rm -f ~/.archway/config/genesis.json
docker rm -f archway 2&>/dev/null

# Install
echo 'Install the Archway node, CHAINID='$CHAIN_ID
docker run --rm -it -v $HOME/.archway:/root/.archway archwaynetwork/archwayd:augusta init $NODENAME --chain-id $CHAIN_ID
docker run --rm -it -v $HOME/.archway:/root/.archway archwaynetwork/archwayd:augusta config chain-id $CHAIN_ID

perl -i -pe 's/^minimum-gas-prices = .+?$/minimum-gas-prices = "0august"/' $HOME/.archway/config/app.toml
SEEDS="2f234549828b18cf5e991cc884707eb65e503bb2@34.74.129.75:31076,c8890bcde31c2959a8aeda172189ec717fef0b2b@95.216.197.14:26656"
PEERS="332dea7332a0c4647a147a08bf50bb2038931e4c@81.30.158.46:26656,4e08eb9d62607d05e3fa3fa52d98a00014c8040b@162.55.90.254:26656,4a701d399a0cd4a577e5b30c9d3cc5d75854936e@95.214.53.132:26456,0c019ac4e4f39d95355926435e50a25ed589915f@89.163.151.226:26656,b65efc14137a426a795b5e78cf34def7e5240231@89.163.164.211:26656,33baa872768e12d4100bce5eb875b90b8739a1d4@185.214.134.154:46656,76862fd5ee017b7b46f65a7ac15da12bba12f7f1@49.12.215.72:26656"

sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.archway/config/config.toml
sed -i.bak -e "s/prometheus = false/prometheus = true/" $HOME/.archway/config/config.toml

# curl -s "https://rpc.augusta-1.archway.tech/genesis" | jq '.result.genesis' > $HOME/.archway/config/genesis.json
curl -s "https://api.nodes.guru/archway_genesis.json" | jq '.result.genesis' > ~/.archway/config/genesis.json

docker run --rm -it -v $HOME/.archway:/root/.archway archwaynetwork/archwayd:augusta unsafe-reset-all
wget -O addrbook.json https://api.nodes.guru/addrbook_archway.json
mv addrbook.json $HOME/.archway/config/
docker run --restart=always -d -it --network host --name archway -v $HOME/.archway:/root/.archway archwaynetwork/archwayd:augusta start --x-crisis-skip-assert-invariants
echo "alias archwayd='docker exec -it archway archwayd'" >> $HOME/.bash_profile