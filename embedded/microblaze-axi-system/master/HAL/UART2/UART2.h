#ifndef SRC_HAL_UART2_UART2_H_
#define SRC_HAL_UART2_UART2_H_

#include <stdint.h>
#include "../../common/types/app_types.h"


#define UART2_TX_READY_MASK     0x01
#define UART2_RX_FLAG_MASK      0x02


#define UART2_RX_IE_MASK        0x01


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
