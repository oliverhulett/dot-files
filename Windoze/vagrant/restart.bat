HERE=%~d0
cd /d %HERE%

vagrant halt
vagrant destroy -f
vagrant box update
vagrant up

REM pause
REM vagrant halt
