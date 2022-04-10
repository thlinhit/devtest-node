#!/bin/bash

exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists go; then
	echo "Golang already installed"
	exit 0
fi

if exists wget; then
	echo 'Skip wget installation because it is already installed'
else
  sudo apt update && sudo apt install wget -y < "/dev/null"
fi

if exists make; then
	echo 'Skip make installation because it is already installed'
else
  sudo apt update && sudo apt install make -y < "/dev/null"
fi

bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi

ver="1.17.2"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
sleep 2

echo "Golang installed successfully"