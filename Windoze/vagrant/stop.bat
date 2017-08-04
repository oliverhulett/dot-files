set HERE=%~dp0
cd /d %HERE%

REM Vagrant needs to explicitly not go through a proxy...
set http_proxy=
set https_proxy=
set HTTP_PROXY=
set HTTPS_PROXY=

echo "STOPPING VM"
echo
vagrant halt
echo
echo "DESTROYING VM"
echo
vagrant destroy -f
echo
echo "DONE"
