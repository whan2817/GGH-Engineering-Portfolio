#ifndef SRC_HAL_I2C_I2C_H_
#define SRC_HAL_I2C_I2C_H_

#include <stdint.h>
#include "xparameters.h"


typedef struct {
    volatile uint32_t CR;    
    volatile uint32_t TX;    
    volatile uint32_t RX;    
    volatile uint32_t SR;    
} I2C_TypeDef_t;

#define I2C_CR_WRITE          (1u << 0)
#define I2C_CR_READ           (1u << 1)
#define I2C_SR_TX_DONE        (1u << 0)
#define I2C_SR_RX_DONE        (1u << 1)

#if defined(XPAR_I2C_S00_AXI_BASEADDR)
#define I2C0_BASEADDR XPAR_I2C_S00_AXI_BASEADDR
#elif defined(XPAR_I2C_0_S00_AXI_BASEADDR)
#define I2C0_BASEADDR XPAR_I2C_0_S00_AXI_BASEADDR
#else
#error "I2C base address macro was not found in xparameters.h"
#endif

#define I2C0 ((I2C_TypeDef_t *)I2C0_BASEADDR)

#ifndef I2C_WRITE_DELAY_US
#define I2C_WRITE_DELAY_US 2000u
#endif

void I2C_Write4BytesPacked(I2C_TypeDef_t *i2c, uint8_t slave_addr_7bit, uint16_t packed_data);
uint32_t I2C_ReadStatus(I2C_TypeDef_t *i2c);
uint8_t I2C_ReadData(I2C_TypeDef_t *i2c);

#endif 
