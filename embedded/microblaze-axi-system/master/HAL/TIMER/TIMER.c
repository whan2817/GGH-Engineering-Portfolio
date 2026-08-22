#include "TIMER.h"

#include "xparameters.h"
#include "xil_io.h"


#if defined(XPAR_TIMER_0_S00_AXI_BASEADDR)
    #define TIMER_BASEADDR XPAR_TIMER_0_S00_AXI_BASEADDR
#elif defined(XPAR_TIMER_S00_AXI_BASEADDR)
    #define TIMER_BASEADDR XPAR_TIMER_S00_AXI_BASEADDR
#elif defined(XPAR_TIMER_BASEADDR)
    #define TIMER_BASEADDR XPAR_TIMER_BASEADDR
#else
    #error "Timer base address macro not found. Check xparameters.h."
#endif


#define TIMER_CR_OFFSET        0x00
#define TIMER_PSC_OFFSET       0x04
#define TIMER_ARR_OFFSET       0x08
#define TIMER_CNT_OFFSET       0x0C

#define TIMER_CR_ADDR          (TIMER_BASEADDR + TIMER_CR_OFFSET)
#define TIMER_PSC_ADDR         (TIMER_BASEADDR + TIMER_PSC_OFFSET)
#define TIMER_ARR_ADDR         (TIMER_BASEADDR + TIMER_ARR_OFFSET)
#define TIMER_CNT_ADDR         (TIMER_BASEADDR + TIMER_CNT_OFFSET)


void TIMER_Init(void)
{
    TIMER_Stop();
    TIMER_DisableInterrupt();

    TIMER_SetPeriod2Sec();
    TIMER_SetCounter(0);
}


void TIMER_SetPrescaler(uint32_t psc)
{
    Xil_Out32(TIMER_PSC_ADDR, psc);
}


void TIMER_SetAutoReload(uint32_t arr)
{
    Xil_Out32(TIMER_ARR_ADDR, arr);
}


void TIMER_SetCounter(uint32_t cnt)
{
    Xil_Out32(TIMER_CNT_ADDR, cnt);
}


uint32_t TIMER_GetCounter(void)
{
    return Xil_In32(TIMER_CNT_ADDR);
}


void TIMER_Start(void)
{
    uint32_t cr;

    cr = Xil_In32(TIMER_CR_ADDR);
    cr |= TIMER_CNT_EN_MASK;

    Xil_Out32(TIMER_CR_ADDR, cr);
}


void TIMER_Stop(void)
{
    uint32_t cr;

    cr = Xil_In32(TIMER_CR_ADDR);
    cr &= ~TIMER_CNT_EN_MASK;

    Xil_Out32(TIMER_CR_ADDR, cr);
}


void TIMER_EnableInterrupt(void)
{
    uint32_t cr;

    cr = Xil_In32(TIMER_CR_ADDR);
    cr |= TIMER_INTR_EN_MASK;

    Xil_Out32(TIMER_CR_ADDR, cr);
}


void TIMER_DisableInterrupt(void)
{
    uint32_t cr;

    cr = Xil_In32(TIMER_CR_ADDR);
    cr &= ~TIMER_INTR_EN_MASK;

    Xil_Out32(TIMER_CR_ADDR, cr);
}


void TIMER_SetPeriod2Sec(void)
{
    TIMER_SetPrescaler(TIMER_1MS_PSC);
    TIMER_SetAutoReload(TIMER_2SEC_ARR);
}


void TIMER_Start2SecInterrupt(void)
{
    TIMER_Stop();

    TIMER_SetPeriod2Sec();
    TIMER_SetCounter(0);

    Xil_Out32(TIMER_CR_ADDR, TIMER_CNT_EN_MASK | TIMER_INTR_EN_MASK);
}


void TIMER_Restart2SecInterrupt(void)
{
    TIMER_Start2SecInterrupt();
}
