#ifndef SRC_HAL_GPIO_GPIO_H_
#define SRC_HAL_GPIO_GPIO_H_

#include <stdint.h>
#include "../../common/types/app_types.h"


#define GPIO_MODE_INPUT       0
#define GPIO_MODE_OUTPUT      1


#define GPIO_PIN_MAX          7
#define GPIO_PORT_MASK        0xFF


void GPIO_SetMode(uint32_t base_addr, uint8_t mode);

uint8_t GPIO_ReadInputPort(uint32_t base_addr);
uint8_t GPIO_ReadOutputPort(uint32_t base_addr);

void GPIO_WriteOutputPort(uint32_t base_addr, uint8_t data);

uint8_t GPIO_ReadPin(uint32_t base_addr, uint8_t pin);
void GPIO_WritePin(uint32_t base_addr, uint8_t pin, uint8_t value);


#endif 
