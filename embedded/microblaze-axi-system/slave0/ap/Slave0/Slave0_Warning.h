#ifndef SRC_AP_SLAVE0_SLAVE0_WARNING_H_
#define SRC_AP_SLAVE0_SLAVE0_WARNING_H_

#include <stdint.h>
#include "Slave0_Packet.h"


#define SLAVE0_WARNING_NORMAL          0x00u
#define SLAVE0_WARNING_DISTANCE        0x01u
#define SLAVE0_WARNING_TEMP_HIGH       0x02u
#define SLAVE0_WARNING_HUMID_HIGH      0x03u
#define SLAVE0_WARNING_DIST_TEMP       0x04u
#define SLAVE0_WARNING_DIST_HUMID      0x05u
#define SLAVE0_WARNING_TEMP_HUMID      0x06u
#define SLAVE0_WARNING_ALL             0x07u
#define SLAVE0_WARNING_SENSOR_ERROR    0x08u


#define SLAVE0_DISTANCE_WARN_THRESHOLD_CM     30u
#define SLAVE0_TEMP_HIGH_THRESHOLD_C          30u
#define SLAVE0_HUMID_HIGH_THRESHOLD_PERCENT   70u

#define SLAVE0_DISTANCE_INVALID_VALUE         0xFFFFu
#define SLAVE0_TEMP_INVALID_VALUE             0xFFu
#define SLAVE0_HUMID_INVALID_VALUE            0xFFu


#define SLAVE0_WARN_LIMIT                     3u


#define SLAVE0_IS_NORMAL_CODE(code)       ((code) == SLAVE0_WARNING_NORMAL)

#define SLAVE0_IS_WARNING_CODE(code)      (((code) >= SLAVE0_WARNING_DISTANCE) && \
                                           ((code) <= SLAVE0_WARNING_SENSOR_ERROR))


void Slave0Warning_Init(void);


uint8_t Slave0Warning_Evaluate(const Slave0SensorPacket_t *sensor);


const char *Slave0Warning_CodeToString(uint8_t warning_code);

#endif 


