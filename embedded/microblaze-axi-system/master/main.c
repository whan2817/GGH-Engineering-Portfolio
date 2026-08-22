#include "platform.h"

#include "xil_printf.h"
#include "sleep.h"

#include "ap/MasterApp.h"
#include "common/interrupt/interrupt.h"
#include "common/types/app_types.h"


int main(void)
{
    int status;

    init_platform();

    xil_printf("\r\n");
    xil_printf("========================================\r\n");
    xil_printf(" Master Board Start\r\n");
    xil_printf("========================================\r\n");

    


    status = Interrupt_Init();
    if (status != APP_OK) {
        xil_printf("[MAIN] Interrupt_Init failed. status=%d\r\n", status);
        xil_printf("[MAIN] System halted.\r\n");

        while (1) {
            


        }
    }

    


    MasterApp_Init();

    xil_printf("[MAIN] Master main loop started.\r\n");

    while (1) {
        MasterApp_Update();

        


        usleep(10000);
    }

    cleanup_platform();

    return 0;
}
