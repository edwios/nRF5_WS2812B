/* Copyright (c) 2016 ioStation Ltd. All Rights Reserved.
 *
 * Licensees are granted free, non-transferable use of the information. NO
 * WARRANTY of ANY KIND is provided. This heading must NOT be removed from
 * the file.
 *
 */

#ifndef RAINBOW_H__
#define RAINBOW_H__

#include "stdlib.h"

#include "config.h"
#include "ws2812b_drive.h"

void rainbow_init(uint16_t);
void rainbow_uninit(void);
void rainbow(rgb_led_t * led_array);

#endif // RAINBOW_H__
