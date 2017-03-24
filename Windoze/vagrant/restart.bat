HERE=%~d0
cd /d %HERE%

echo "STOPPING VM"
echo
vagrant halt
echo
echo "DESTROYING VM"
echo 
vagrant destroy -f
echo
echo "MAILING PATCHES HOME"
echo
..\sync2home\mail_patches_home.sh
echo
echo "UPDATING BASE IMAGE"
echo
vagrant box update
echo
echo "STARTING VM"
echo
vagrant up
echo
echo "DONE"

REM pause
REM vagrant halt
