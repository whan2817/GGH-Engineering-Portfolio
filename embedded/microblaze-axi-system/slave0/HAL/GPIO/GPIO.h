#ifndef SRC_HAL_GPIO_GPIO_H_
#define SRC_HAL_GPIO_GPIO_H_

#include <stdint.h>
#include "xparameters.h"

typedef struct {
    volatile uint32_t CR;   
    volatile uint32_t IDR;  
    volatile uint32_t ODR;  
} GPIO_TypeDef;


#if defined(XPAR_GPIO_0_S00_AXI_BASEADDR)
#define GPIOA_BASEADDR XPAR_GPIO_0_S00_AXI_BASEADDR
#define GPIOA ((GPIO_TypeDef *)GPIOA_BASEADDR)
#endif

#if defined(XPAR_GPIO_1_S00_AXI_BASEADDR)
#define GPIOB_BASEADDR XPAR_GPIO_1_S00_AXI_BASEADDR
#define GPIOB ((GPIO_TypeDef *)GPIOB_BASEADDR)
#endif

#if defined(XPAR_GPIO_2_S00_AXI_BASEADDR)
#define GPIOC_BASEADDR XPAR_GPIO_2_S00_AXI_BASEADDR
#define GPIOC ((GPIO_TypeDef *)GPIOC_BASEADDR)
#endif

#if defined(XPAR_GPIO_3_S00_AXI_BASEADDR)
#define GPIOD_BASEADDR XPAR_GPIO_3_S00_AXI_BASEADDR
#define GPIOD ((GPIO_TypeDef *)GPIOD_BASEADDR)
#endif

#if defined(XPAR_GPIO_16_GPIO_BASEADDR)
#define GPIO16_BASEADDR XPAR_GPIO_16_GPIO_BASEADDR
#define GPIO16 ((GPIO_TypeDef *)GPIO16_BASEADDR)
#elif defined(XPAR_GPIO_S00_AXI_BASEADDR)
#define GPIO16_BASEADDR XPAR_GPIO_S00_AXI_BASEADDR
#define GPIO16 ((GPIO_TypeDef *)GPIO16_BASEADDR)
#endif

#if !defined(GPIOA) && !defined(GPIO16)
#error "No supported custom GPIO base address macro was found in xparameters.h"
#endif

#define GPIO_INPUT   0u
#define GPIO_OUTPUT  1u

#define GPIO_PIN_0   0x0001u
#define GPIO_PIN_1   0x0002u
#define GPIO_PIN_2   0x0004u
#define GPIO_PIN_3   0x0008u
#define GPIO_PIN_4   0x0010u
#define GPIO_PIN_5   0x0020u
#define GPIO_PIN_6   0x0040u
#define GPIO_PIN_7   0x0080u
#define GPIO_PIN_8   0x0100u
#define GPIO_PIN_9   0x0200u
#define GPIO_PIN_10  0x0400u
#define GPIO_PIN_11  0x0800u
#define GPIO_PIN_12  0x1000u
#define GPIO_PIN_13  0x2000u
#define GPIO_PIN_14  0x4000u
#define GPIO_PIN_15  0x8000u

#define GPIO_RESET   0u
#define GPIO_SET     1u

void GPIO_SetMode(GPIO_TypeDef *GPIOx, uint32_t mode_mask);
uint32_t GPIO_GetCR(GPIO_TypeDef *GPIOx);
uint32_t GPIO_GetODR(GPIO_TypeDef *GPIOx);
uint32_t GPIO_ReadPort(GPIO_TypeDef *GPIOx);
uint32_t GPIO_ReadPin(GPIO_TypeDef *GPIOx, uint32_t gpio_pin);
void GPIO_WritePort(GPIO_TypeDef *GPIOx, uint32_t data);
void GPIO_WriteMasked(GPIO_TypeDef *GPIOx, uint32_t mask, uint32_t data);
void GPIO_WritePin(GPIO_TypeDef *GPIOx, uint32_t gpio_pin, uint32_t state);

#endif 
