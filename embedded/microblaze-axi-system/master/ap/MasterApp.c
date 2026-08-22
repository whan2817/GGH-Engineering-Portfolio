#include "MasterApp.h"

#include "Protocol.h"
#include "MeasurementService.h"
#include "WarningLogService.h"

#include "../HAL/UART2/UART2.h"
#include "../HAL/LCD/LCD.h"

#include "../driver/Button/Button.h"
#include "../common/interrupt/interrupt.h"

#include "xil_printf.h"


static master_app_state_t master_state = MASTER_STATE_IDLE;

static uint8_t auto_mode = MASTER_AUTO_MODE_OFF;
static uint8_t log_dump_request = 0;

static sensor_data_t current_sensor;
static result_data_t current_result;

static uint8_t sensor_packet[PACKET_MAX_LEN];
static uint8_t result_packet[PACKET_MAX_LEN];
static uint8_t sensor_packet_len = 0;


static void MasterApp_ClearSensorData(void)
{
    current_sensor.distance_cm = MEASUREMENT_DISTANCE_INVALID;
    current_sensor.temperature = MEASUREMENT_TEMPERATURE_INVALID;
    current_sensor.humidity    = MEASUREMENT_HUMIDITY_INVALID;

    current_sensor.hcsr04_done = 0;
    current_sensor.dht11_valid = 0;
}


static void MasterApp_ClearResultData(void)
{
    current_result.minute      = 0;
    current_result.second      = 0;
    current_result.result_code = WARNING_CODE_NORMAL;
}


static void MasterApp_StartSequence(void)
{
    MasterApp_ClearSensorData();
    MasterApp_ClearResultData();

    Interrupt_ClearTimerFlag();

    MeasurementService_Start();

    LCD_PrintMessage("Measuring...", "Please wait");

    master_state = MASTER_STATE_MEASURING;

    xil_printf("[Master] Measurement started.\r\n");
}


static void MasterApp_ProcessButtonEvent(void)
{
    uint8_t event;

    Button_Update();

    event = Button_GetEvent();

    if (event & BUTTON_EVENT_AUTO) {
        Button_ClearEvent(BUTTON_EVENT_AUTO);
        MasterApp_ToggleAuto();
    }

    if (event & BUTTON_EVENT_LOG) {
        Button_ClearEvent(BUTTON_EVENT_LOG);
        MasterApp_RequestLogDump();
    }

    if (event & BUTTON_EVENT_MANUAL) {
        Button_ClearEvent(BUTTON_EVENT_MANUAL);

        if (master_state == MASTER_STATE_IDLE) {
            MasterApp_StartManual();
        }
    }
}


static void MasterApp_GoIdleOrAutoRestart(void)
{
    if (log_dump_request) {
        master_state = MASTER_STATE_LOG_DUMP;
    } else if (auto_mode == MASTER_AUTO_MODE_ON) {
        MasterApp_StartSequence();
    } else {
        master_state = MASTER_STATE_IDLE;
        LCD_PrintMessage("Master Ready", "Manual/Auto/Log");
    }
}


void MasterApp_Init(void)
{
    master_state = MASTER_STATE_IDLE;
    auto_mode = MASTER_AUTO_MODE_OFF;
    log_dump_request = 0;

    MasterApp_ClearSensorData();
    MasterApp_ClearResultData();

    Button_Init();
    UART2_Init();
    MeasurementService_Init();
    WarningLogService_Init();

    LCD_Init();
    LCD_PrintMessage("Master Ready", "Manual/Auto/Log");

    xil_printf("[Master] MasterApp initialized.\r\n");
}


