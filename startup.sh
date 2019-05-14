#!/bin/bash 
addgroup --gid $GID $USER
useradd -m -s /bin/bash -u $UID -g $GID $USER
chmod 777 /work
chmod 777 /ants_config
ln -s /ants_config /home/$USER/.config
cd /ants2/ANTS2/build
runuser -u $USER ./ants2 
