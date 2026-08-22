#include "MeasurementService.h"

#include "../HAL/HCSR04/HCSR04.h"
#include "../HAL/DHT11/DHT11.h"
#include "../HAL/TIMER/TIMER.h"


void MeasurementService_Init(void)
{
    HCSR04_Init();
    DHT11_Init();
    TIMER_Init();
}


/* 두 센서의 측정을 동시에 시작하고 2초 타이머로 결과 확인 시점을 정한다. */
void MeasurementService_Start(void)
{
    HCSR04_Start();
    DHT11_Start();

    TIMER_Start2SecInterrupt();
}


/* 완료 상태를 확인한 센서만 결과 구조체에 반영한다. */
int MeasurementService_Read(sensor_data_t *sensor)
{
    if (sensor == 0) {
        return APP_INVALID_ARG;
    }

    sensor->distance_cm = MEASUREMENT_DISTANCE_INVALID;
    sensor->temperature = MEASUREMENT_TEMPERATURE_INVALID;
    sensor->humidity    = MEASUREMENT_HUMIDITY_INVALID;

    sensor->hcsr04_done = 0;
    sensor->dht11_valid = 0;

    


    if (HCSR04_IsDone()) {
        sensor->distance_cm = HCSR04_GetDistanceCm();
        sensor->hcsr04_done = 1;

        HCSR04_ClearDone();
    }

    


    if (DHT11_IsValid()) {
        sensor->temperature = DHT11_GetTemperature();
        sensor->humidity    = DHT11_GetHumidity();
        sensor->dht11_valid = 1;
    }

    return APP_OK;
}


int MeasurementService_MeasureBlocking(sensor_data_t *sensor)
{
    int hcsr04_status;
    int dht11_status;
    uint16_t distance;
    uint8_t temperature;
    uint8_t humidity;

    if (sensor == 0) {
        return APP_INVALID_ARG;
    }

    sensor->distance_cm = MEASUREMENT_DISTANCE_INVALID;
    sensor->temperature = MEASUREMENT_TEMPERATURE_INVALID;
    sensor->humidity    = MEASUREMENT_HUMIDITY_INVALID;

    sensor->hcsr04_done = 0;
    sensor->dht11_valid = 0;

    hcsr04_status = HCSR04_ReadDistance(&distance, HCSR04_TIMEOUT_MS);
    if (hcsr04_status == APP_OK) {
        sensor->distance_cm = distance;
        sensor->hcsr04_done = 1;
    }

    dht11_status = DHT11_ReadData(&temperature, &humidity, DHT11_TIMEOUT_MS);
    if (dht11_status == APP_OK) {
        sensor->temperature = temperature;
        sensor->humidity    = humidity;
        sensor->dht11_valid = 1;
    }

    return APP_OK;
}


uint8_t MeasurementService_HasSensorError(const sensor_data_t *sensor)
{
    if (sensor == 0) {
        return 1;
    }

    if (sensor->hcsr04_done == 0U) {
        return 1;
    }

    if (sensor->dht11_valid == 0U) {
        return 1;
    }

    if (sensor->distance_cm == MEASUREMENT_DISTANCE_INVALID) {
        return 1;
    }

    if (sensor->temperature == MEASUREMENT_TEMPERATURE_INVALID) {
        return 1;
    }

    if (sensor->humidity == MEASUREMENT_HUMIDITY_INVALID) {
        return 1;
    }

    return 0;
}
