[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

<img src="https://raw.githubusercontent.com/AlexWoodblock/ArduinoBleKeyboard/main/assets/icon.png" alt="Project logo" width="128">

# Arduino BLE keyboard

This project was born out of curiosity and a certain aversion to buying a Bluetooth keyboard that will sit and collect dust most of the time.

It was also a project to explore how does Swift UI fare on Mac OS (spoiler: quite good, but not without its' problems) and to to work with custom-defined BLE interaction protocol.

## Components of the project
- Client for macOS that sends keypresses to Arduino Nano 33 BLE
- Firmware for Arduino Nano 33 BLE that takes the data sent by client and emulates keypresses as a Human Interface Device

## BLE interactions
BLE specifications in this firmware are pretty simple:
- Device advertises itself with the name `Virtual Keyboard`
- Service `98AD` is advertised - let's refer to it as **keyboard service**
- Characteristic `98AF` is a part of keyboard service. It can only be written to without confirmation. Let's refer to it as **RX characteristic**.
- On every write to RX characteristic, a keypress will be generated based on the data written.

### Data format for RX characteristic
- Size: 32 bits
- First 16 bits are for HID key code (the key itself) as an unsigned integer
- Second 16 bits are for HID key modifier (Shift, Ctrl, etc.) as an unsigned integer
- Integers should be big-endian

It's not intended to be used as a keyboard replacement for something serious - if you need a keyboard, just go and buy one. This is mostly for fun and to see what interesting things could be squeezed out of Arduino.

# Known problems
- Sending input while screen is locked will lock up the device, leading to BLE connection loss sometimes. 
