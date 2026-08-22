#ifndef SRC_COMMON_DELAY_DELAY_H_
#define SRC_COMMON_DELAY_DELAY_H_

#include <stdint.h>
#include "sleep.h"

uint32_t millis(void);
void incTick(void);
void delay_sec(uint32_t seconds);
void delay_ms(uint32_t msec);
void delay_us(uint32_t usec);

#endif 
