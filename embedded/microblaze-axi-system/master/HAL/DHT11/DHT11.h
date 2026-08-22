#ifndef SRC_HAL_DHT11_DHT11_H_
#define SRC_HAL_DHT11_DHT11_H_

#include <stdint.h>
#include "../../common/types/app_types.h"


#define DHT11_START_MASK       0x01
#define DHT11_VALID_MASK       0x01


#define DHT11_TIMEOUT_MS       2000U


void DHT11_Init(void);

void DHT11_Start(void);

uint8_t DHT11_IsValid(void);

uint8_t DHT11_GetTemperature(void);
uint8_t DHT11_GetHumidity(void);

int DHT11_ReadData(uint8_t *temperature,
                   uint8_t *humidity,
                   uint32_t timeout_ms);


#endif 
