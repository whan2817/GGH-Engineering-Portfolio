#include "UART2.h"

#include "xparameters.h"
#include "xil_io.h"


#if defined(XPAR_UART2_S00_AXI_BASEADDR)
    #define UART2_BASEADDR XPAR_UART2_S00_AXI_BASEADDR
#elif defined(XPAR_UART2_0_S00_AXI_BASEADDR)
    #define UART2_BASEADDR XPAR_UART2_0_S00_AXI_BASEADDR
#elif defined(XPAR_UART2_BASEADDR)
    #define UART2_BASEADDR XPAR_UART2_BASEADDR
#else
    #error "UART2 base address macro not found. Check xparameters.h."
#endif


#define UART2_SR_OFFSET        0x00
#define UART2_TDR_OFFSET       0x04
#define UART2_RDR_OFFSET       0x08
#define UART2_CR_OFFSET        0x0C

#define UART2_SR_ADDR          (UART2_BASEADDR + UART2_SR_OFFSET)
#define UART2_TDR_ADDR         (UART2_BASEADDR + UART2_TDR_OFFSET)
#define UART2_RDR_ADDR         (UART2_BASEADDR + UART2_RDR_OFFSET)
#define UART2_CR_ADDR          (UART2_BASEADDR + UART2_CR_OFFSET)


#define UART2_TX_TIMEOUT_LOOP          1000000U
#define UART2_RX_TIMEOUT_LOOP_PER_MS   100000U


void UART2_Init(void)
{
    UART2_DisableRxInterrupt();
    UART2_FlushRx();
}


uint32_t UART2_GetStatus(void)
{
    return Xil_In32(UART2_SR_ADDR);
}


int UART2_IsTxReady(void)
{
    if (UART2_GetStatus() & UART2_TX_READY_MASK) {
        return 1;
    }

    return 0;
}


int UART2_IsRxDataReady(void)
{
    if (UART2_GetStatus() & UART2_RX_FLAG_MASK) {
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
    uint32_t dummy;
    uint32_t guard_count = 0;

    while (UART2_IsRxDataReady()) {
        dummy = Xil_In32(UART2_RDR_ADDR);
        (void)dummy;

        guard_count++;
        if (guard_count > 16U) {
            break;
        }
    }
}


int UART2_SendByte(uint8_t data)
{
    uint32_t timeout_count = UART2_TX_TIMEOUT_LOOP;

    while (timeout_count > 0U) {
        if (UART2_IsTxReady()) {
            Xil_Out32(UART2_TDR_ADDR, (uint32_t)data);
            return APP_OK;
        }

        timeout_count--;
    }

    return APP_TIMEOUT;
}


int UART2_RecvByte(uint8_t *data, uint32_t timeout_ms)
{
    uint32_t timeout_count;
    uint32_t rdr;

    if (data == 0) {
        return APP_INVALID_ARG;
    }

    if (timeout_ms == 0U) {
        if (UART2_IsRxDataReady()) {
            rdr = Xil_In32(UART2_RDR_ADDR);
            *data = (uint8_t)(rdr & 0xFF);
            return APP_OK;
        }

        return APP_TIMEOUT;
    }

    timeout_count = timeout_ms * UART2_RX_TIMEOUT_LOOP_PER_MS;

    while (timeout_count > 0U) {
        if (UART2_IsRxDataReady()) {
            rdr = Xil_In32(UART2_RDR_ADDR);
            *data = (uint8_t)(rdr & 0xFF);
            return APP_OK;
        }

        timeout_count--;
    }

    return APP_TIMEOUT;
}


int UART2_SendBytes(const uint8_t *data, uint8_t len)
{
    uint8_t i;
    int status;

    if (data == 0) {
        return APP_INVALID_ARG;
    }

    if (len == 0U) {
        return APP_INVALID_ARG;
    }

    for (i = 0; i < len; i++) {
        status = UART2_SendByte(data[i]);
        if (status != APP_OK) {
            return status;
        }
    }

    return APP_OK;
}


/* 정해진 길이의 패킷을 바이트 순서대로 수신한다. */
int UART2_RecvBytes(uint8_t *data, uint8_t len, uint32_t timeout_ms)
{
    uint8_t i;
    int status;

    if (data == 0) {
        return APP_INVALID_ARG;
    }

    if (len == 0U) {
        return APP_INVALID_ARG;
    }

    for (i = 0; i < len; i++) {
        status = UART2_RecvByte(&data[i], timeout_ms);
        if (status != APP_OK) {
            return status;
        }
    }

    return APP_OK;
}
