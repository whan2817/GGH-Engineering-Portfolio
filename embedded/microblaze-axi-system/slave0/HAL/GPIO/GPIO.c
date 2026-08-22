#include "GPIO.h"

void GPIO_SetMode(GPIO_TypeDef *GPIOx, uint32_t mode_mask)
{
    GPIOx->CR = mode_mask;
}

uint32_t GPIO_GetCR(GPIO_TypeDef *GPIOx)
{
    return GPIOx->CR;
}

uint32_t GPIO_GetODR(GPIO_TypeDef *GPIOx)
{
    return GPIOx->ODR;
}

uint32_t GPIO_ReadPort(GPIO_TypeDef *GPIOx)
{
    return GPIOx->IDR;
}

uint32_t GPIO_ReadPin(GPIO_TypeDef *GPIOx, uint32_t gpio_pin)
{
    return (GPIOx->IDR & gpio_pin) ? 1u : 0u;
}

void GPIO_WritePort(GPIO_TypeDef *GPIOx, uint32_t data)
{
    GPIOx->ODR = data;
}

void GPIO_WriteMasked(GPIO_TypeDef *GPIOx, uint32_t mask, uint32_t data)
{
    uint32_t odr;

    odr = GPIOx->ODR;
    odr &= ~mask;
    odr |= (data & mask);
    GPIOx->ODR = odr;
}

void GPIO_WritePin(GPIO_TypeDef *GPIOx, uint32_t gpio_pin, uint32_t state)
{
    if (state == GPIO_SET) {
        GPIOx->ODR |= gpio_pin;
    } else {
        GPIOx->ODR &= ~gpio_pin;
    }
}
