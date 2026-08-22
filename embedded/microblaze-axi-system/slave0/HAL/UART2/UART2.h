#ifndef SRC_HAL_UART2_UART2_H_
#define SRC_HAL_UART2_UART2_H_

#include <stdint.h>


#define UART2_OK                  0
#define UART2_ERROR              -1
#define UART2_TIMEOUT            -2
#define UART2_INVALID_ARG        -3


#define UART2_TX_READY_MASK       0x01u
#define UART2_RX_FLAG_MASK        0x02u


#define UART2_RX_IE_MASK          0x01u


void UART2_Init(void);


uint32_t UART2_GetStatus(void);


int UART2_IsTxReady(void);


int UART2_IsRxDataReady(void);


void UART2_EnableRxInterrupt(void);


void UART2_DisableRxInterrupt(void);


void UART2_FlushRx(void);


int UART2_SendByte(uint8_t data);


int UART2_RecvByte(uint8_t *data, uint32_t timeout_ms);


int UART2_SendBytes(const uint8_t *data, uint8_t len);


int UART2_RecvBytes(uint8_t *data, uint8_t len, uint32_t timeout_ms);

#endif 
