#!/bin/bash

# All code from: http://www.smolloy.com/2015/12/epics-ioc-on-a-raspberry-pi/

# Download the necessary source files
echo "Downloading the necessary source files"
mkdir /home/pi/Downloads
cd /home/pi/Downloads
wget http://www.aps.anl.gov/epics/download/base/baseR3.14.12.5.tar.gz
wget http://aps.anl.gov/epics/download/modules/asyn4-28.tar.gz
wget http://epics.web.psi.ch/software/streamdevice/StreamDevice-2.tgz

# Create a place to work
echo "Creating a place to work: ~/Apps/epics"
mkdir -p /home/pi/Apps/epics
echo "Untar-ing EPICS base"
tar -zxf /home/pi/Downloads/baseR3.14.12.5.tar.gz -C /home/pi/Apps/epics/
echo "Creating links to epics folders at /usr/local"
sudo ln -s /home/pi/Apps/epics /usr/local/
ln -s /home/pi/Apps/epics/base-3.14.12.5 /home/pi/Apps/epics/base

# Set the EPICS environment variables
echo "Setting up the EPICS enviroment variables"
cat <<EOF >> /home/pi/.bash_aliases
export EPICS_ROOT=/usr/local/epics
export EPICS_BASE=\${EPICS_ROOT}/base
export EPICS_HOST_ARCH=/\\`\${EPICS_BASE}/startup/EpicsHostArch\\`
export EPICS_BASE_BIN=\${EPICS_BASE}/bin/\${EPICS_HOST_ARCH}
export EPICS_BASE_LIB=\${EPICS_BASE}/lib/\${EPICS_HOST_ARCH}
if [ "" = "\${LD_LIBRARY_PATH}" ]; then
    export LD_LIBRARY_PATH=\${EPICS_BASE_LIB}
else
    export LD_LIBRARY_PATH=\${EPICS_BASE_LIB}:\${LD_LIBRARY_PATH}
fi
export PATH=\${PATH}:\${EPICS_BASE_BIN}
EOF
. /home/pi/.bashrc

# Compile EPICS
echo "Compiling EPICS"
cd /home/pi/Apps/epics/base
make

# Install ASYN into EPICS
echo "Installing ASYN library into EPICS"
mkdir -p /home/pi/Apps/epics/modules
echo "Untar-ing"
tar -zxf /home/pi/Downloads/asyn4-28.tar.gz -C ~/Apps/epics/modules/
echo "Linking"
ln -s /home/pi/Apps/epics/modules/asyn4-28 /home/pi/Apps/epics/modules/asyn
echo "Editing the configuration"
cd /home/pi/Apps/epics/modules/asyn
sed -e '/IPAC/ s/^#*/#/' configure/RELEASE
sed -e '/SNCSEQ/ s/^#*/#/' configure/RELEASE
sed -e '/EPICS_BASE/ s/^#*/#/' configure/RELEASE
echo "EPICS_BASE=/usr/local/epics/base" >> configure/RELEASE
echo "Compiling"
cd /home/pi/Apps/epics/modules/asyn
make

# Install StreamDevice into EPICS
echo "Installing StreamDevice library into EPICS"
mkdir /home/pi/Apps/epics/modules/stream
cd /home/pi/Apps/epics/modules/stream
echo "Untar-ing"
tar -zxvf /home/pi/Downloads/StreamDevice-2.tgz -C  /home/pi/Apps/epics/modules/stream
echo "Configuring"
echo | makeBaseApp.pl -t support
echo "ASYN=/usr/local/epics/modules/asyn" >> configure/RELEASE
echo "Compiling 1"
make
echo "Compiling 2"
cd StreamDevice-2-6
make

echo "Done!"
