#include "Slave0.h"
#include "../../HAL/UART2/UART2.h"
#include "../../driver/LCD1602/LCD1602.h"
#include "xil_printf.h"

static Slave0Status_t g_slave0_status;
static uint8_t g_rx_buffer[SLAVE0_RX_BUFFER_SIZE];
static uint8_t g_rx_index = 0u;

static void Slave0_ProcessReceivedByte(uint8_t rx_data);
static void Slave0_ProcessCompletedPacket(void);
static void Slave0_SendResultPacket(uint8_t result_code);
static void Slave0_DisplayWarning(uint8_t result_code, uint8_t minute, uint8_t second);
static void Slave0_PrintMasterRxLog(const Slave0SensorPacket_t *sensor, uint8_t result_code);

void Slave0_ResetParser(void)
{
    uint8_t i;

    for (i = 0u; i < SLAVE0_RX_BUFFER_SIZE; i++) {
        g_rx_buffer[i] = 0u;
    }

    g_rx_index = 0u;
}

void Slave0_Init(void)
{
    g_slave0_status.packet_ok_count    = 0u;
    g_slave0_status.packet_error_count = 0u;
    g_slave0_status.result_sent_count  = 0u;
    g_slave0_status.warning_count      = 0u;

    g_slave0_status.last_sensor.distance_cm = 0u;
    g_slave0_status.last_sensor.temperature = 0u;
    g_slave0_status.last_sensor.humidity    = 0u;

    g_slave0_status.last_minute      = 0u;
    g_slave0_status.last_second      = 0u;
    g_slave0_status.last_result_code = SLAVE0_WARNING_NORMAL;

    Slave0_ResetParser();
    Slave0Warning_Init();
    Slave0Time_Init();

    UART2_Init();
    UART2_FlushRx();

#if SLAVE0_DEBUG_PRINT_ENABLE
    xil_printf("[Slave0] Init done.\r\n");
#endif
}

void Slave0_Execute(void)
{
    uint8_t rx_data;
    int recv_status;
    uint8_t guard_count;

    
    guard_count = 0u;

    while (guard_count < 16u) {
        recv_status = UART2_RecvByte(&rx_data, 0u);

        if (recv_status != UART2_OK) {
            break;
        }

        Slave0_ProcessReceivedByte(rx_data);
        guard_count++;
    }
}

/* 시작 바이트와 패킷 형식을 기준으로 수신 바이트를 프레임으로 조립한다. */
static void Slave0_ProcessReceivedByte(uint8_t rx_data)
{
    if (g_rx_index == 0u) {
        if (rx_data == SLAVE0_START_BYTE) {
            g_rx_buffer[0] = rx_data;
            g_rx_index = 1u;
        }
        return;
    }

    if (g_rx_index == SLAVE0_SENSOR_TYPE_IDX) {
        if (rx_data != SLAVE0_TYPE_SENSOR) {
            g_slave0_status.packet_error_count++;
            Slave0_ResetParser();

            if (rx_data == SLAVE0_START_BYTE) {
                g_rx_buffer[0] = rx_data;
                g_rx_index = 1u;
            }
            return;
        }
    }

    if (g_rx_index >= SLAVE0_RX_BUFFER_SIZE) {
        g_slave0_status.packet_error_count++;
        Slave0_ResetParser();
        return;
    }

    g_rx_buffer[g_rx_index] = rx_data;
    g_rx_index++;

    if (g_rx_index >= SLAVE0_SENSOR_PACKET_LEN) {
        Slave0_ProcessCompletedPacket();
        Slave0_ResetParser();
    }
}

static void Slave0_ProcessCompletedPacket(void)
{
    Slave0SensorPacket_t sensor;
    uint8_t result_code;
    int parse_ok;

    parse_ok = Slave0_ParseSensorPacket(g_rx_buffer, &sensor);

    if (parse_ok == 0) {
        g_slave0_status.packet_error_count++;

        
        Slave0_SendResultPacket(SLAVE0_WARNING_SENSOR_ERROR);

#if SLAVE0_DEBUG_PRINT_ENABLE
        xil_printf("[Slave0] Packet parse failed. SENSOR_ERROR sent.\r\n");
#endif
        return;
    }

    g_slave0_status.packet_ok_count++;
    g_slave0_status.last_sensor = sensor;

    result_code = Slave0Warning_Evaluate(&sensor);

    
    Slave0_SendResultPacket(result_code);

    


    Slave0_PrintMasterRxLog(&sensor, result_code);

}

/* 경고 판정 결과와 현재 시간을 응답 패킷으로 구성해 Master에 전송한다. */
static void Slave0_SendResultPacket(uint8_t result_code)
{
    Slave0ResultPacket_t result;
    uint8_t result_raw[SLAVE0_RESULT_PACKET_LEN];
    int send_status;

    Slave0Time_GetTime(&result.minute, &result.second);
    result.result_code = result_code;

    Slave0_BuildResultPacket(&result, result_raw);

    send_status = UART2_SendBytes(result_raw, SLAVE0_RESULT_PACKET_LEN);

    g_slave0_status.last_minute      = result.minute;
    g_slave0_status.last_second      = result.second;
    g_slave0_status.last_result_code = result.result_code;

    if (send_status == UART2_OK) {
        g_slave0_status.result_sent_count++;
    } else {
        g_slave0_status.packet_error_count++;
#if SLAVE0_DEBUG_PRINT_ENABLE
        xil_printf("[Slave0] Result send failed. status=%d\r\n", send_status);
#endif
    }

    if (SLAVE0_IS_WARNING_CODE(result_code)) {
        g_slave0_status.warning_count++;
        Slave0_DisplayWarning(result_code, result.minute, result.second);
    }
}

static void Slave0_PrintMasterRxLog(const Slave0SensorPacket_t *sensor, uint8_t result_code)
{
#if SLAVE0_MASTER_RX_LOG_ENABLE
    if (sensor == 0) {
        return;
    }

    


    xil_printf("[MASTER RX] dist=%dcm temp=%d humid=%d result=0x%x %s time=%d:%d\r\n",
               (int)sensor->distance_cm,
               (int)sensor->temperature,
               (int)sensor->humidity,
               (unsigned int)result_code,
               Slave0Warning_CodeToString(result_code),
               (int)g_slave0_status.last_minute,
               (int)g_slave0_status.last_second);

    xil_printf("[MAIN] alive. ok=%lu err=%lu sent=%lu warn=%lu\r\n",
               (unsigned long)g_slave0_status.packet_ok_count,
               (unsigned long)g_slave0_status.packet_error_count,
               (unsigned long)g_slave0_status.result_sent_count,
               (unsigned long)g_slave0_status.warning_count);
#else
    (void)sensor;
    (void)result_code;
#endif
}

static void Slave0_DisplayWarning(uint8_t result_code, uint8_t minute, uint8_t second)
{
    
    LCD1602_BacklightOn();
    LCD1602_PrintWarning(result_code,
                         minute,
                         second,
                         Slave0Warning_CodeToString(result_code));
}

void Slave0_GetStatus(Slave0Status_t *status)
{
    if (status == 0) {
        return;
    }

    *status = g_slave0_status;
}

uint32_t Slave0_GetPacketOkCount(void)
{
    return g_slave0_status.packet_ok_count;
}

uint32_t Slave0_GetPacketErrorCount(void)
{
    return g_slave0_status.packet_error_count;
}

uint32_t Slave0_GetResultSentCount(void)
{
    return g_slave0_status.result_sent_count;
}

uint32_t Slave0_GetWarningCount(void)
{
    return g_slave0_status.warning_count;
}
