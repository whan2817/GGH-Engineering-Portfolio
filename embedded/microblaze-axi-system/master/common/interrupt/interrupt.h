#ifndef SRC_COMMON_INTERRUPT_INTERRUPT_H_
#define SRC_COMMON_INTERRUPT_INTERRUPT_H_

#include <stdint.h>
#include "../../common/types/app_types.h"


#define TIMER_INTR_ID          0


extern volatile uint8_t g_timer_intr_flag;


int Interrupt_Init(void);

void TimerIntrHandler(void *CallbackRef);

uint8_t Interrupt_GetTimerFlag(void);
void Interrupt_ClearTimerFlag(void);


#endif 
