#ifndef SRC_HAL_UART_UART_H_
#define SRC_HAL_UART_UART_H_

#include <stdint.h>
#include "xparameters.h"

#define UART_SR_TX_READY   (1u << 0)
#define UART_SR_RX_FLAG    (1u << 1)
#define UART_CR_RX_IE      (1u << 0)

#ifndef UART_RX_BUFFER_SIZE
#define UART_RX_BUFFER_SIZE 64u
#endif

typedef struct {
    volatile uint32_t SR;   
    volatile uint32_t TDR;  
    volatile uint32_t RDR;  
    volatile uint32_t CR;   
} UART_TypeDef_t;


#if defined(XPAR_UART2_S00_AXI_BASEADDR)
#define UART2_BASEADDR XPAR_UART2_S00_AXI_BASEADDR
#elif defined(XPAR_UART_0_S00_AXI_BASEADDR)
#define UART2_BASEADDR XPAR_UART_0_S00_AXI_BASEADDR
#elif defined(XPAR_UART_S00_AXI_BASEADDR)
#define UART2_BASEADDR XPAR_UART_S00_AXI_BASEADDR
#else
#error "UART2 base address macro was not found in xparameters.h"
#endif

#define UART2 ((UART_TypeDef_t *)UART2_BASEADDR)
#define UART0 UART2   

void UART_StartInterrupt(UART_TypeDef_t *uart);
void UART_StopInterrupt(UART_TypeDef_t *uart);

uint8_t UART_TxReady(UART_TypeDef_t *uart);
uint8_t UART_RxAvailableHw(UART_TypeDef_t *uart);

void UART_Transmit(UART_TypeDef_t *uart, uint8_t data);
uint8_t UART_Receive(UART_TypeDef_t *uart);
uint8_t UART_RxAvalable(UART_TypeDef_t *uart); 

void UART_SendBuffer(UART_TypeDef_t *uart, const uint8_t *data, uint32_t len);
int  UART_ReadByte(UART_TypeDef_t *uart, uint8_t *data);
void UART_RxIrqHandler(UART_TypeDef_t *uart);
void UART_RxBufferClear(void);
uint32_t UART_RxOverrunCount(void);

#endif 
