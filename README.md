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
The idea for this project originally came from a 2016 project done by two MIT Students (see Final Projects - Memorable Projects - Instrumentation on [this website](https://web.mit.edu/6.111/volume2/www/f2019/)). Originally, my take on a digital oscilloscope was supposed to use a VGA display interface, but after some failed attempts, the display fornat was switched to use a 96x64 OLED screen with 16-bit color resolution. 

The scope of this project was to design the digital pipeline between an ADC expansion board ([Pmod AD1](https://digilent.com/reference/pmod/pmodad1/reference-manual)) and an OLED screen ([Pmod OLEDrgb](https://digilent.com/reference/pmod/pmodoledrgb/reference-manual)) housed by the [Basys 3 FPGA trainer board](https://digilent.com/reference/programmable-logic/basys-3/reference-manual). The project was later extended to also implement a function generator using a DAC expansion board ([Pmod DA2](https://digilent.com/reference/pmod/pmodda2/reference-manual)) to avoid having to use external lab equipement for testing and validation. The following image shows the required harware arrangement.

<p align="center">
  <img src="images/hardware_requirements.png" width="800">
</p>

## Key Features
**Oscilloscope**
- Two-channel signal acquisition via 12-bit SPI ADC (Pmod AD1, AD7476) at up to 917.4 kSPS
- 0V to 3.3V voltage input range with 1.65V assumed signal bias voltage
- Adaptive waveform reconstruction using Equivalent-Time Sampling (ETS) for full reconstruction of high frequency signals
- Rising-edge trigger signal detection fixed at 1.65V
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

Here's an overview of what each submodule does and what other modules they might instantiate :
- **pmodOLEDrgb** : This module is responsible for interfacing with the OLED display controller ([SSD1331](https://cdn-shop.adafruit.com/datasheets/SSD1331_1.2.pdf), 96x64) via an SPI-like protocol. This is the only module in the project that was imported from an [online ressource](https://yannick-bornat.enseirb-matmeca.fr/wiki/doku.php/en202:pmodoledrgb) as the OLED controller requires a very specific startup sequence and has a large set of user-programmable registers. This modules recieves 7-bit column indeces, 6-bit row indeces and 16-bit color values from the layer_compositor module and stores them in an internal bitmap array which is periodically transfered to the OLED controller. This module instantiates delay_line submodules for synchronisation of its interface with the pmodOLEDrgb module.
- **layer_compositor** : This module allows oscilloscope elements (layers) to be displayed on top of one another with priority ordering. For example, while the background_layer is the black and gray background grid of the oscilloscope window, the waveform channels and the cursor layers have to be displayed above this grid and relative to one another. Each external layer module therefore give a one-bit active value (wether they are to be displayed for given row and column indeces) and an rgb value for their color. This modules has internal column an row counters and sweeps the screen's pixels and polls for each one the different layers and selects which one'S rgb value is to be displayed for any given pixel.
- **bg_layer** : This is the background layer which interfaces with the layer_compositor module giving it the color of the background grid pattern for any given pixel on the screen.
- **pmodAD1** : This module interfaces with the ADC Pmod AD1 extension board, which itself implements two ADC IC with 1MSPS capabilities. In our application, this modules reads samples from these 12-bit ADC at a 917.4 kSPS rate with a SPI-like protocol and interfaces with the wave_capture modules giving them the read 12-bit values.
- **wave_capture** : this module implements all digital signal processing blocks necessary for signal reconstruction and display with its associated ch_layer. It uses Equivalent-Time-Sampling, which anchors on the detected rising edge triggers of the input signal and registers an offset sample (decimating all opthers) from this trigger event in an internal buffer of values. This internal array of registered values is then accessed by the display layer module, which in turns computes it so that i can be displayed by the layer_compositor. This means that only one sample per trigger cycle is registered, which is great for displaying higher frequency signal with better fidelity, but is not ideal for lower frequency signals, which now take longer times to update in the oscilloscope window as it takes 96 trigger cycles (signal periods) for its full display. See [Future Improvements](#future-improvements) section for suggestions on how to better this signal processing scheme. This module is also responsible for takling into account the user-set horiozontal zoom, adjusting the sampling registering in consequence for effective display of signals with the propoer horizontal range.
- **ch_layer** : this layer module interfaces with the layer_compositor module and is responsible for displaying a given waveform, which is reconstructed with a wave_capture module instance. It takes in the row and column indeces from the layer_compositor, relays the column index it to the wave_capture module and fetches the associated 12-bit value from its buffer. If the value matches the pixel row that is currently considered by the layer_compositor, this layer module asserts its active output. This is the module that considerst the user-set vertical zoom. It keeps a current value of the current zoom factor and adjusts how the waveform will be displayed in consequence, all the while keeping it centered around the 1.65V center voltage point of the project.
- **ch_cursor_layer** : this layer module acts both as the display interface of the cursors and their handler. This layer module is instantiated for each waveformn channel and keeps an internal value of the current cursor positions, updating them with user button presses when appropriate.
- **cursor_measurement** : this module interfaces with the ch_cursor_layer module instances, taking for input the current cursor positions, and, with the vertical zoom values from the ch_layer instances, measuring the associated analog voltage value for each cursor. It computes the voltage value for the last-moved cursor and displays it on the Basys 3 board's 4-digit 7-segment display.
- **pmodDA2** : this module is responsible for interfacing with the extension DAC board which implements two 12-bit DAC IC's with a theoretical output rate of 1MSPS. This module effectively outputs analog signal samples at a 925.9 kSPS rate. It implements the logic for the SPI-like interfacing with the Pmod DA2 extension board and also interfaces with the function_generator module, which supplies it with a constant stream of 12-bit values.
- **function_generator** : this is the module which, thanks to the pmodDA2 module and the extension DAC board, generates the analog signals for the project. It handles the user-adjustable frequency and amplitude parameters to generate the proper signal parameters and can change between the three signal types (sine, square and sawtooth ramp). It works by instantiating (for each channel) a phase accumulator module, which accumulates a 24-bit phase value, and a Look-Up-Table (LUT) submodule for each signal type. Thhe function_generator modules, depending on the user-set singal frequency, generates the 24-bit phase increments for a system clock period (10ns) and accumulates it to the current phase with the phase_accumulator submodule. The accumulated phase is then fed into the signal LUT's and, depending on what type of signal is selected for a given channel, it select one of the LUT's 12-bit output value and scales it, depending on the requested signal amplitude. This module therfore implements the entire digital backend for signal generation.
- **input_manager** : this module is responsible for taking raw button inputs, debouncing them, and generating pulsed signals on button presses. It also considers three slide-switches on the FPGA board which allows to configure what the buttons should do and map the button presses to the appropriate user control signal to one of the project's modules. Thes control signal can be to adjust the oscilloscope horizontal or vertical zoom or move the vertical position of the cursors for example.


## Testing
TBD
## Future Improvements
hybrid ETS RTS with decimation for signal reconstruction depending on signal frequency
Include a second display for showing measurement values like cursor positions voltages, frequency and the current control mode of the oscilloscope.
Analog front end for real +-10V range of measurement with signal conditioning to 0V to 3.3V
