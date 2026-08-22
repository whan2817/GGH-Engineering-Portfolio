#include "HCSR04.h"

#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"


#if defined(XPAR_HCSR04_0_S00_AXI_BASEADDR)
    #define HCSR04_BASEADDR XPAR_HCSR04_0_S00_AXI_BASEADDR
#elif defined(XPAR_HCSR04_S00_AXI_BASEADDR)
    #define HCSR04_BASEADDR XPAR_HCSR04_S00_AXI_BASEADDR
#elif defined(XPAR_HCSR04_BASEADDR)
    #define HCSR04_BASEADDR XPAR_HCSR04_BASEADDR
#else
    #error "HCSR04 base address macro not found. Check xparameters.h."
#endif


#define HCSR04_CTRL_OFFSET          0x00
#define HCSR04_STATUS_OFFSET        0x04
#define HCSR04_DISTANCE_OFFSET      0x08

#define HCSR04_CTRL_ADDR            (HCSR04_BASEADDR + HCSR04_CTRL_OFFSET)
#define HCSR04_STATUS_ADDR          (HCSR04_BASEADDR + HCSR04_STATUS_OFFSET)
#define HCSR04_DISTANCE_ADDR        (HCSR04_BASEADDR + HCSR04_DISTANCE_OFFSET)


void HCSR04_Init(void)
{
    Xil_Out32(HCSR04_CTRL_ADDR, 0x00);
    HCSR04_ClearDone();
}


void HCSR04_Start(void)
{
    HCSR04_ClearDone();

    Xil_Out32(HCSR04_CTRL_ADDR, HCSR04_START_MASK);
    usleep(1);
    Xil_Out32(HCSR04_CTRL_ADDR, 0x00);
}


void HCSR04_ClearDone(void)
{
    Xil_Out32(HCSR04_CTRL_ADDR, HCSR04_CLEAR_DONE_MASK);
    usleep(1);
    Xil_Out32(HCSR04_CTRL_ADDR, 0x00);
}


uint8_t HCSR04_IsDone(void)
{
    uint32_t status;

    status = Xil_In32(HCSR04_STATUS_ADDR);

    if (status & HCSR04_DONE_MASK) {
        return 1;
    }

    return 0;
}


uint16_t HCSR04_GetDistanceCm(void)
{
    return (uint16_t)(Xil_In32(HCSR04_DISTANCE_ADDR) & 0xFFFF);
}


int HCSR04_ReadDistance(uint16_t *distance_cm, uint32_t timeout_ms)
{
    uint32_t elapsed_ms;

    if (distance_cm == 0) {
        return APP_INVALID_ARG;
    }

    HCSR04_Start();

    elapsed_ms = 0;

    while (elapsed_ms < timeout_ms) {
        if (HCSR04_IsDone()) {
            *distance_cm = HCSR04_GetDistanceCm();
            HCSR04_ClearDone();
            return APP_OK;
        }

        usleep(1000);
        elapsed_ms++;
    }

    return APP_TIMEOUT;
}
