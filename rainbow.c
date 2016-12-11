/* Copyright (c) 2016 ioStation Ltd. All Rights Reserved.
 *
 * Licensees are granted free, non-transferable use of the information. NO
 * WARRANTY of ANY KIND is provided. This heading must NOT be removed from
 * the file.
 *
 */

#include	"rainbow.h"
#include "SEGGER_RTT.h"
#include "SEGGER_RTT_Conf.h"

static rgb_led_t *led_array_base;				// array for base color
static rgb_led_t *led_array_work; 				// array for flash left-up to right-down

const static rgb_led_t color_list[] = {
	{0           , MAX_BRIGHTNESS, 0           }, // Red
	{MAX_BRIGHTNESS, MAX_BRIGHTNESS, 0           }, // Yellow
	{MAX_BRIGHTNESS, 0           , 0           }, // Green
	{MAX_BRIGHTNESS, 0           , MAX_BRIGHTNESS}, // rght green
	{0           , 0           , MAX_BRIGHTNESS}, // Blue
	{0           , MAX_BRIGHTNESS, MAX_BRIGHTNESS}, // Purple
	{0           , MAX_BRIGHTNESS, 0           }, // Red
};

const static uint8_t n_color_list = sizeof(color_list)/sizeof(color_list[0]);

void rainbow_init(uint16_t num_leds)
{
	/* Initialize the LED colors based upon the color list
	 * Originated from running_rainbow.c (c) Takafumi Naka, 2016
	 */
	uint32_t iregion;
	float ratio;

	// allocate buffers
	led_array_base		= malloc(num_leds * sizeof(rgb_led_t));
	led_array_work		= malloc(num_leds * sizeof(rgb_led_t));

	// initialize led_array (base color array)
	for(uint16_t i=0;i<NUM_LEDS;i++)
	{

		iregion = (n_color_list-1)*i/NUM_LEDS;
		ratio = (i - iregion*(float)NUM_LEDS/(n_color_list-1))/((float)NUM_LEDS/(n_color_list-1));
		led_array_base[i].green = color_list[iregion].green*(1-ratio) + color_list[iregion+1].green * ratio;
		led_array_base[i].red   = color_list[iregion].red*(1-ratio)   + color_list[iregion+1].red   * ratio;
		led_array_base[i].blue  = color_list[iregion].blue*(1-ratio)  + color_list[iregion+1].blue  * ratio;
	}
}

void rainbow_uninit()
{
		free(led_array_base);
		free(led_array_work);
}

void rainbow(rgb_led_t * led_array_out)
{	
	// update led_array_base
	{
		for(uint16_t i=0;i<NUM_LEDS;i++)
		{
			led_array_work[i] = led_array_base[i];
		}
	}
	// Update led color
	{
		uint16_t i;
		rgb_led_t tmp;

		for( i=0;i<NUM_LEDS-1;i++)
		{
			if (i==0) {
				tmp=led_array_work[i];
			}
			led_array_work[i]=led_array_work[i+1];				
		}	
		led_array_work[i] = tmp;	
	}
	// Update output array
	{
		for(uint16_t i=0;i<NUM_LEDS;i++)
		{
			led_array_out[i] = led_array_work[i];
			// Also update the base color table
			led_array_base[i]=led_array_work[i];
		}	
	}
}

void setcolor(rgb_led_t * led_array_out, uint32_t rgbcolor)
{

	uint8_t rgbc8[4];

	rgbc8[0] = (uint8_t)(rgbcolor & 0x000000FF);
	rgbc8[1] = (uint8_t)((rgbcolor & 0x0000FF00)>>8);
	rgbc8[2] = (uint8_t)((rgbcolor & 0x00FF0000)>>16);
	rgbc8[3] = (uint8_t)((rgbcolor & 0xFF000000)>>24);

/*
    char sv[128];
    sprintf(sv, "setcolor: RGB LED r:%0hx g:%0hx b:%0hx\n", rgbc8[1], rgbc8[2], rgbc8[3]);
    SEGGER_RTT_WriteString(0, sv);
*/

	// update led_array_base
	{
		for(uint16_t i=0;i<NUM_LEDS;i++)
		{
			led_array_work[i].blue  = rgbc8[3];
			led_array_work[i].green = rgbc8[2];
			led_array_work[i].red   = rgbc8[1];
		}
	}
	// Update output array
	{
		for(uint16_t i=0;i<NUM_LEDS;i++)
		{
			led_array_out[i] = led_array_work[i];
		}	
	}


}