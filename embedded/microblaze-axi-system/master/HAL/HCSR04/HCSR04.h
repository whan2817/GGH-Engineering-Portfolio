#ifndef SRC_HAL_HCSR04_HCSR04_H_
#define SRC_HAL_HCSR04_HCSR04_H_

#include <stdint.h>
#include "../../common/types/app_types.h"


#define HCSR04_START_MASK          0x01
#define HCSR04_DONE_MASK           0x01
#define HCSR04_CLEAR_DONE_MASK     0x04


#define HCSR04_TIMEOUT_MS          100U


void HCSR04_Init(void);

void HCSR04_Start(void);
void HCSR04_ClearDone(void);

uint8_t HCSR04_IsDone(void);
uint16_t HCSR04_GetDistanceCm(void);

int HCSR04_ReadDistance(uint16_t *distance_cm, uint32_t timeout_ms);


#endif 
