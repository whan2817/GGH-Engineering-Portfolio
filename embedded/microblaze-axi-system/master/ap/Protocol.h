#ifndef SRC_AP_PROTOCOL_H_
#define SRC_AP_PROTOCOL_H_

#include <stdint.h>
#include "../common/types/app_types.h"
#include "../common/types/packet_types.h"


uint8_t Protocol_CalcChecksum(const uint8_t *packet, uint8_t checksum_index);

int Protocol_VerifyChecksum(const uint8_t *packet, uint8_t packet_len);


int Protocol_BuildSensorPacket(const sensor_data_t *sensor, uint8_t *packet, uint8_t *packet_len);


int Protocol_ParseResultPacket(const uint8_t *packet, uint8_t packet_len, result_data_t *result);

#endif 
