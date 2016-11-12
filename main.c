/* Copyright (c) 2016 ioStation Ltd. All Rights Reserved.
 *
 * Licensees are granted free, non-transferable use of the information. NO
 * WARRANTY of ANY KIND is provided. This heading must NOT be removed from
 * the file.
 *
 */


#include <stdio.h>
#include <string.h>
#include "SEGGER_RTT.h"
#include "SEGGER_RTT_Conf.h"
#include "nordic_common.h"
#include "nrf.h"
#include "nrf_drv_i2s.h"
#include "nrf_drv_uart.h"
#include "nrf_delay.h"
#include "app_util_platform.h"
#include "app_error.h"
#include "boards.h"
#include "app_uart.h"
#include "boards.h"
#include "app_timer.h"
#include "app_button.h"
#include "bsp.h"

#include "config.h"
#include "ws2812b_drive.h"
#include "i2s_ws2812b_drive.h"
#include "rainbow.h"

// For LED indicators
#define GOODLED     BSP_LED_0_MASK
#define BLANKLED	BSP_LED_1_MASK
#define BADLED      BSP_LED_2_MASK

void app_error_fault_handler(uint32_t id, uint32_t pc, uint32_t info)
{
    #ifdef DEBUG
    app_error_print(id, pc, info);
    #endif

    LEDS_ON(LEDS_MASK);
    while(1);
}

int main(void)
{
	LEDS_CONFIGURE(GOODLED | BLANKLED | BADLED);
	LEDS_OFF(GOODLED | BLANKLED| BADLED);
	SEGGER_RTT_WriteString(0, "WS2812b Demo\n");

	while (1)	// repeat forever
    {
		rgb_led_t led_array[NUM_LEDS];
		uint32_t current_limit;

		SEGGER_RTT_WriteString(0,"Demo start\n");
		LEDS_INVERT(GOODLED);
		
		rainbow_init(NUM_LEDS);
		
		int32_t time_left = DEMO_PERIOD;
		int32_t step_time = CYCLE_TIME;
		while (time_left > 0 )
		{
			LEDS_INVERT(GOODLED);	// Beat the heart

			// work out the LED colors for each cycle 
			rainbow(led_array);

			// Adjust total current used by LEDs to below the max allowed 
			current_limit = MAX_TOTAL_CURRENT;
			ws2812b_drive_current_cap(led_array, NUM_LEDS, current_limit);

			if (i2s_ws2812b_drive_xfer(led_array, NUM_LEDS, STDOUT) != NRF_SUCCESS) {
				LEDS_ON(BADLED);	// Lit error indicator up
				SEGGER_RTT_WriteString(0,"ERROR: Send to LED failed!\n");
			} else {
				LEDS_OFF(BADLED); 	// Reset bad status indicator
			}

			nrf_delay_ms(CYCLE_TIME);

			time_left -= step_time;
		}

		rainbow_uninit();
		
		// Turn off LEDs
		ws2812b_drive_set_blank(led_array,NUM_LEDS);
		i2s_ws2812b_drive_xfer(led_array, NUM_LEDS, STDOUT);
		// Wait 3s before restart the rainbow
		SEGGER_RTT_WriteString(0,"Blank LED and Wait 3s\n");
		LEDS_ON(BLANKLED);
		nrf_delay_ms(3000);
		LEDS_OFF(BLANKLED);
	}
    
}


/** @} */
