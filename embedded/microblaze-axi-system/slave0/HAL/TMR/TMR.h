#ifndef SRC_HAL_TMR_TMR_H_
#define SRC_HAL_TMR_TMR_H_

#include <stdint.h>
#include "xparameters.h"

typedef struct {
    volatile uint32_t CR;
    volatile uint32_t PSC;
    volatile uint32_t ARR;
    volatile uint32_t CNT;
} TMR_TypeDef_t;

#if defined(XPAR_TIMER_0_S00_AXI_BASEADDR)
#define SLAVE0_HAS_TMR0 1
#define TMR0_BASEADDR XPAR_TIMER_0_S00_AXI_BASEADDR
#define TMR0 ((TMR_TypeDef_t *)TMR0_BASEADDR)
#elif defined(XPAR_TMR_0_S00_AXI_BASEADDR)
#define SLAVE0_HAS_TMR0 1
#define TMR0_BASEADDR XPAR_TMR_0_S00_AXI_BASEADDR
#define TMR0 ((TMR_TypeDef_t *)TMR0_BASEADDR)
#else
#define SLAVE0_HAS_TMR0 0
#endif

#define TMR_EN_BIT 0u
#define TMR_IE_BIT 1u

void TMR_SetPSC(TMR_TypeDef_t *tmr, uint32_t psc);
uint32_t TMR_GetPSC(TMR_TypeDef_t *tmr);
void TMR_SetARR(TMR_TypeDef_t *tmr, uint32_t arr);
uint32_t TMR_GetARR(TMR_TypeDef_t *tmr);
void TMR_SetCNT(TMR_TypeDef_t *tmr, uint32_t cnt);
uint32_t TMR_GetCNT(TMR_TypeDef_t *tmr);
void TMR_StartTimer(TMR_TypeDef_t *tmr);
void TMR_StopTimer(TMR_TypeDef_t *tmr);
void TMR_StartInterrupt(TMR_TypeDef_t *tmr);
void TMR_StopInterrupt(TMR_TypeDef_t *tmr);

#endif 
