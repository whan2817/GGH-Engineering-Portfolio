#ifndef SRC_AP_MEASUREMENTSERVICE_H_
#define SRC_AP_MEASUREMENTSERVICE_H_

#include <stdint.h>
#include "../common/types/app_types.h"


#define MEASUREMENT_DISTANCE_INVALID      0xFFFF
#define MEASUREMENT_TEMPERATURE_INVALID   0xFF
#define MEASUREMENT_HUMIDITY_INVALID      0xFF


void MeasurementService_Init(void);

void MeasurementService_Start(void);

int MeasurementService_Read(sensor_data_t *sensor);

int MeasurementService_MeasureBlocking(sensor_data_t *sensor);

uint8_t MeasurementService_HasSensorError(const sensor_data_t *sensor);


#endif 
