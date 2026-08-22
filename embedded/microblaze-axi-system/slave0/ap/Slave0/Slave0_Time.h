#ifndef SRC_AP_SLAVE0_SLAVE0_TIME_H_
#define SRC_AP_SLAVE0_SLAVE0_TIME_H_

#include <stdint.h>

#define SLAVE0_TIME_MS_PER_SEC       1000u
#define SLAVE0_TIME_SEC_MAX          60u
#define SLAVE0_TIME_MIN_MAX          60u

typedef struct {
    uint8_t minute;
    uint8_t second;
} Slave0Time_t;

void Slave0Time_Init(void);
void Slave0Time_Tick1ms(void);
void Slave0Time_GetTime(uint8_t *minute, uint8_t *second);
Slave0Time_t Slave0Time_GetTimeStruct(void);
void Slave0Time_SetTime(uint8_t minute, uint8_t second);
void Slave0Time_Reset(void);


void Slave0Time_FndTask(void);

#endif 
