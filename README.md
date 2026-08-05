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

The scope of this project was to design the digital pipeline between an ADC expansion board ([Pmod AD1](https://digilent.com/reference/pmod/pmodad1/reference-manual)) and an OLED screen expansion board ([Pmod OLEDrgb](https://digilent.com/reference/pmod/pmodoledrgb/reference-manual)) housed by the [Basys 3 FPGA trainer board](https://digilent.com/reference/programmable-logic/basys-3/reference-manual). The scope of the project was then extended to implement a function generator with a DAC expansion ([Pmod DA2](https://digilent.com/reference/pmod/pmodda2/reference-manual)) to avoid having to use external lab equipement for testing and demonstration. The following image shows the required harware arrangement.

<p align="center">
  <img src="images/hardware.png" width="800">
</p>

## Key Features

## System Architecture

## Testing

## Future Improvements
