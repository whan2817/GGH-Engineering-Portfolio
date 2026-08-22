#include "Slave0_Packet.h"


/* 패킷 타입부터 체크섬 직전 필드까지 XOR해 무결성을 확인한다. */
uint8_t Slave0_ChecksumXor(const uint8_t *packet,
                           uint32_t start_idx,
                           uint32_t end_idx_exclusive)
{
    uint8_t checksum;
    uint32_t i;

    if (packet == 0) {
        return 0u;
    }

    checksum = 0u;

    for (i = start_idx; i < end_idx_exclusive; i++) {
        checksum ^= packet[i];
    }

    return checksum;
}


int Slave0_ParseSensorPacket(const uint8_t raw[SLAVE0_SENSOR_PACKET_LEN],
                             Slave0SensorPacket_t *sensor)
{
    uint8_t checksum;

    if ((raw == 0) || (sensor == 0)) {
        return 0;
    }

    if (raw[SLAVE0_SENSOR_START_IDX] != SLAVE0_START_BYTE) {
        return 0;
    }

    if (raw[SLAVE0_SENSOR_TYPE_IDX] != SLAVE0_TYPE_SENSOR) {
        return 0;
    }

    checksum = Slave0_ChecksumXor(raw,
                                  SLAVE0_SENSOR_TYPE_IDX,
                                  SLAVE0_SENSOR_CHECKSUM_IDX);

    if (checksum != raw[SLAVE0_SENSOR_CHECKSUM_IDX]) {
        return 0;
    }

    sensor->distance_cm =
        ((uint16_t)raw[SLAVE0_SENSOR_DIST_H_IDX] << 8) |
        ((uint16_t)raw[SLAVE0_SENSOR_DIST_L_IDX]);

    sensor->temperature = raw[SLAVE0_SENSOR_TEMP_IDX];
    sensor->humidity    = raw[SLAVE0_SENSOR_HUMID_IDX];

    return 1;
}


void Slave0_BuildResultPacket(const Slave0ResultPacket_t *result,
                              uint8_t raw[SLAVE0_RESULT_PACKET_LEN])
{
    if ((result == 0) || (raw == 0)) {
        return;
    }

    raw[SLAVE0_RESULT_START_IDX]  = SLAVE0_START_BYTE;
    raw[SLAVE0_RESULT_TYPE_IDX]   = SLAVE0_TYPE_RESULT;
    raw[SLAVE0_RESULT_MINUTE_IDX] = result->minute;
    raw[SLAVE0_RESULT_SECOND_IDX] = result->second;
    raw[SLAVE0_RESULT_CODE_IDX]   = result->result_code;

    raw[SLAVE0_RESULT_CHECKSUM_IDX] =
        Slave0_ChecksumXor(raw,
                           SLAVE0_RESULT_TYPE_IDX,
                           SLAVE0_RESULT_CHECKSUM_IDX);
}

