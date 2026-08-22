#include "delay.h"

static volatile uint32_t g_m_tick = 0;

uint32_t millis(void)
{
    return g_m_tick;
}

void incTick(void)
{
    g_m_tick++;
}

void delay_sec(uint32_t seconds)
{
    sleep(seconds);
}

void delay_ms(uint32_t msec)
{
    usleep(msec * 1000u);
}

void delay_us(uint32_t usec)
{
    usleep(usec);
}
