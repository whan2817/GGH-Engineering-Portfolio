#include "WarningLogService.h"

#include "xil_printf.h"
#include "../HAL/EEPROM/EEPROM.h"


/* 쓰기 위치와 저장 개수로 순환 로그의 가장 오래된 레코드를 계산한다. */
static uint8_t WarningLogService_GetOldestIndex(uint8_t write_index,
                                                uint8_t log_count)
{
    if (log_count < LOG_MAX_COUNT) {
        return 0;
    }

    return write_index;
}


static uint8_t WarningLogService_GetLogAddress(uint8_t physical_index)
{
    return (uint8_t)(LOG_BASE_ADDR + (physical_index * LOG_SIZE_BYTES));
}


static int WarningLogService_ReadHeader(uint8_t *write_index,
                                        uint8_t *log_count,
                                        uint8_t *next_seq)
{
    int status;

    if ((write_index == 0) || (log_count == 0) || (next_seq == 0)) {
        return APP_INVALID_ARG;
    }

    status = EEPROM_ReadByte(LOG_WRITE_INDEX_ADDR, write_index);
    if (status != APP_OK) {
        return status;
    }

    status = EEPROM_ReadByte(LOG_COUNT_ADDR, log_count);
    if (status != APP_OK) {
        return status;
    }

    status = EEPROM_ReadByte(LOG_NEXT_SEQ_ADDR, next_seq);
    if (status != APP_OK) {
        return status;
    }

    if (*write_index >= LOG_MAX_COUNT) {
        *write_index = 0;
    }

    if (*log_count > LOG_MAX_COUNT) {
        *log_count = LOG_MAX_COUNT;
    }

    return APP_OK;
}


static int WarningLogService_WriteHeader(uint8_t write_index,
                                         uint8_t log_count,
                                         uint8_t next_seq)
{
    int status;

    status = EEPROM_WriteByte(LOG_WRITE_INDEX_ADDR, write_index);
    if (status != APP_OK) {
        return status;
    }

    status = EEPROM_WriteByte(LOG_COUNT_ADDR, log_count);
    if (status != APP_OK) {
        return status;
    }

    status = EEPROM_WriteByte(LOG_NEXT_SEQ_ADDR, next_seq);
    if (status != APP_OK) {
        return status;
    }

    return APP_OK;
}


static int WarningLogService_ReadLog(uint8_t physical_index,
                                     warning_log_t *log)
{
    uint8_t raw[LOG_SIZE_BYTES];
    uint8_t addr;
    int status;

    if (log == 0) {
        return APP_INVALID_ARG;
    }

    if (physical_index >= LOG_MAX_COUNT) {
        return APP_INVALID_ARG;
    }

    addr = WarningLogService_GetLogAddress(physical_index);

    status = EEPROM_ReadBytes(addr, raw, LOG_SIZE_BYTES);
    if (status != APP_OK) {
        return status;
    }

    log->seq          = raw[LOG_SEQ_IDX];
    log->minute       = raw[LOG_MINUTE_IDX];
    log->second       = raw[LOG_SECOND_IDX];
    log->warning_code = raw[LOG_WARNING_CODE_IDX];
    log->checksum     = raw[LOG_CHECKSUM_IDX];

    return APP_OK;
}


static int WarningLogService_WriteLog(uint8_t physical_index,
                                      const warning_log_t *log)
{
    uint8_t raw[LOG_SIZE_BYTES];
    uint8_t addr;

    if (log == 0) {
        return APP_INVALID_ARG;
    }

    if (physical_index >= LOG_MAX_COUNT) {
        return APP_INVALID_ARG;
    }

    addr = WarningLogService_GetLogAddress(physical_index);

    raw[LOG_SEQ_IDX]          = log->seq;
    raw[LOG_MINUTE_IDX]       = log->minute;
    raw[LOG_SECOND_IDX]       = log->second;
    raw[LOG_WARNING_CODE_IDX] = log->warning_code;
    raw[LOG_CHECKSUM_IDX]     = log->checksum;

    return EEPROM_WriteBytes(addr, raw, LOG_SIZE_BYTES);
}


uint8_t WarningLogService_CalcChecksum(const warning_log_t *log)
{
    uint8_t checksum;

    if (log == 0) {
        return 0;
    }

    checksum = 0;
    checksum ^= log->seq;
    checksum ^= log->minute;
    checksum ^= log->second;
    checksum ^= log->warning_code;

    return checksum;
}


const char *WarningLogService_CodeToString(uint8_t warning_code)
{
    switch (warning_code) {
    case WARNING_CODE_NORMAL:
        return "NORMAL";

    case WARNING_CODE_DISTANCE:
        return "DIST_WARN";

    case WARNING_CODE_TEMP_HIGH:
        return "TEMP_WARN";

    case WARNING_CODE_HUMID_HIGH:
        return "HUMID_WARN";

    case WARNING_CODE_DIST_TEMP:
        return "DIST_TEMP_WARN";

    case WARNING_CODE_DIST_HUMID:
        return "DIST_HUMID_WARN";

    case WARNING_CODE_TEMP_HUMID:
        return "TEMP_HUMID_WARN";

    case WARNING_CODE_ALL:
        return "ALL_WARN";

    case WARNING_CODE_SENSOR_ERROR:
        return "SENSOR_ERROR";

    default:
        return "UNKNOWN";
    }
}


