#ifndef SRC_DRIVER_BUTTON_BUTTON_H_
#define SRC_DRIVER_BUTTON_BUTTON_H_

#include <stdint.h>
#include "../../common/types/app_types.h"


#define BUTTON_MANUAL_PIN          1
#define BUTTON_AUTO_PIN            2
#define BUTTON_LOG_PIN             3


#define BUTTON_EVENT_NONE          0x00
#define BUTTON_EVENT_MANUAL        0x01
#define BUTTON_EVENT_AUTO          0x02
#define BUTTON_EVENT_LOG           0x04


#define BUTTON_ACTIVE_LEVEL        1


void Button_Init(void);

void Button_Update(void);

uint8_t Button_GetEvent(void);
void Button_ClearEvent(uint8_t event_mask);

uint8_t Button_IsManualPressed(void);
uint8_t Button_IsAutoPressed(void);
uint8_t Button_IsLogPressed(void);


#endif 
