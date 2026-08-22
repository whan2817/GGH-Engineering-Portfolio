#include "EEPROM.h"

#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"


#if defined(XPAR_SPI_S00_AXI_BASEADDR)
    #define SPI_BASEADDR XPAR_SPI_S00_AXI_BASEADDR
#elif defined(XPAR_SPI_0_S00_AXI_BASEADDR)
    #define SPI_BASEADDR XPAR_SPI_0_S00_AXI_BASEADDR
#elif defined(XPAR_SPI_BASEADDR)
    #define SPI_BASEADDR XPAR_SPI_BASEADDR
#else
    #error "SPI base address macro not found. Check xparameters.h."
#endif


#define SPI_CTRL_OFFSET        0x00
#define SPI_TX_OFFSET          0x04
#define SPI_STATUS_OFFSET      0x08
#define SPI_RX_OFFSET          0x0C

#define SPI_CTRL_ADDR          (SPI_BASEADDR + SPI_CTRL_OFFSET)
#define SPI_TX_DATA_ADDR       (SPI_BASEADDR + SPI_TX_OFFSET)
#define SPI_STATUS_ADDR        (SPI_BASEADDR + SPI_STATUS_OFFSET)
#define SPI_RX_DATA_ADDR       (SPI_BASEADDR + SPI_RX_OFFSET)


#define SPI_CTRL_START_MASK        0x01
#define SPI_CTRL_CS_MANUAL_EN      0x02
#define SPI_CTRL_CS_N              0x04

#define SPI_DONE_MASK              0x01
#define SPI_BUSY_MASK              0x02

static uint32_t spi_ctrl_shadow = SPI_CTRL_CS_MANUAL_EN | SPI_CTRL_CS_N;


#define SPI_TRANSFER_TIMEOUT   100000U


static void SPI_SetCSLow(void)
{
    spi_ctrl_shadow = SPI_CTRL_CS_MANUAL_EN;
    Xil_Out32(SPI_CTRL_ADDR, spi_ctrl_shadow);

    usleep(5);
}

static void SPI_SetCSHigh(void)
{
    spi_ctrl_shadow = SPI_CTRL_CS_MANUAL_EN | SPI_CTRL_CS_N;
    Xil_Out32(SPI_CTRL_ADDR, spi_ctrl_shadow);

    usleep(5);
}

/* 한 바이트 전송이 끝날 때까지 SPI 상태를 확인하고 수신값을 반환한다. */
static int SPI_TransferByte(uint8_t tx_data, uint8_t *rx_data)
{
    uint32_t status;
    uint32_t timeout_count;

    if (rx_data == 0) {
        return APP_INVALID_ARG;
    }

    


    Xil_Out32(SPI_TX_DATA_ADDR, (uint32_t)tx_data);

    


    Xil_Out32(SPI_CTRL_ADDR, spi_ctrl_shadow | SPI_CTRL_START_MASK);
    usleep(1);
    Xil_Out32(SPI_CTRL_ADDR, spi_ctrl_shadow);
    


    timeout_count = SPI_TRANSFER_TIMEOUT;

    while (timeout_count > 0U) {
        status = Xil_In32(SPI_STATUS_ADDR);

        if ((status & SPI_DONE_MASK) && ((status & SPI_BUSY_MASK) == 0U)) {
            *rx_data = (uint8_t)(Xil_In32(SPI_RX_DATA_ADDR) & 0xFF);
            return APP_OK;
        }

        timeout_count--;
    }

    return APP_TIMEOUT;
}


void EEPROM_Init(void)
{
    SPI_SetCSHigh();
}


int EEPROM_WriteByte(uint8_t addr, uint8_t data)
{
    uint8_t dummy;
    int status;

    SPI_SetCSLow();

    status = SPI_TransferByte(EEPROM_CMD_WRITE, &dummy);
    if (status != APP_OK) {
        SPI_SetCSHigh();
        return status;
    }

    status = SPI_TransferByte(addr, &dummy);
    if (status != APP_OK) {
        SPI_SetCSHigh();
        return status;
    }

    status = SPI_TransferByte(data, &dummy);
    if (status != APP_OK) {
        SPI_SetCSHigh();
        return status;
    }

    SPI_SetCSHigh();

    return APP_OK;
}


int EEPROM_ReadByte(uint8_t addr, uint8_t *data)
{
    uint8_t dummy;
    int status;

    if (data == 0) {
        return APP_INVALID_ARG;
    }

    SPI_SetCSLow();

    status = SPI_TransferByte(EEPROM_CMD_READ, &dummy);
    if (status != APP_OK) {
        SPI_SetCSHigh();
        return status;
    }

    status = SPI_TransferByte(addr, &dummy);
    if (status != APP_OK) {
        SPI_SetCSHigh();
        return status;
    }

    


    status = SPI_TransferByte(EEPROM_DUMMY_BYTE, data);
    if (status != APP_OK) {
        SPI_SetCSHigh();
        return status;
    }

    SPI_SetCSHigh();

    return APP_OK;
}


int EEPROM_WriteBytes(uint8_t start_addr, const uint8_t *data, uint8_t len)
{
    uint8_t dummy;
    uint8_t i;
    int status;
    uint16_t end_addr;

    if (data == 0) {
        return APP_INVALID_ARG;
    }

    if (len == 0U) {
        return APP_INVALID_ARG;
    }

    end_addr = (uint16_t)start_addr + (uint16_t)len - 1U;

    if (end_addr > EEPROM_ADDR_MAX) {
        return APP_INVALID_ARG;
    }

    SPI_SetCSLow();

    status = SPI_TransferByte(EEPROM_CMD_WRITE, &dummy);
    if (status != APP_OK) {
        SPI_SetCSHigh();
        return status;
    }

    status = SPI_TransferByte(start_addr, &dummy);
    if (status != APP_OK) {
        SPI_SetCSHigh();
        return status;
    }

    for (i = 0; i < len; i++) {
        status = SPI_TransferByte(data[i], &dummy);
        if (status != APP_OK) {
            SPI_SetCSHigh();
            return status;
        }
    }

    SPI_SetCSHigh();

    return APP_OK;
}


int EEPROM_ReadBytes(uint8_t start_addr, uint8_t *data, uint8_t len)
{
    uint8_t dummy;
    uint8_t i;
    int status;
    uint16_t end_addr;

    if (data == 0) {
        return APP_INVALID_ARG;
    }

    if (len == 0U) {
        return APP_INVALID_ARG;
    }

    end_addr = (uint16_t)start_addr + (uint16_t)len - 1U;

    if (end_addr > EEPROM_ADDR_MAX) {
        return APP_INVALID_ARG;
    }

    SPI_SetCSLow();

    status = SPI_TransferByte(EEPROM_CMD_READ, &dummy);
    if (status != APP_OK) {
        SPI_SetCSHigh();
        return status;
    }

    status = SPI_TransferByte(start_addr, &dummy);
    if (status != APP_OK) {
        SPI_SetCSHigh();
        return status;
    }

    for (i = 0; i < len; i++) {
        status = SPI_TransferByte(EEPROM_DUMMY_BYTE, &data[i]);
        if (status != APP_OK) {
            SPI_SetCSHigh();
            return status;
        }
    }

    SPI_SetCSHigh();

    return APP_OK;
}