void MasterApp_Update(void)
{
    int status;

    MasterApp_ProcessButtonEvent();

    /* 측정, 표시, 패킷 송수신, 로그 저장을 상태별로 순차 처리한다. */
    switch (master_state) {
    case MASTER_STATE_IDLE:
        if (log_dump_request) {
            master_state = MASTER_STATE_LOG_DUMP;
        } else if (auto_mode == MASTER_AUTO_MODE_ON) {
            MasterApp_StartSequence();
        }
        break;

    case MASTER_STATE_MEASURING:
        if (Interrupt_GetTimerFlag()) {
            Interrupt_ClearTimerFlag();
            master_state = MASTER_STATE_READ_SENSOR;
        }
        break;

    case MASTER_STATE_READ_SENSOR:
        status = MeasurementService_Read(&current_sensor);
        if (status != APP_OK) {
            xil_printf("[Master] Sensor read failed. status=%d\r\n", status);
            master_state = MASTER_STATE_ERROR;
        } else {
            master_state = MASTER_STATE_DISPLAY_SENSOR;
        }
        break;

    case MASTER_STATE_DISPLAY_SENSOR:
        LCD_PrintSensorData(current_sensor.distance_cm,
                            current_sensor.temperature,
                            current_sensor.humidity);

        xil_printf("[Master] Sensor: dist=%d temp=%d hum=%d h_done=%d d_valid=%d\r\n",
                   current_sensor.distance_cm,
                   current_sensor.temperature,
                   current_sensor.humidity,
                   current_sensor.hcsr04_done,
                   current_sensor.dht11_valid);

        master_state = MASTER_STATE_SEND_SENSOR_PACKET;
        break;

    case MASTER_STATE_SEND_SENSOR_PACKET:
        status = Protocol_BuildSensorPacket(&current_sensor,
                                            sensor_packet,
                                            &sensor_packet_len);
        if (status != APP_OK) {
            xil_printf("[Master] Build sensor packet failed. status=%d\r\n", status);
            master_state = MASTER_STATE_ERROR;
            break;
        }

        


        UART2_FlushRx();

        


        status = UART2_SendBytes(sensor_packet, sensor_packet_len);
        if (status != APP_OK) {
            xil_printf("[Master] UART2 send failed. status=%d\r\n", status);
            master_state = MASTER_STATE_ERROR;
            break;
        }

        


        status = UART2_RecvBytes(result_packet,
                                 RESULT_PACKET_LEN,
                                 RESULT_PACKET_TIMEOUT_MS);
        if (status != APP_OK) {
            xil_printf("[Master] Sensor packet sent.\r\n");
            xil_printf("[Master] Result packet timeout or rx failed. status=%d\r\n", status);
            master_state = MASTER_STATE_ERROR;
            break;
        }

        


        xil_printf("[Master] RX raw: %x %x %x %x %x %x\r\n",
                   result_packet[0],
                   result_packet[1],
                   result_packet[2],
                   result_packet[3],
                   result_packet[4],
                   result_packet[5]);

        status = Protocol_ParseResultPacket(result_packet,
                                            RESULT_PACKET_LEN,
                                            &current_result);
        if (status != APP_OK) {
            xil_printf("[Master] Sensor packet sent.\r\n");
            xil_printf("[Master] Result packet parse failed. status=%d\r\n", status);
            master_state = MASTER_STATE_ERROR;
            break;
        }

        xil_printf("[Master] Sensor packet sent.\r\n");

        master_state = MASTER_STATE_PROCESS_RESULT;
        break;

    case MASTER_STATE_WAIT_RESULT_PACKET:
        status = UART2_RecvBytes(result_packet,
                                 RESULT_PACKET_LEN,
                                 RESULT_PACKET_TIMEOUT_MS);
        if (status != APP_OK) {
            xil_printf("[Master] Result packet timeout or rx failed. status=%d\r\n", status);
            master_state = MASTER_STATE_ERROR;
            break;
        }

        status = Protocol_ParseResultPacket(result_packet,
                                            RESULT_PACKET_LEN,
                                            &current_result);
        if (status != APP_OK) {
            xil_printf("[Master] Result packet parse failed. status=%d\r\n", status);
            master_state = MASTER_STATE_ERROR;
            break;
        }

        master_state = MASTER_STATE_PROCESS_RESULT;
        break;

    case MASTER_STATE_PROCESS_RESULT:
        xil_printf("[Master] Result: time=%d:%d code=0x%x\r\n",
                   current_result.minute,
                   current_result.second,
                   current_result.result_code);

        if (IS_WARNING_CODE(current_result.result_code)) {
            status = WarningLogService_Save(current_result.minute,
                                            current_result.second,
                                            current_result.result_code);

            if (status != APP_OK) {
                xil_printf("[Master] Warning log save failed. status=%d\r\n", status);
            }

            LCD_PrintMessage("Warning Result", "Log Saved");
        } else {
            LCD_PrintMessage("Normal Result", "No Warning");
        }

        MasterApp_GoIdleOrAutoRestart();
        break;

    case MASTER_STATE_LOG_DUMP:
        log_dump_request = 0;

        LCD_PrintMessage("Log Dump", "Serial Output");

        status = WarningLogService_DumpAll();
        if (status != APP_OK) {
            xil_printf("[Master] Log dump failed. status=%d\r\n", status);
        }

        master_state = MASTER_STATE_IDLE;
        LCD_PrintMessage("Master Ready", "Manual/Auto/Log");
        break;

    case MASTER_STATE_ERROR:
        LCD_PrintMessage("Master Error", "Check Serial");

        


        auto_mode = MASTER_AUTO_MODE_OFF;

        master_state = MASTER_STATE_IDLE;
        break;

    default:
        master_state = MASTER_STATE_ERROR;
        break;
    }
}


void MasterApp_StartManual(void)
{
    if (master_state != MASTER_STATE_IDLE) {
        return;
    }

    MasterApp_StartSequence();
}


void MasterApp_ToggleAuto(void)
{
    if (auto_mode == MASTER_AUTO_MODE_ON) {
        auto_mode = MASTER_AUTO_MODE_OFF;

        xil_printf("[Master] Auto mode OFF.\r\n");

        if (master_state == MASTER_STATE_IDLE) {
            LCD_PrintMessage("Auto Mode", "OFF");
        }
    } else {
        auto_mode = MASTER_AUTO_MODE_ON;

        xil_printf("[Master] Auto mode ON.\r\n");

        if (master_state == MASTER_STATE_IDLE) {
            LCD_PrintMessage("Auto Mode", "ON");
            MasterApp_StartSequence();
        }
    }
}


void MasterApp_RequestLogDump(void)
{
    log_dump_request = 1;

    if (master_state == MASTER_STATE_IDLE) {
        master_state = MASTER_STATE_LOG_DUMP;
    }
}


uint8_t MasterApp_IsBusy(void)
{
    if (master_state == MASTER_STATE_IDLE) {
        return 0;
    }

    return 1;
}


uint8_t MasterApp_IsAutoModeOn(void)

{
    return auto_mode;
}


master_app_state_t MasterApp_GetState(void)
{
    return master_state;
}
