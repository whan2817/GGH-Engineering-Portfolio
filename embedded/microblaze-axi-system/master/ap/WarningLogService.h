#ifndef SRC_AP_WARNINGLOGSERVICE_H_
#define SRC_AP_WARNINGLOGSERVICE_H_

#include <stdint.h>
#include "../common/types/app_types.h"


#define LOG_MAGIC_ADDR              0x00
#define LOG_WRITE_INDEX_ADDR        0x01
#define LOG_COUNT_ADDR              0x02
#define LOG_NEXT_SEQ_ADDR           0x03

#define LOG_RESERVED_START_ADDR     0x04
#define LOG_RESERVED_END_ADDR       0x0F

#define LOG_BASE_ADDR               0x10
#define LOG_END_ADDR                0xFF

#define LOG_MAGIC_VALUE             0xA5


#define LOG_SIZE_BYTES              5

#define LOG_SEQ_IDX                 0
#define LOG_MINUTE_IDX              1
#define LOG_SECOND_IDX              2
#define LOG_WARNING_CODE_IDX        3
#define LOG_CHECKSUM_IDX            4


#define LOG_MAX_COUNT               48


void WarningLogService_Init(void);

int WarningLogService_Format(void);

int WarningLogService_Save(uint8_t minute,
                           uint8_t second,
                           uint8_t warning_code);

int WarningLogService_DumpAll(void);

uint8_t WarningLogService_CalcChecksum(const warning_log_t *log);

const char *WarningLogService_CodeToString(uint8_t warning_code);


#endif 
