#include "UART.h"

static volatile uint8_t  g_uart_rx_buf[UART_RX_BUFFER_SIZE];
static volatile uint32_t g_uart_rx_head = 0;
static volatile uint32_t g_uart_rx_tail = 0;
static volatile uint32_t g_uart_rx_overrun = 0;

static uint32_t next_index(uint32_t index)
{
    return (index + 1u) % UART_RX_BUFFER_SIZE;
}

void UART_StartInterrupt(UART_TypeDef_t *uart)
{
    uart->CR |= UART_CR_RX_IE;
}

void UART_StopInterrupt(UART_TypeDef_t *uart)
{
    uart->CR &= ~UART_CR_RX_IE;
}

uint8_t UART_TxReady(UART_TypeDef_t *uart)
{
    return (uart->SR & UART_SR_TX_READY) ? 1u : 0u;
}

uint8_t UART_RxAvailableHw(UART_TypeDef_t *uart)
{
    return (uart->SR & UART_SR_RX_FLAG) ? 1u : 0u;
}

void UART_Transmit(UART_TypeDef_t *uart, uint8_t data)
{
    while (!UART_TxReady(uart)) {
        ;
    }
    uart->TDR = (uint32_t)data;
}

void UART_SendBuffer(UART_TypeDef_t *uart, const uint8_t *data, uint32_t len)
{
    uint32_t i;

    if (data == 0) {
        return;
    }

    for (i = 0; i < len; i++) {
        UART_Transmit(uart, data[i]);
    }
}

uint8_t UART_Receive(UART_TypeDef_t *uart)
{
    uint8_t data;

    while (!UART_ReadByte(uart, &data)) {
        ;
    }
    return data;
}

uint8_t UART_RxAvalable(UART_TypeDef_t *uart)
{
    if (g_uart_rx_head != g_uart_rx_tail) {
        return 1u;
    }
    return UART_RxAvailableHw(uart);
}

int UART_ReadByte(UART_TypeDef_t *uart, uint8_t *data)
{
    if (data == 0) {
        return 0;
    }

    if (g_uart_rx_head != g_uart_rx_tail) {
        *data = g_uart_rx_buf[g_uart_rx_tail];
        g_uart_rx_tail = next_index(g_uart_rx_tail);
        return 1;
    }

    
    if (UART_RxAvailableHw(uart)) {
        *data = (uint8_t)uart->RDR;
        return 1;
    }

    return 0;
}

void UART_RxIrqHandler(UART_TypeDef_t *uart)
{
    uint8_t data;
    uint32_t next;

    if (!UART_RxAvailableHw(uart)) {
        return;
    }

    
    data = (uint8_t)uart->RDR;
    next = next_index(g_uart_rx_head);

    if (next == g_uart_rx_tail) {
        g_uart_rx_overrun++;
        return;
    }

    g_uart_rx_buf[g_uart_rx_head] = data;
    g_uart_rx_head = next;
}

void UART_RxBufferClear(void)
{
    g_uart_rx_head = 0;
    g_uart_rx_tail = 0;
    g_uart_rx_overrun = 0;
}

uint32_t UART_RxOverrunCount(void)
{
    return g_uart_rx_overrun;
}
