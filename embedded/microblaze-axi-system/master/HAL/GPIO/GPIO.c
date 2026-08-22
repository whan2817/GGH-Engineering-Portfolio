#include "GPIO.h"

#include "xil_io.h"


#define GPIO_CR_OFFSET        0x00
#define GPIO_IDR_OFFSET       0x04
#define GPIO_ODR_OFFSET       0x08

#define GPIO_CR_ADDR(base)    ((base) + GPIO_CR_OFFSET)
#define GPIO_IDR_ADDR(base)   ((base) + GPIO_IDR_OFFSET)
#define GPIO_ODR_ADDR(base)   ((base) + GPIO_ODR_OFFSET)


void GPIO_SetMode(uint32_t base_addr, uint8_t mode)
{
    Xil_Out32(GPIO_CR_ADDR(base_addr), (uint32_t)(mode & GPIO_PORT_MASK));
}


uint8_t GPIO_ReadInputPort(uint32_t base_addr)
{
    return (uint8_t)(Xil_In32(GPIO_IDR_ADDR(base_addr)) & GPIO_PORT_MASK);
}


uint8_t GPIO_ReadOutputPort(uint32_t base_addr)
{
    return (uint8_t)(Xil_In32(GPIO_ODR_ADDR(base_addr)) & GPIO_PORT_MASK);
}


void GPIO_WriteOutputPort(uint32_t base_addr, uint8_t data)
{
    Xil_Out32(GPIO_ODR_ADDR(base_addr), (uint32_t)(data & GPIO_PORT_MASK));
}


uint8_t GPIO_ReadPin(uint32_t base_addr, uint8_t pin)
{
    uint8_t port_data;

    if (pin > GPIO_PIN_MAX) {
        return 0;
    }

    port_data = GPIO_ReadInputPort(base_addr);

    if (port_data & (uint8_t)(1U << pin)) {
        return 1;
    }

    return 0;
}


void GPIO_WritePin(uint32_t base_addr, uint8_t pin, uint8_t value)
{
    uint8_t port_data;

    if (pin > GPIO_PIN_MAX) {
        return;
    }

    port_data = GPIO_ReadOutputPort(base_addr);

    if (value) {
        port_data |= (uint8_t)(1U << pin);
    } else {
        port_data &= (uint8_t)(~(1U << pin));
    }

    GPIO_WriteOutputPort(base_addr, port_data);
}
