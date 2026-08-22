#include "Protocol.h"


/* 시작 바이트를 제외한 패킷 필드를 XOR해 체크섬을 계산한다. */
uint8_t Protocol_CalcChecksum(const uint8_t *packet, uint8_t checksum_index)
{
    uint8_t checksum = 0;
    uint8_t i;

    if (packet == 0) {
        return 0;
    }

    if (checksum_index <= PACKET_CHECKSUM_START_INDEX) {
        return 0;
    }

    for (i = PACKET_CHECKSUM_START_INDEX; i < checksum_index; i++) {
        checksum ^= packet[i];
    }

    return checksum;
}


int Protocol_VerifyChecksum(const uint8_t *packet, uint8_t packet_len)
{
    uint8_t calc_checksum;
    uint8_t recv_checksum;
    uint8_t checksum_index;

    if (packet == 0) {
        return APP_INVALID_ARG;
    }

    if (packet_len < 3) {
        return APP_INVALID_ARG;
    }

    checksum_index = packet_len - 1;

    calc_checksum = Protocol_CalcChecksum(packet, checksum_index);
    recv_checksum = packet[checksum_index];

    if (calc_checksum != recv_checksum) {
        return APP_CHECKSUM_ERROR;
    }

    return APP_OK;
}


int Protocol_BuildSensorPacket(const sensor_data_t *sensor,
                               uint8_t *packet,
                               uint8_t *packet_len)
{
    if ((sensor == 0) || (packet == 0) || (packet_len == 0)) {
        return APP_INVALID_ARG;
    }

    packet[SENSOR_PACKET_START_IDX]  = PACKET_START_BYTE;
    packet[SENSOR_PACKET_TYPE_IDX]   = PACKET_TYPE_SENSOR;

    packet[SENSOR_PACKET_DIST_H_IDX] = (uint8_t)((sensor->distance_cm >> 8) & 0xFF);
    packet[SENSOR_PACKET_DIST_L_IDX] = (uint8_t)(sensor->distance_cm & 0xFF);

    packet[SENSOR_PACKET_TEMP_IDX]   = sensor->temperature;
    packet[SENSOR_PACKET_HUMID_IDX]  = sensor->humidity;

    packet[SENSOR_PACKET_CHECKSUM_IDX] =
        Protocol_CalcChecksum(packet, SENSOR_PACKET_CHECKSUM_IDX);

    *packet_len = SENSOR_PACKET_LEN;

    return APP_OK;
}


int Protocol_ParseResultPacket(const uint8_t *packet,
                               uint8_t packet_len,
                               result_data_t *result)
{
    int status;
    uint8_t result_code;

    if ((packet == 0) || (result == 0)) {
        return APP_INVALID_ARG;
    }

    if (packet_len != RESULT_PACKET_LEN) {
        return APP_INVALID_ARG;
    }

    if (packet[RESULT_PACKET_START_IDX] != PACKET_START_BYTE) {
        return APP_INVALID_ARG;
    }

    if (packet[RESULT_PACKET_TYPE_IDX] != PACKET_TYPE_RESULT) {
        return APP_INVALID_ARG;
    }

    status = Protocol_VerifyChecksum(packet, packet_len);
    if (status != APP_OK) {
        return status;
    }

    result_code = packet[RESULT_PACKET_CODE_IDX];

    if (!IS_NORMAL_CODE(result_code) && !IS_WARNING_CODE(result_code)) {
        return APP_INVALID_ARG;
    }

    result->minute      = packet[RESULT_PACKET_MINUTE_IDX];
    result->second      = packet[RESULT_PACKET_SECOND_IDX];
    result->result_code = result_code;

    return APP_OK;
}
