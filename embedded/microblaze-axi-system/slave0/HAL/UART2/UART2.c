#include "UART2.h"

#include "xparameters.h"
#include "xil_io.h"


#if defined(XPAR_UART2_S00_AXI_BASEADDR)
    #define UART2_BASEADDR XPAR_UART2_S00_AXI_BASEADDR
#elif defined(XPAR_UART2_0_S00_AXI_BASEADDR)
    #define UART2_BASEADDR XPAR_UART2_0_S00_AXI_BASEADDR
#elif defined(XPAR_UART_0_S00_AXI_BASEADDR)
    #define UART2_BASEADDR XPAR_UART_0_S00_AXI_BASEADDR
#elif defined(XPAR_UART_S00_AXI_BASEADDR)
    #define UART2_BASEADDR XPAR_UART_S00_AXI_BASEADDR
#elif defined(XPAR_UART2_BASEADDR)
    #define UART2_BASEADDR XPAR_UART2_BASEADDR
#else
    #error "UART2 base address macro not found. Check xparameters.h."
#endif


#define UART2_STATUS_OFFSET        0x00u
#define UART2_TDR_OFFSET           0x04u
#define UART2_RDR_OFFSET           0x08u
#define UART2_CR_OFFSET            0x0Cu

#define UART2_STATUS_ADDR          (UART2_BASEADDR + UART2_STATUS_OFFSET)
#define UART2_TDR_ADDR             (UART2_BASEADDR + UART2_TDR_OFFSET)
#define UART2_RDR_ADDR             (UART2_BASEADDR + UART2_RDR_OFFSET)
#define UART2_CR_ADDR              (UART2_BASEADDR + UART2_CR_OFFSET)


#define UART2_TX_TIMEOUT_LOOP          1000000u
#define UART2_RX_TIMEOUT_LOOP_PER_MS   100000u


void UART2_Init(void)
{
    UART2_DisableRxInterrupt();
    UART2_FlushRx();
}


uint32_t UART2_GetStatus(void)
{
    return Xil_In32(UART2_STATUS_ADDR);
}


int UART2_IsTxReady(void)
{
    uint32_t status;

    status = UART2_GetStatus();

    if ((status & UART2_TX_READY_MASK) != 0u) {
        return 1;
    }

    return 0;
}


int UART2_IsRxDataReady(void)
{
    uint32_t status;

    status = UART2_GetStatus();

    if ((status & UART2_RX_FLAG_MASK) != 0u) {
        return 1;
    }

    return 0;
}


void UART2_EnableRxInterrupt(void)
{
    uint32_t cr;

    cr = Xil_In32(UART2_CR_ADDR);
    cr |= UART2_RX_IE_MASK;

    Xil_Out32(UART2_CR_ADDR, cr);
}


void UART2_DisableRxInterrupt(void)
{
    uint32_t cr;

    cr = Xil_In32(UART2_CR_ADDR);
    cr &= ~UART2_RX_IE_MASK;

    Xil_Out32(UART2_CR_ADDR, cr);
}


void UART2_FlushRx(void)
{
    uint32_t guard_count;
    volatile uint32_t dummy;

    guard_count = 0u;

    while ((UART2_IsRxDataReady() != 0) && (guard_count < 64u)) {
        dummy = Xil_In32(UART2_RDR_ADDR);
        guard_count++;
    }

    (void)dummy;
}


int UART2_SendByte(uint8_t data)
{
    uint32_t timeout_count;

    timeout_count = 0u;

    while (UART2_IsTxReady() == 0) {
        timeout_count++;

        if (timeout_count >= UART2_TX_TIMEOUT_LOOP) {
            return UART2_TIMEOUT;
        }
    }

    Xil_Out32(UART2_TDR_ADDR, (uint32_t)data);

    return UART2_OK;
}


int UART2_RecvByte(uint8_t *data, uint32_t timeout_ms)
{
    uint32_t timeout_count;
    uint32_t timeout_limit;

    if (data == 0) {
        return UART2_INVALID_ARG;
    }

    


    if (timeout_ms == 0u) {
        if (UART2_IsRxDataReady() != 0) {
            *data = (uint8_t)(Xil_In32(UART2_RDR_ADDR) & 0xFFu);
            return UART2_OK;
        }

        return UART2_TIMEOUT;
    }

    timeout_limit = timeout_ms * UART2_RX_TIMEOUT_LOOP_PER_MS;
    timeout_count = 0u;

    while (timeout_count < timeout_limit) {
        if (UART2_IsRxDataReady() != 0) {
            *data = (uint8_t)(Xil_In32(UART2_RDR_ADDR) & 0xFFu);
            return UART2_OK;
        }

        timeout_count++;
    }

    return UART2_TIMEOUT;
}


int UART2_SendBytes(const uint8_t *data, uint8_t len)
{
    uint8_t i;
    int status;

    if ((data == 0) || (len == 0u)) {
        return UART2_INVALID_ARG;
    }

    for (i = 0u; i < len; i++) {
        status = UART2_SendByte(data[i]);

        if (status != UART2_OK) {
            return status;
        }
    }

    return UART2_OK;
}


/* 정해진 길이의 패킷을 바이트 순서대로 수신한다. */
int UART2_RecvBytes(uint8_t *data, uint8_t len, uint32_t timeout_ms)
{
    uint8_t i;
    int status;

    if ((data == 0) || (len == 0u)) {
        return UART2_INVALID_ARG;
    }

    for (i = 0u; i < len; i++) {
        status = UART2_RecvByte(&data[i], timeout_ms);

        if (status != UART2_OK) {
            return status;
        }
    }

    return UART2_OK;
}
