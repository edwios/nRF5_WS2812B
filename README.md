
#nRF52832 with WS2812B LED Array 

This is a simple demo program for the Nordic Semiconductor's nRF52832 Bluetooth SoC. It displays a flowing rainbow of colors when connected to a NeoPixel LED strip with WS2812B LEDs.

The source code is targeted to the nRF5 SDK v12.1.0. Other versions of SDK may require changes to the source code. The WS2812B drivers included: i2s_ws2812b_drive and ws2812b_drive, are from Takafumi Naka-san and copyrighted 2015,2016 Takafumi Naka[1].

Thank you Naka-san for your pioneer works on the WS2812B drivers.

Installation
============

Create a folder under "example" in your nRF5 SDK install path and copy the parent directory of this README to it.
Example：$NRF5SDK/examples/works/ws2812b_rainbow
Modify SDK_ROOT in the Makefile (located under pca10040/armgcc/) to point to $NRF5SDK if you put the project directory in a different location or depth, the default is 3 levels up the project directory (SDK_ROOT := $(PROJ_DIR)/../../..)

Configurations
==============

Configure the parameters for running the demo in config.h, they include the number of LEDs on the LED strip, the demo period and update period, etc.

Number of LEDs
--------------
NUM_LEDS

You can leave others to the defaults in config.h but you *must* set the NUM_LEDS to the correct number of LEDs on your LED strip. Wrong value will result in a non-functioning demo.

Current Consumptions
--------------------
MAX_TOTAL_CURRENT

The MAX_TOTAL_CURRENT parameter control how much current can be used by summing all the LED's current according to their brightness (and color). The current used for one LED is defined in ws2812b_drive_calc_current() inside the ws2812b_drive.c

You may want to adjust the MAX_TOTAL_CURRENT in relation to the number of LEDs and your power supply.

Output Pin
----------
STDOUT

The control signal output (SDOUT) is defaulted to P0.11 here in the demo but you are free to change it to any port available.

Driving the LED Strip
=====================
To make it work with a WS2812B LED strip/matrix, the control signal *must* go through a level shifter. The nRF52832 cannot drive the LED control line (DI) directly (not that it will damage the SoC but it simply won't work).

I used TI's TXB0104 level conveter, datasheet here <a href="http://www.ti.com/lit/ds/symlink/txb0104.pdf">http://www.ti.com/lit/ds/symlink/txb0104.pdf</a>, although the TXB0101 is a better fit because we only need one port here, however, I could not find any module out there and only the TXB0104 is available in modules.

Among other possible places, the TXB0104 module is also available from Sparkfun <a href="https://www.sparkfun.com/products/11771">https://www.sparkfun.com/products/11771</a>

Connect the control signal (SDOUT) to port A1 of the TXB0104 and connect port B1 (output) to the LED control line (DI) of the LED strip. 

References
==========
[1]	nRF52832 + WS2812B その5: I2S で制御, http://takafuminaka.blogspot.hk/2016/02/nrf52832-ws2812b-5-i2s.html

