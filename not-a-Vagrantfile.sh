#!/bin/bash -x

source "${HOME}/.bashrc"
source "${HOME}/.bash_aliases/19-env-proxy.sh"
source "${HOME}/.bash_aliases/19-env-pyvenv_setup.sh"

proxy_setup

sudo yum groupinstall -y "Development Tools"
sudo yum install -y wget curl telnet postgresql-server postgresql-contrib postgresql freetype-devel libpng-devel python-devel unixODBC-devel postgresql-devel libxml2-devel libxslt-devel
sudo yum install -y cmake ccache distcc protobuf protobuf-c protobuf-python protobuf-compiler valgrind protobuf-vim golang-vim
sudo yum install -y vagrant yakuake iotop nethogs sysstat aspell aspell-en cifs-utils samba samba-client openssl-libs openssl-static wireshark java-1.8.0-openjdk-devel java-1.8.0-openjdk

wget --quiet https://storage.googleapis.com/golang/go1.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.6.linux-amd64.tar.gz
rm go1.6.linux-amd64.tar.gz

wget --quiet http://artifactory.aus.optiver.com/artifactory/dev/trd/drone_linux_amd64.tar.gz
sudo tar -C /usr/local/bin -xzf drone_linux_amd64.tar.gz
rm drone_linux_amd64.tar.gz

python_setup

pip install --upgrade invoke trdb docker-compose
sudo yum install -y http://artifactory.aus.optiver.com/artifactory/dev/trd/courier-1.1.0-1.x86_64.rpm


