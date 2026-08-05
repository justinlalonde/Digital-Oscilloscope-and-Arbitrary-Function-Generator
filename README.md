# Digital-Oscilloscope-and-Arbitrary-Function-Generator
Two-channel digital oscilloscope and arbitrary function generator implemented in VHDL on a Xilinx Artix-7 FPGA (Basys3 board)

**June 2026 - August 2026**

<p align="center">
  <img src="images/project.jpg" width="1000">
</p>

## Table of Contents

- [Project Overview](#project-overview)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Testing](#testing)
- [Future Improvements](#future-improvements)

## Project Overview
The idea for this project originally came from a 2016 project done by two MIT Students (see [Final Projects - Memorable Projects - Instrumentation](https://web.mit.edu/6.111/volume2/www/f2019/)). Originally the project was supposed to use a VGA display interface, but after failed attempts, this display method was switched to a 96x64 OLED extension board with 16-bit color resolution. 

The scope of this project was to design the digital pipeline between an ADC expansion board ([Pmod AD1](https://digilent.com/reference/pmod/pmodad1/reference-manual)) and an OLED screen ([Pmod OLEDrgb](https://digilent.com/reference/pmod/pmodoledrgb/reference-manual)) housed by the [Basys 3 FPGA trainer board](https://digilent.com/reference/programmable-logic/basys-3/reference-manual). The scope of the project was later extended to also implement a function generator using a DAC expansion board ([Pmod DA2](https://digilent.com/reference/pmod/pmodda2/reference-manual)) to avoid having to use external lab equipement for testing and validation. The following image shows the required harware arrangement.

<p align="center">
  <img src="images/hardware_requirements.png" width="800">
</p>

## Key Features
**Oscilloscope**
- Two-channel signal acquisition via 12-bit SPI ADC (Pmod AD1, AD7476) at up to 917.4 kSPS
- 0V to 3.3V voltage input range with 1.65V assumed bias voltage
- Adaptive waveform reconstruction using Equivalent-Time Sampling (ETS) for full reconstruction of high frequency signals
- Rising-edge trigger detection fixed at 1.65V
- User-adjsutable horizontal and vertical scaling of displayed waveforms in oscilloscope window
- Real-time cursor measurement system: on-screen cursor position converted to voltage (0–3.3V), 4 cursors across 2 channels
- Multiplexed 4-digit 7-segment display for last cursor voltage readout (see image below)
- OLED display (SSD1331, 96×64) for waveform rendering

<p align="center">
  <img src="images/cursors.png" width="500">
</p>

**Function Generator**
- Two independent arbitrary function generator channels (sine, square, triangle/sawtooth) with frequency and amplitude control
- User control interface for signal type, amplitude and frequency adjustement for each output channel
- 12-bit SPI DAC output stage (Pmod DA2, DAC121S101) for generating waveforms at up to 925.9 kSPS

<p align="center">
  <img src="images/screen.png" width="400">
</p>

## System Architecture
This VHDL project's architecture is composed of a top module which instantiates 14 sub-modules. Three of these submodule (layer_compositor, function_generator and input_manager) then instantiate other submodules themselves without any futher depth. We'll cover the top module's architecture in this section. The following diagram shows the top module's architecture along with the various interfaces between modules.
<p align="center">
  <img src="images/top_module.png" width="900">
</p>
The highlighted interfaces in the above diagrams are shown in detail in the following images
<p align="center">
  <img src="images/ADC_interface.png" width="250">
  &nbsp;&nbsp;
  <img src="images/DAC_interface.png" width="350">
  &nbsp;&nbsp;
  <img src="images/point_interface.png" width="200">
  &nbsp;&nbsp;
  <img src="images/cursor_interface.png" width="330">
  &nbsp;&nbsp;
  <img src="images/layer_interface.png" width="280">
  &nbsp;&nbsp;
  <img src="images/pixel_interface.png" width="200">
  &nbsp;&nbsp;
  <img src="images/control_interface.png" width="450">
</p>


## Testing

## Future Improvements
