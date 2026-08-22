#include "Slave0_Warning.h"


static uint8_t g_last_condition_code = SLAVE0_WARNING_NORMAL;
static uint8_t g_consecutive_count   = 0u;


static uint8_t Slave0Warning_GetRawConditionCode(const Slave0SensorPacket_t *sensor)
{
    uint8_t dist_warn;
    uint8_t temp_warn;
    uint8_t humid_warn;

    if (sensor == 0) {
        return SLAVE0_WARNING_SENSOR_ERROR;
    }

    


    if ((sensor->distance_cm == SLAVE0_DISTANCE_INVALID_VALUE) ||
        (sensor->temperature == SLAVE0_TEMP_INVALID_VALUE) ||
        (sensor->humidity == SLAVE0_HUMID_INVALID_VALUE)) {
        return SLAVE0_WARNING_SENSOR_ERROR;
    }

    dist_warn = 0u;
    temp_warn = 0u;
    humid_warn = 0u;

    if (sensor->distance_cm <= SLAVE0_DISTANCE_WARN_THRESHOLD_CM) {
        dist_warn = 1u;
    }

    if (sensor->temperature >= SLAVE0_TEMP_HIGH_THRESHOLD_C) {
        temp_warn = 1u;
    }

    if (sensor->humidity >= SLAVE0_HUMID_HIGH_THRESHOLD_PERCENT) {
        humid_warn = 1u;
    }

    


    if ((dist_warn != 0u) && (temp_warn != 0u) && (humid_warn != 0u)) {
        return SLAVE0_WARNING_ALL;
    }

    if ((dist_warn != 0u) && (temp_warn != 0u)) {
        return SLAVE0_WARNING_DIST_TEMP;
    }

    if ((dist_warn != 0u) && (humid_warn != 0u)) {
        return SLAVE0_WARNING_DIST_HUMID;
    }

    if ((temp_warn != 0u) && (humid_warn != 0u)) {
        return SLAVE0_WARNING_TEMP_HUMID;
    }

    if (dist_warn != 0u) {
        return SLAVE0_WARNING_DISTANCE;
    }

    if (temp_warn != 0u) {
        return SLAVE0_WARNING_TEMP_HIGH;
    }

    if (humid_warn != 0u) {
        return SLAVE0_WARNING_HUMID_HIGH;
    }

    return SLAVE0_WARNING_NORMAL;
}


void Slave0Warning_Init(void)
{
    g_last_condition_code = SLAVE0_WARNING_NORMAL;
    g_consecutive_count   = 0u;
}


/* 동일한 경고 조건이 연속으로 누적된 경우에만 확정 경고 코드를 반환한다. */
uint8_t Slave0Warning_Evaluate(const Slave0SensorPacket_t *sensor)
{
    uint8_t raw_code;

    raw_code = Slave0Warning_GetRawConditionCode(sensor);

    


    if (raw_code == SLAVE0_WARNING_SENSOR_ERROR) {
        g_last_condition_code = SLAVE0_WARNING_SENSOR_ERROR;
        g_consecutive_count = SLAVE0_WARN_LIMIT;
        return SLAVE0_WARNING_SENSOR_ERROR;
    }

    


    if (raw_code == SLAVE0_WARNING_NORMAL) {
        g_last_condition_code = SLAVE0_WARNING_NORMAL;
        g_consecutive_count = 0u;
        return SLAVE0_WARNING_NORMAL;
    }

    


    if (raw_code == g_last_condition_code) {
        if (g_consecutive_count < SLAVE0_WARN_LIMIT) {
            g_consecutive_count++;
        }
    } else {
        g_last_condition_code = raw_code;
        g_consecutive_count = 1u;
    }

    


    if (g_consecutive_count >= SLAVE0_WARN_LIMIT) {
        return raw_code;
    }

    return SLAVE0_WARNING_NORMAL;
}


const char *Slave0Warning_CodeToString(uint8_t warning_code)
{
    switch (warning_code) {
    case SLAVE0_WARNING_NORMAL:
        return "NORMAL";

    case SLAVE0_WARNING_DISTANCE:
        return "DISTANCE";

    case SLAVE0_WARNING_TEMP_HIGH:
        return "TEMP_HIGH";

    case SLAVE0_WARNING_HUMID_HIGH:
        return "HUMID_HIGH";

    case SLAVE0_WARNING_DIST_TEMP:
        return "DIST_TEMP";

    case SLAVE0_WARNING_DIST_HUMID:
        return "DIST_HUMID";

    case SLAVE0_WARNING_TEMP_HUMID:
        return "TEMP_HUMID";

    case SLAVE0_WARNING_ALL:
        return "ALL";

    case SLAVE0_WARNING_SENSOR_ERROR:
        return "SENSOR_ERROR";

    default:
        return "UNKNOWN";
    }
}
