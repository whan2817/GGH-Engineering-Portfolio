#include "interrupt.h"
#include "../delay/delay.h"
#include "../../HAL/UART/UART.h"

#if SLAVE0_HAS_INTC
#include "xintc.h"
#include "xil_exception.h"
#include "xstatus.h"

static XIntc IntrController;
#endif

void TMR_ISR(void *CallbackRef)
{
    (void)CallbackRef;
    incTick();
}

void UART_ISR(void *CallbackRef)
{
    (void)CallbackRef;
    UART_RxIrqHandler(UART2);
}

int SetupInterruptSystem(void)
{
#if SLAVE0_HAS_INTC
    int status;

    status = XIntc_Initialize(&IntrController, INTC_DEV_ID);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

#if SLAVE0_HAS_TMR_IRQ
    status = XIntc_Connect(&IntrController,
                           TMR_VEC_ID,
                           (XInterruptHandler)TMR_ISR,
                           (void *)0);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
#endif

#if SLAVE0_HAS_UART_IRQ
    status = XIntc_Connect(&IntrController,
                           UART_VEC_ID,
                           (XInterruptHandler)UART_ISR,
                           (void *)0);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
#endif

    status = XIntc_Start(&IntrController, XIN_REAL_MODE);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

#if SLAVE0_HAS_TMR_IRQ
    XIntc_Enable(&IntrController, TMR_VEC_ID);
#endif

#if SLAVE0_HAS_UART_IRQ
    XIntc_Enable(&IntrController, UART_VEC_ID);
#endif

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                 (Xil_ExceptionHandler)XIntc_InterruptHandler,
                                 &IntrController);
    Xil_ExceptionEnable();

    return XST_SUCCESS;
#else
    return 0;
#endif
}
