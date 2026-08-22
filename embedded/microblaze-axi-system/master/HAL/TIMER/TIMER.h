#ifndef SRC_HAL_TIMER_TIMER_H_
#define SRC_HAL_TIMER_TIMER_H_

#include <stdint.h>
#include "../../common/types/app_types.h"


#define TIMER_CNT_EN_MASK       0x01
#define TIMER_INTR_EN_MASK      0x02


#define TIMER_1MS_PSC           99999U
#define TIMER_2SEC_ARR          1999U


void TIMER_Init(void);

void TIMER_SetPrescaler(uint32_t psc);
void TIMER_SetAutoReload(uint32_t arr);
void TIMER_SetCounter(uint32_t cnt);

uint32_t TIMER_GetCounter(void);

void TIMER_Start(void);
void TIMER_Stop(void);

void TIMER_EnableInterrupt(void);
void TIMER_DisableInterrupt(void);

void TIMER_SetPeriod2Sec(void);
void TIMER_Start2SecInterrupt(void);
void TIMER_Restart2SecInterrupt(void);


#endif 
