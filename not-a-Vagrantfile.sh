#!/bin/bash

source "${HOME}/.bashrc"
source "${HOME}/.bash_aliases/19-env-proxy.sh"
source "${HOME}/.bash_aliases/19-env-pyvenv_setup.sh"

proxy_setup

sudo yum groupinstall -y "Development Tools"
sudo yum install -y wget curl telnet postgresql freetype-devel libpng-devel python-devel cmake vagrand ccache distcc cifs-utils samba samba-client protobuf protobuf-c protobuf-python protobuf-vim protobuf-compiler openssl-libs openssl-static valgrind golang-vim wireshark yakuake iotop nethogs sysstat java-1.8.0-openjdk-devel java-1.8.0-openjdk unixODBC-devel postgresql-devel libxml2-devel libxslt-devel aspell aspell-en
sudo pip install trdb
sudo yum install -y http://artifactory.aus.optiver.com/artifactory/dev/trd/courier-1.1.0-1.x86_64.rpm

wget --quiet https://storage.googleapis.com/golang/go1.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.6.linux-amd64.tar.gz
rm go1.6.linux-amd64.tar.gz

python_setup

