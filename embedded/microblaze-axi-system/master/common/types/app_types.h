#ifndef SRC_COMMON_TYPES_APP_TYPES_H_
#define SRC_COMMON_TYPES_APP_TYPES_H_
#include <stdint.h>


typedef enum {
    APP_OK = 0,
    APP_ERROR = -1,
    APP_TIMEOUT = -2,
    APP_CHECKSUM_ERROR = -3,
    APP_INVALID_ARG = -4,
    APP_NO_DATA = -5
} app_status_t;


typedef enum {
    APP_OFF = 0,
    APP_ON  = 1
} app_onoff_t;


#define WARNING_CODE_NORMAL          0x00

#define WARNING_CODE_DISTANCE        0x01
#define WARNING_CODE_TEMP_HIGH       0x02
#define WARNING_CODE_HUMID_HIGH      0x03
#define WARNING_CODE_DIST_TEMP       0x04
#define WARNING_CODE_DIST_HUMID      0x05
#define WARNING_CODE_TEMP_HUMID      0x06
#define WARNING_CODE_ALL             0x07
#define WARNING_CODE_SENSOR_ERROR    0x08

#define WARNING_CODE_MIN             0x01
#define WARNING_CODE_MAX             0x08


typedef struct {
    uint16_t distance_cm;
    uint8_t  temperature;
    uint8_t  humidity;

    uint8_t  hcsr04_done;
    uint8_t  dht11_valid;
} sensor_data_t;


typedef struct {
    uint8_t minute;
    uint8_t second;
    uint8_t result_code;
} result_data_t;


typedef struct {
    uint8_t seq;
    uint8_t minute;
    uint8_t second;
    uint8_t warning_code;
    uint8_t checksum;
} warning_log_t;


#define IS_WARNING_CODE(code) \
    (((code) >= WARNING_CODE_MIN) && ((code) <= WARNING_CODE_MAX))

#define IS_NORMAL_CODE(code) \
    ((code) == WARNING_CODE_NORMAL)

#endif 
