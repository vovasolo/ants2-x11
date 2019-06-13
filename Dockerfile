FROM ubuntu:18.04

ARG ROOTTGZ=root_v6.16.00.Linux-ubuntu18-x86_64-gcc7.3.tar.gz
ARG G4VERSION=10.5.1
ARG JOBS=3

# Update all packages

RUN apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade
# Install packages
# Essential utilities
RUN apt-get -y install git nano wget
# Development environment (gcc, make, etc. + cmake)
RUN apt-get -y install build-essential cmake
# Qt5 base system + modules required by ANTS
RUN apt-get -y install qt5-default libqt5websockets5-dev qtscript5-dev
# additional libs needed by ROOT
RUN apt-get -y install libtbb-dev
# additional libs needed by ANTS
RUN apt-get -y install libeigen3-dev
# xeyes to test X11 forwarding + some X11 packaged needed by ROOT pulled as dependencies
RUN apt-get -y install x11-apps
# OpenGL, FLANN and FANN
RUN apt-get -y install libgl2ps-dev libflann-dev libfann-dev liblz4-dev
# Python scripting
RUN apt-get -y install python3-dev libpythonqt-qt5-python3-dev

# ROOT Installation
RUN wget https://root.cern.ch/download/$ROOTTGZ
RUN tar -xzf $ROOTTGZ -C /opt
RUN rm $ROOTTGZ
RUN echo ". /opt/root/bin/thisroot.sh" >> ~/.bashrc

# additional libs needed by GEANT
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y install libxerces-c-dev freeglut3-dev libmotif-dev tk-dev libxpm-dev libxmu-dev libxi-dev

# GEANT Installation
RUN wget https://github.com/Geant4/geant4/archive/v$G4VERSION.tar.gz
RUN tar -xzf v$G4VERSION.tar.gz -C /opt
RUN rm v$G4VERSION.tar.gz

RUN mkdir /geant4-build # refresh+1!
# build Geant4 
# NB: building a *single-threaded* version
# change DGEANT4_BUILD_MULTITHREADED to ON if feeling adventurous
RUN cd /geant4-build && cmake -DCMAKE_INSTALL_PREFIX=/opt/geant4-install -DGEANT4_USE_GDML=ON -DCMAKE_BUILD_TYPE=Release -DGEANT4_INSTALL_DATA=ON -DGEANT4_USE_OPENGL_X11=ON -DGEANT4_USE_XM=ON -DGEANT4_USE_QT=ON -DGEANT4_BUILD_MULTITHREADED=OFF /opt/geant4-$G4VERSION && make -j$JOBS && make install
RUN echo ". /opt/geant4-install/bin/geant4.sh" >> ~/.bashrc
#RUN echo ". /opt/geant4-install/bin/geant4.sh" > /etc/profile.d/geant4.sh && chmod +x /etc/profile.d/geant4.sh

# cleanup
RUN rm -rf /geant4-build
RUN rm -rf /opt/geant4-$G4VERSION
# End of GEANT4 stuff

# Ncrystal
RUN cd / && git clone https://github.com/mctools/ncrystal.git # refresh+1!
RUN cd /ncrystal && cmake . && make -j$JOBS && make install
RUN echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib" >> ~/.bashrc
#ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

# G4ants
RUN cd / && git clone https://github.com/andrmor/G4ants.git # refresh+1!
RUN cd /G4ants  && cmake . && make -j$JOBS && make install

# ANTS installation
RUN mkdir /ants2 && cd /ants2 && git clone -b Dev https://github.com/andrmor/ANTS2.git # refresh+1!

# Activate FLANN, FANN and Python scripting -- only needed for Dev branch
RUN sed -i 's/#CONFIG += ants2_flann/CONFIG += ants2_flann/g' /ants2/ANTS2/src/ants2.pro
RUN sed -i 's/#CONFIG += ants2_fann/CONFIG += ants2_fann/g' /ants2/ANTS2/src/ants2.pro
RUN sed -i 's/#CONFIG += ants2_Python/CONFIG += ants2_Python/g' /ants2/ANTS2/src/ants2.pro

RUN cd /ants2/ANTS2 && mkdir build

### the effect of sourcing a script lasts only inside one RUN command
### so we need to pack it together with compilation as a one-liner
RUN /bin/bash -c "source /opt/root/bin/thisroot.sh \
    && cd /ants2/ANTS2/build && qmake \"CONFIG += ants2_docker\" ../src/ants2.pro && make -j$JOBS"

ENV LD_LIBRARY_PATH=/opt/root/lib:/ncrystal
COPY startup.sh /root/
ENTRYPOINT ["/root/startup.sh"]


