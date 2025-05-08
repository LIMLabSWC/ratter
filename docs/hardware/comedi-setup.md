# Comedi Setup Guide

This guide explains how to set up and configure Comedi for hardware control in the ExperPort system.

## Overview

Comedi (Control and Measurement Device Interface) provides a unified interface for data acquisition hardware. In ExperPort, it's used for:
- Digital I/O control
- Hardware triggering
- Device synchronization

## Installation

1. Install Comedi:
   ```bash
   # Install dependencies
   apt-get install build-essential linux-headers-$(uname -r)
   
   # Download and compile Comedi
   git clone https://github.com/Linux-Comedi/comedi.git
   cd comedi
   ./configure
   make
   make install
   ```

2. Load required kernel modules:
   ```bash
   modprobe kcomedilib
   ```

## Device Configuration

### Parallel Port Setup

1. Configure parallel port driver:
   ```bash
   modprobe comedi_parport
   comedi_config /dev/comedi0 comedi_parport 0x378
   ```

2. Verify BIOS settings:
   - Enable parallel port
   - Note IO address (typically 0x378)

### National Instruments Cards

For NI cards:
```bash
modprobe ni_pcimio
comedi_config /dev/comedi0 ni_pcimio
```

## Testing Configuration

Use the ComediClientServer utility:

1. Obtain the utility:
   ```bash
   cvs -d :pserver:anonymous@rtlab.org:/cvs co ComediClientServer
   cd ComediClientServer
   qmake
   make
   ```

2. Run the server:
   ```bash
   # First, unload LynxTrig-RT if running
   rmmod LynxTrig-RT
   
   # Start the server
   Server/ComediServer
   ```

3. Run the client:
   ```bash
   Client/ComediClient
   ```
   - Enter 'localhost' in server name
   - Click "Connect"

## Hardware Connections

### Parallel Port Pinout

Data pins (D0-D7) are used for DIO lines:
- D0: Data bit 0
- D1: Data bit 1
- ...
- D7: Data bit 7

### DIO Line Configuration

1. Lines are automatically configured for input
2. Valid range: [first_trig_chan, first_trig_chan + num_trig_chans)
3. Binary pattern is read every 1/10th millisecond

## Integration with LynxTrig

1. Load LynxTrig with Comedi support:
   ```bash
   insmod LynxTrig-RT.o comedi_triggers=1 num_trig_chans=8 first_trig_chan=0
   ```

2. Verify configuration:
   - Check /proc/interrupts for conflicts
   - Monitor system logs for errors
   - Test with ComediClientServer

## Troubleshooting

1. **Module Load Failures**
   - Check kernel version compatibility
   - Verify hardware detection
   - Review system logs

2. **Connection Issues**
   - Verify IO addresses
   - Check cable connections
   - Test with ComediClientServer

3. **Performance Problems**
   - Monitor interrupt usage
   - Check for resource conflicts
   - Verify timing settings

## Support Resources

- [Comedi Documentation](http://www.comedi.org)
- [Linux Kernel Documentation](https://www.kernel.org/doc/html/latest/)
- System Administrator Support 