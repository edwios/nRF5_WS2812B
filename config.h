/* Copyright (c) 2016 ioStation Ltd. All Rights Reserved.
 *
 * Licensees are granted free, non-transferable use of the information. NO
 * WARRANTY of ANY KIND is provided. This heading must NOT be removed from
 * the file.
 *
 */
#ifndef CONFIG_H__
#define CONFIG_H__

#define	STDOUT				11		// Output pin, connect to the DI of the LED strip

#define NUM_LEDS			12		// Total number of LEDs on the strip
#define MAX_BRIGHTNESS		255		// Maximum value of a single color (255 for WS2812B/WS2813)
#define MAX_TOTAL_CURRENT	800 	// Maximum total current (mA) cunsumption allowed for all LEDs
#define DEMO_PERIOD 		10000	// How long each complete rainbow demo last
#define CYCLE_TIME 			20		// Period between each color update

#endif
