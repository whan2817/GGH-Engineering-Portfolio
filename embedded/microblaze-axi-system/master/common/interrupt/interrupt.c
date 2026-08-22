#include "interrupt.h"

#include "xparameters.h"
#include "xintc.h"
#include "xil_exception.h"
#include "xil_printf.h"

#include "../../HAL/TIMER/TIMER.h"


#if defined(XPAR_INTC_0_DEVICE_ID)
    #define INTC_DEVICE_ID XPAR_INTC_0_DEVICE_ID
#elif defined(XPAR_AXI_INTC_0_DEVICE_ID)
    #define INTC_DEVICE_ID XPAR_AXI_INTC_0_DEVICE_ID
#elif defined(XPAR_MICROBLAZE_0_AXI_INTC_DEVICE_ID)
    #define INTC_DEVICE_ID XPAR_MICROBLAZE_0_AXI_INTC_DEVICE_ID
#else
    #error "AXI Interrupt Controller device ID macro not found. Check xparameters.h."
#endif


static XIntc g_intc;

volatile uint8_t g_timer_intr_flag = 0;


void TimerIntrHandler(void *CallbackRef)
{
    (void)CallbackRef;

    g_timer_intr_flag = 1;

    


    TIMER_Stop();
    TIMER_DisableInterrupt();
}


int Interrupt_Init(void)
{
    int status;

    g_timer_intr_flag = 0;

    status = XIntc_Initialize(&g_intc, INTC_DEVICE_ID);
    if (status != XST_SUCCESS) {
        xil_printf("[INTC] XIntc_Initialize failed. status=%d\r\n", status);
        return APP_ERROR;
    }

    status = XIntc_Connect(&g_intc,
                           TIMER_INTR_ID,
                           (XInterruptHandler)TimerIntrHandler,
                           0);
    if (status != XST_SUCCESS) {
        xil_printf("[INTC] XIntc_Connect failed. status=%d\r\n", status);
        return APP_ERROR;
    }

    status = XIntc_Start(&g_intc, XIN_REAL_MODE);
    if (status != XST_SUCCESS) {
        xil_printf("[INTC] XIntc_Start failed. status=%d\r\n", status);
        return APP_ERROR;
    }

    XIntc_Enable(&g_intc, TIMER_INTR_ID);

    Xil_ExceptionInit();

    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                 (Xil_ExceptionHandler)XIntc_InterruptHandler,
                                 &g_intc);

    Xil_ExceptionEnable();

    xil_printf("[INTC] Interrupt controller initialized.\r\n");

    return APP_OK;
}


uint8_t Interrupt_GetTimerFlag(void)
{
    return g_timer_intr_flag;
}


void Interrupt_ClearTimerFlag(void)
{
    g_timer_intr_flag = 0;
}
