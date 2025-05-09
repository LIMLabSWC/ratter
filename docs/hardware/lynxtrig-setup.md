# LynxTrig Setup Guide

This guide explains how to set up and use the LynxTrig system for real-time sound triggering in behavioral experiments.

## Prerequisites

1. LynxTWO-RT.o sound driver for the Lynx22 Sound Card
2. Latest version of LynxTrig software
3. RTLinux-3.1 or 3.2
4. Linux Kernel version 2.4.xx
5. LynxTWO (L22) soundcard

## Hardware Requirements

### Sound Card
- LynxTWO (L22) soundcard
- PCI ID: 1621:0023
- Verify with `lspci` command:
  ```
  00:0b.0 Multimedia audio controller: Unknown device 1621:0023
  ```

### Interrupt Configuration
For optimal performance, the LynxTWO card should have a dedicated interrupt:
1. Check current IRQ assignment:
   ```bash
   cat /proc/pci
   ```
2. View interrupt usage:
   ```bash
   cat /proc/interrupts
   ```
3. Adjust hardware configuration if needed:
   - Move card to different PCI slots
   - Disable unused devices
   - Configure BIOS settings

## Installation

1. Obtain required software:
   ```bash
   # LynxTWO-RT driver
   cvs -d :pserver:anonymous@rtlab.org:/cvs co LynxTWO-RT
   
   # LynxTrig software
   cvs -d :pserver:anonymous@rtlab.org:/cvs co LynxTrig
   ```

2. Load kernel modules:
   ```bash
   insmod ../LynxTWO/LynxTWO-RT.o
   insmod LynxTrig-RT.o
   ```

3. Start the server:
   ```bash
   ./LynxTrigServer
   ```

## MATLAB Integration

Use the `@RTLSoundMachine` class in MATLAB:

```matlab
% Initialize
mysm = RTLSoundMachine('hostname');  % Replace with your RTLinux box hostname

% Configure
mysm = SetSampleRate(mysm, 44000);   % Supports up to 210KHz

% Load and play sounds
mysm = LoadSound(mysm, 1, sound_vector);  % 1xN or 2xN vector for mono/stereo
PlaySound(mysm, 1);
```

## Hardware Triggering

To enable hardware triggering:

```bash
insmod LynxTrig-RT.o comedi_triggers=1 num_trig_chans=8 first_trig_chan=0
```

This configuration:
- Uses COMEDI device on /dev/comedi0
- Configures 8 DIO lines starting at channel 0
- Requires proper COMEDI setup (see [Comedi Setup Guide](comedi-setup.md))

## Troubleshooting

1. **Module Load Failure**
   - Verify COMEDI device configuration
   - Check interrupt conflicts
   - Ensure proper kernel version

2. **Sound Issues**
   - Verify sample rate compatibility
   - Check sound card connections
   - Monitor system logs for errors

3. **Trigger Problems**
   - Verify DIO line connections
   - Check COMEDI configuration
   - Test with ComediClientServer utility

## Support

For additional support:
- Check the [Comedi documentation](http://www.comedi.org)
- Contact system administrators
- Refer to the [FSM Documentation](../technical/fsm-documentation.md) 