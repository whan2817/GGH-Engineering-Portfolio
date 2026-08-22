#ifndef SRC_DRIVER_FND_FND_H_
#define SRC_DRIVER_FND_FND_H_

#include <stdint.h>
#include "../../HAL/GPIO/GPIO.h"


#if defined(GPIOB)
#define FND_GPIO GPIOB
#elif defined(GPIO16)
#define FND_GPIO GPIO16
#else
#error "FND requires GPIOB or GPIO16 base macro. Check xparameters.h."
#endif

#define FND_DATA_SHIFT   8u
#define FND_DIGIT_SHIFT  4u
#define FND_DATA_MASK    (0x00FFu << FND_DATA_SHIFT)    
#define FND_DIGIT_MASK   (0x000Fu << FND_DIGIT_SHIFT)   
#define FND_OUTPUT_MASK  (FND_DATA_MASK | FND_DIGIT_MASK)

#define FND_DIGIT_0 0u
#define FND_DIGIT_1 1u
#define FND_DIGIT_2 2u
#define FND_DIGIT_3 3u

#define FND_DP_ON   1u
#define FND_DP_OFF  0u

void FND_Init(void);
void FND_SetNum(uint32_t num);
void FND_SetTime(uint8_t minute, uint8_t second);
void FND_SetDP(uint32_t fndDigitSel, uint32_t fndDpState);
void FND_Execute(void);
void FND_Excute(void);      
void FND_DispAllOff(void);

#endif 
