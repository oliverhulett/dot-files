HERE=%~d0
cd /d %HERE%

vagrant halt
vagrant destroy -f
..\sync2home\mail_patches_home.sh
vagrant box update
vagrant up

REM pause
REM vagrant halt
