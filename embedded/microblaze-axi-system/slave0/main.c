#include "platform.h"
#include "xil_printf.h"

#include "common/delay/delay.h"
#include "driver/LCD1602/LCD1602.h"
#include "ap/Slave0/Slave0.h"
#include "ap/Slave0/Slave0_Time.h"

#ifndef SLAVE0_CPU_TICK_SLICE_US
#define SLAVE0_CPU_TICK_SLICE_US 50u
#endif

#define SLAVE0_CPU_SLICES_PER_MS (1000u / SLAVE0_CPU_TICK_SLICE_US)
static void Slave0_BoardInitDisplay(void)
{
    LCD1602_Init();
    LCD1602_BacklightOn();
    LCD1602_Clear();

    LCD1602_SetCursor(0u, 0u);
    LCD1602_WriteStringPadded("Slave0 Ready", 16u);

    LCD1602_SetCursor(1u, 0u);
    LCD1602_WriteStringPadded("UART2 Waiting", 16u);
}

static void Slave0_ServiceOneMs(void)
{
    uint32_t i;

    for (i = 0u; i < SLAVE0_CPU_SLICES_PER_MS; i++) {
        
        Slave0_Execute();

        
        Slave0Time_FndTask();

        delay_us(SLAVE0_CPU_TICK_SLICE_US);
    }

    Slave0Time_Tick1ms();
}

int main(void)
{
    init_platform();

    xil_printf("\r\n");
    xil_printf("========================================\r\n");
    xil_printf(" Slave0 Board Start\r\n");
    xil_printf(" UART2 responder + LCD1602 + FND\r\n");
    xil_printf("========================================\r\n");

    
    Slave0_BoardInitDisplay();

    
    Slave0_Init();

    xil_printf("[MAIN] Waiting sensor packet from Master...\r\n");
    xil_printf("[MAIN] Periodic alive log disabled. RX log prints only on valid Master packet.\r\n");

    while (1) {
        


        Slave0_ServiceOneMs();
    }

    cleanup_platform();
    return 0;
}
