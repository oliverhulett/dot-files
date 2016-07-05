useradd -s /bin/bash -p -u1000 -g users -G users,adm,wheel,docker,vboxsf,root olihul
passwd olihul
userdel -fr vagrant
