#ifndef SRC_AP_MASTERAPP_H_
#define SRC_AP_MASTERAPP_H_

#include <stdint.h>
#include "../common/types/app_types.h"


typedef enum {
    MASTER_STATE_IDLE = 0,
    MASTER_STATE_MEASURING,
    MASTER_STATE_READ_SENSOR,
    MASTER_STATE_DISPLAY_SENSOR,
    MASTER_STATE_SEND_SENSOR_PACKET,
    MASTER_STATE_WAIT_RESULT_PACKET,
    MASTER_STATE_PROCESS_RESULT,
    MASTER_STATE_LOG_DUMP,
    MASTER_STATE_ERROR
} master_app_state_t;


#define MASTER_EVENT_NONE          0x00
#define MASTER_EVENT_MANUAL        0x01
#define MASTER_EVENT_AUTO          0x02
#define MASTER_EVENT_LOG           0x04
#define MASTER_EVENT_TIMER_DONE    0x08


#define MASTER_AUTO_MODE_OFF       0
#define MASTER_AUTO_MODE_ON        1


void MasterApp_Init(void);

void MasterApp_Update(void);

void MasterApp_StartManual(void);
void MasterApp_ToggleAuto(void);
void MasterApp_RequestLogDump(void);

uint8_t MasterApp_IsBusy(void);
uint8_t MasterApp_IsAutoModeOn(void);

master_app_state_t MasterApp_GetState(void);

#endif 
