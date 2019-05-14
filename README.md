# ants2-x11

Dockerized GUI version of ANTS2 package with graphics exported via plain X11 

## Usage

Create two folders for sharing files between the host and the ANTS inside the container, for example
`ants2docker/config` and `ants2docker/work` in your home directory. Then start a container: 

`docker run -it -v $HOME/ants2docker/config:/ants_config -v $HOME/ants2docker/work:/work -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -e UID=$(id -u) -e GID=$(id -g) -e USER=$USER vovasolo/ants2-x11:0.1`