int WarningLogService_Format(void)
{
    int status;

    status = EEPROM_WriteByte(LOG_MAGIC_ADDR, LOG_MAGIC_VALUE);
    if (status != APP_OK) {
        return status;
    }

    status = WarningLogService_WriteHeader(0, 0, 1);
    if (status != APP_OK) {
        return status;
    }

    return APP_OK;
}


void WarningLogService_Init(void)
{
    uint8_t magic;
    int status;

    EEPROM_Init();

    status = EEPROM_ReadByte(LOG_MAGIC_ADDR, &magic);
    if (status != APP_OK) {
        xil_printf("[WarningLog] EEPROM magic read failed. status=%d\r\n", status);
        return;
    }

    if (magic != LOG_MAGIC_VALUE) {
        xil_printf("[WarningLog] Log area not formatted. Formatting...\r\n");

        status = WarningLogService_Format();
        if (status == APP_OK) {
            xil_printf("[WarningLog] Format done.\r\n");
        } else {
            xil_printf("[WarningLog] Format failed. status=%d\r\n", status);
        }
    } else {
        xil_printf("[WarningLog] Log area ready.\r\n");
    }
}


/* 경고 레코드를 현재 위치에 저장한 뒤 다음 쓰기 위치와 순번을 갱신한다. */
int WarningLogService_Save(uint8_t minute,
                           uint8_t second,
                           uint8_t warning_code)
{
    uint8_t write_index;
    uint8_t log_count;
    uint8_t next_seq;
    uint8_t next_write_index;
    warning_log_t log;
    int status;

    if (!IS_WARNING_CODE(warning_code)) {
        return APP_INVALID_ARG;
    }

    if (minute > 59U) {
        return APP_INVALID_ARG;
    }

    if (second > 59U) {
        return APP_INVALID_ARG;
    }

    status = WarningLogService_ReadHeader(&write_index, &log_count, &next_seq);
    if (status != APP_OK) {
        return status;
    }

    log.seq          = next_seq;
    log.minute       = minute;
    log.second       = second;
    log.warning_code = warning_code;
    log.checksum     = WarningLogService_CalcChecksum(&log);

    status = WarningLogService_WriteLog(write_index, &log);
    if (status != APP_OK) {
        return status;
    }

    next_write_index = (uint8_t)(write_index + 1U);
    if (next_write_index >= LOG_MAX_COUNT) {
        next_write_index = 0;
    }

    if (log_count < LOG_MAX_COUNT) {
        log_count++;
    }

    next_seq++;
    if (next_seq == 0U) {
        next_seq = 1U;
    }

    status = WarningLogService_WriteHeader(next_write_index, log_count, next_seq);
    if (status != APP_OK) {
        return status;
    }

    xil_printf("[WarningLog] Saved: seq=%d time=%d:%d code=0x%x %s\r\n",
               log.seq,
               log.minute,
               log.second,
               log.warning_code,
               WarningLogService_CodeToString(log.warning_code));

    return APP_OK;
}


int WarningLogService_DumpAll(void)
{
    uint8_t magic;
    uint8_t write_index;
    uint8_t log_count;
    uint8_t next_seq;
    uint8_t oldest_index;
    uint8_t physical_index;
    uint8_t i;
    warning_log_t log;
    uint8_t calc_checksum;
    int status;

    status = EEPROM_ReadByte(LOG_MAGIC_ADDR, &magic);
    if (status != APP_OK) {
        xil_printf("[WarningLog] Magic read failed. status=%d\r\n", status);
        return status;
    }

    if (magic != LOG_MAGIC_VALUE) {
        xil_printf("[WarningLog] Log area is not formatted.\r\n");
        return APP_ERROR;
    }

    status = WarningLogService_ReadHeader(&write_index, &log_count, &next_seq);
    if (status != APP_OK) {
        xil_printf("[WarningLog] Header read failed. status=%d\r\n", status);
        return status;
    }

    oldest_index = WarningLogService_GetOldestIndex(write_index, log_count);

    xil_printf("\r\n========================================\r\n");
    xil_printf(" EEPROM WARNING LOG DUMP\r\n");
    xil_printf(" count       = %d\r\n", log_count);
    xil_printf(" max         = %d\r\n", LOG_MAX_COUNT);
    xil_printf(" write_index = %d\r\n", write_index);
    xil_printf(" next_seq    = %d\r\n", next_seq);
    xil_printf("========================================\r\n");

    if (log_count == 0U) {
        xil_printf(" No warning log stored.\r\n");
        xil_printf("========================================\r\n");
        xil_printf(" END OF LOG\r\n");
        xil_printf("========================================\r\n");
        return APP_OK;
    }

    for (i = 0; i < log_count; i++) {
        physical_index = (uint8_t)((oldest_index + i) % LOG_MAX_COUNT);

        status = WarningLogService_ReadLog(physical_index, &log);
        if (status != APP_OK) {
        	xil_printf("[%d] Read failed. status=%d\r\n", i, status);
            continue;
        }

        calc_checksum = WarningLogService_CalcChecksum(&log);

        xil_printf("[%d] seq=%d time=%d:%d code=0x%x %s checksum=%s\r\n",
                   i,
                   log.seq,
                   log.minute,
                   log.second,
                   log.warning_code,
                   WarningLogService_CodeToString(log.warning_code),
                   (calc_checksum == log.checksum) ? "OK" : "BAD");
    }

    xil_printf("========================================\r\n");
    xil_printf(" END OF LOG\r\n");
    xil_printf("========================================\r\n");

    return APP_OK;
}
