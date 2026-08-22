#include "Slave0_Time.h"
#include "../../driver/FND/FND.h"

static uint16_t g_ms_count = 0u;
static uint8_t  g_minute   = 0u;
static uint8_t  g_second   = 0u;

void Slave0Time_Init(void)
{
    g_ms_count = 0u;
    g_minute   = 0u;
    g_second   = 0u;

    FND_Init();
    FND_SetTime(g_minute, g_second);
}

void Slave0Time_Tick1ms(void)
{
    g_ms_count++;

    if (g_ms_count >= SLAVE0_TIME_MS_PER_SEC) {
        g_ms_count = 0u;

        g_second++;
        if (g_second >= SLAVE0_TIME_SEC_MAX) {
            g_second = 0u;

            g_minute++;
            if (g_minute >= SLAVE0_TIME_MIN_MAX) {
                g_minute = 0u;
            }
        }

        FND_SetTime(g_minute, g_second);
    }
}

void Slave0Time_GetTime(uint8_t *minute, uint8_t *second)
{
    if (minute != 0) {
        *minute = g_minute;
    }

    if (second != 0) {
        *second = g_second;
    }
}

Slave0Time_t Slave0Time_GetTimeStruct(void)
{
    Slave0Time_t time_data;

    time_data.minute = g_minute;
    time_data.second = g_second;

    return time_data;
}

void Slave0Time_SetTime(uint8_t minute, uint8_t second)
{
    if (minute >= SLAVE0_TIME_MIN_MAX) {
        minute = 0u;
    }

    if (second >= SLAVE0_TIME_SEC_MAX) {
        second = 0u;
    }

    g_minute   = minute;
    g_second   = second;
    g_ms_count = 0u;

    FND_SetTime(g_minute, g_second);
}

void Slave0Time_Reset(void)
{
    Slave0Time_Init();
}

void Slave0Time_FndTask(void)
{
    FND_Execute();
}
