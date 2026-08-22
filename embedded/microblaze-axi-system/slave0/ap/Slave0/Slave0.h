#ifndef SRC_AP_SLAVE0_SLAVE0_H_
#define SRC_AP_SLAVE0_SLAVE0_H_

#include <stdint.h>

#include "Slave0_Packet.h"
#include "Slave0_Warning.h"
#include "Slave0_Time.h"

#ifndef SLAVE0_DEBUG_PRINT_ENABLE
#define SLAVE0_DEBUG_PRINT_ENABLE 0u
#endif


#ifndef SLAVE0_MASTER_RX_LOG_ENABLE
#define SLAVE0_MASTER_RX_LOG_ENABLE 1u
#endif

#define SLAVE0_RX_BUFFER_SIZE SLAVE0_SENSOR_PACKET_LEN

typedef struct {
    uint32_t packet_ok_count;
    uint32_t packet_error_count;
    uint32_t result_sent_count;
    uint32_t warning_count;

    Slave0SensorPacket_t last_sensor;

    uint8_t last_minute;
    uint8_t last_second;
    uint8_t last_result_code;
} Slave0Status_t;

void Slave0_Init(void);
void Slave0_Execute(void);
void Slave0_ResetParser(void);
void Slave0_GetStatus(Slave0Status_t *status);
uint32_t Slave0_GetPacketOkCount(void);
uint32_t Slave0_GetPacketErrorCount(void);
uint32_t Slave0_GetResultSentCount(void);
uint32_t Slave0_GetWarningCount(void);

#endif 
