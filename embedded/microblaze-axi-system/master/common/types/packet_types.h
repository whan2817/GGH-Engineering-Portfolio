#ifndef SRC_COMMON_TYPES_PACKET_TYPES_H_
#define SRC_COMMON_TYPES_PACKET_TYPES_H_

#include <stdint.h>


#define PACKET_START_BYTE              0xAA

#define PACKET_TYPE_SENSOR             0x10
#define PACKET_TYPE_RESULT             0x20

#define PACKET_MAX_LEN                 8


#define PACKET_CHECKSUM_START_INDEX    1


#define SENSOR_PACKET_LEN              7

#define SENSOR_PACKET_START_IDX        0
#define SENSOR_PACKET_TYPE_IDX         1
#define SENSOR_PACKET_DIST_H_IDX       2
#define SENSOR_PACKET_DIST_L_IDX       3
#define SENSOR_PACKET_TEMP_IDX         4
#define SENSOR_PACKET_HUMID_IDX        5
#define SENSOR_PACKET_CHECKSUM_IDX     6


#define RESULT_PACKET_LEN              6

#define RESULT_PACKET_START_IDX        0
#define RESULT_PACKET_TYPE_IDX         1
#define RESULT_PACKET_MINUTE_IDX       2
#define RESULT_PACKET_SECOND_IDX       3
#define RESULT_PACKET_CODE_IDX         4
#define RESULT_PACKET_CHECKSUM_IDX     5


#define RESULT_PACKET_TIMEOUT_MS       1000

#endif 
