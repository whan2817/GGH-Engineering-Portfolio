#include "I2C.h"
#include "../../common/delay/delay.h"

uint32_t I2C_ReadStatus(I2C_TypeDef_t *i2c)
{
    return i2c->SR;
}

uint8_t I2C_ReadData(I2C_TypeDef_t *i2c)
{
    return (uint8_t)(i2c->RX & 0xFFu);
}

void I2C_Write4BytesPacked(I2C_TypeDef_t *i2c, uint8_t slave_addr_7bit, uint16_t packed_data)
{
    uint32_t reg_data;

    
    reg_data = (((uint32_t)slave_addr_7bit & 0x7Fu) << 16) |
               ((uint32_t)packed_data & 0xFFFFu);

    i2c->TX = reg_data;

    
    i2c->CR = I2C_CR_WRITE;

    


    delay_us(I2C_WRITE_DELAY_US);
}
