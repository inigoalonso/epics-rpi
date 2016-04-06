#!/bin/bash

# All code from: http://www.smolloy.com/2015/12/epics-serial-communication-with-arduino/

# Create a new project
echo "Creating new project"
mkdir ~/Apps/epics/helloWorldIOC
cd ~/Apps/epics/helloWorldIOC
makeBaseApp.pl -t ioc helloWorldIOC
echo | makeBaseApp.pl -i -t ioc helloWorldIOC
echo "ASYN=/usr/local/epics/modules/asyn" >> configure/RELEASE
echo "STREAM=/usr/local/epics/modules/stream" >> configure/RELEASE

# Create the Protocol file
echo "Creating the Protocol file"
cat <<EOF >> ~/Apps/epics/helloWorldIOC/helloWorldIOCApp/Db/arduino.proto
Terminator = LF;
get_analog {
    out "R";
    in "R %f";
    ExtraInput = Ignore;
}
set_digital {
    out "W%d\n";
    ExtraInput = Ignore;
}
EOF

# Create the database file
cat <<EOF >> ~/Apps/epics/helloWorldIOC/helloWorldIOCApp/Db/arduino.db
record(ao, led:set) {
    field(DESC, "Arduino digi pin 11")
    field(DTYP, "stream")
    field(OUT, "@arduino.proto set_digital() $(PORT)")
    field(DRVL, "0")
    field(DRVH, "255")
}
record(ai, photo:get) {
    field(DESC, "Photo diode's output")
    field(DTYP, "stream")
    field(INP, "@arduino.proto get_analog() $(PORT)")
    field(SCAN, ".5 second")
}
EOF

#Environment preparation
echo "Preparing the environment"
cd ~/Apps/epics/helloWorldIOC/helloWorldIOCApp/Db
sed '/#DB += /a\
DB += arduino.db' Makefile

cd ~/ Apps/epics/helloWorldIOC/helloWorldIOCApp/src
sed -i '/helloWorldIOC_DBD += base.dbd/a\
helloWorldIOC_DBD += asyn.dbd
helloWorldIOC_DBD += stream.dbd
helloWorldIOC_DBD += drvAsynIPPort.dbd
helloWorldIOC_DBD += drvAsynSerialPort.dbd' Makefile
sed -i '/hellowWorldIOC_LIBS/a\
helloWorldIOC_LIBS += asyn
helloWorldIOC_LIBS += stream' Makefile

cd ~/Apps/epics/helloWorldIOC/iocBoot/iochelloWorldIOC
sed -i '/> envPaths/a\
epicsEnvSet(STREAM_PROTOCOL_PATH,"helloWorldIOCApp/Db")' st.cmd
sed -i '/helloWorldIOC_registerRecordDeviceDriver pdbbase/a\
drvAsynSerialPortConfigure("SERIALPORT","/dev/ttyACM0",0,0,0)
asynSetOption("SERIALPORT",-1,"baud","115200")
asynSetOption("SERIALPORT",-1,"bits","8")
asynSetOption("SERIALPORT",-1,"parity","none")
asynSetOption("SERIALPORT",-1,"stop","1")
asynSetOption("SERIALPORT",-1,"clocal","Y")
asynSetOption("SERIALPORT",-1,"crtscts","N")
dbLoadRecords("db/arduino.db","PORT='SERIALPORT'")' st.cmd
sed -i -e 's/\$(TOP)/\/home\/pi\/Apps\/epics\/helloWorldIOC/g' st.cmd
sed -i -e 's/\$(IOC)/iochelloWorldIOC/g' st.cmd

# Compile
echo "Compiling the new project"
cd ~/Apps/epics/helloWorldIOC
make

# Start the IOC
echo "Starting the IOC"
./bin/linux-arm/helloWorldIOC iocBoot/iochelloWorldIOC/st.cmd