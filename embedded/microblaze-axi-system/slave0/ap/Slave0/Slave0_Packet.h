#ifndef SRC_AP_SLAVE0_SLAVE0_PACKET_H_
#define SRC_AP_SLAVE0_SLAVE0_PACKET_H_

#include <stdint.h>


#define SLAVE0_START_BYTE          0xAAu

#define SLAVE0_TYPE_SENSOR         0x10u
#define SLAVE0_TYPE_RESULT         0x20u


#define SLAVE0_SENSOR_PACKET_LEN   7u

#define SLAVE0_SENSOR_START_IDX    0u
#define SLAVE0_SENSOR_TYPE_IDX     1u
#define SLAVE0_SENSOR_DIST_H_IDX   2u
#define SLAVE0_SENSOR_DIST_L_IDX   3u
#define SLAVE0_SENSOR_TEMP_IDX     4u
#define SLAVE0_SENSOR_HUMID_IDX    5u
#define SLAVE0_SENSOR_CHECKSUM_IDX 6u


#define SLAVE0_RESULT_PACKET_LEN   6u

#define SLAVE0_RESULT_START_IDX    0u
#define SLAVE0_RESULT_TYPE_IDX     1u
#define SLAVE0_RESULT_MINUTE_IDX   2u
#define SLAVE0_RESULT_SECOND_IDX   3u
#define SLAVE0_RESULT_CODE_IDX     4u
#define SLAVE0_RESULT_CHECKSUM_IDX 5u


typedef struct {
    uint16_t distance_cm;
    uint8_t  temperature;
    uint8_t  humidity;
} Slave0SensorPacket_t;


typedef struct {
    uint8_t minute;
    uint8_t second;
    uint8_t result_code;
} Slave0ResultPacket_t;


uint8_t Slave0_ChecksumXor(const uint8_t *packet,
                           uint32_t start_idx,
                           uint32_t end_idx_exclusive);

int Slave0_ParseSensorPacket(const uint8_t raw[SLAVE0_SENSOR_PACKET_LEN],
                             Slave0SensorPacket_t *sensor);

void Slave0_BuildResultPacket(const Slave0ResultPacket_t *result,
                              uint8_t raw[SLAVE0_RESULT_PACKET_LEN]);

#endif 
