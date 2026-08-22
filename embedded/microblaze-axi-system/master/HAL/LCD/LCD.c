#include "LCD.h"

#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"


#if defined(XPAR_I2C_S00_AXI_BASEADDR)
    #define I2C_BASEADDR XPAR_I2C_S00_AXI_BASEADDR
#elif defined(XPAR_I2C_0_S00_AXI_BASEADDR)
    #define I2C_BASEADDR XPAR_I2C_0_S00_AXI_BASEADDR
#elif defined(XPAR_I2C_BASEADDR)
    #define I2C_BASEADDR XPAR_I2C_BASEADDR
#else
    #error "I2C base address macro not found. Check xparameters.h."
#endif


#define I2C_CTRL_OFFSET           0x00
#define I2C_DATA_OFFSET           0x04
#define I2C_RX_DATA_OFFSET        0x08
#define I2C_DONE_OFFSET           0x0C

#define I2C_CTRL_ADDR             (I2C_BASEADDR + I2C_CTRL_OFFSET)
#define I2C_DATA_ADDR             (I2C_BASEADDR + I2C_DATA_OFFSET)
#define I2C_RX_DATA_ADDR          (I2C_BASEADDR + I2C_RX_DATA_OFFSET)
#define I2C_DONE_ADDR             (I2C_BASEADDR + I2C_DONE_OFFSET)

#define I2C_WRITE_TRIGGER         0x01


#define LCD_BACKLIGHT             0x08
#define LCD_ENABLE                0x04
#define LCD_RS                    0x01


static void LCD_I2C_WriteFrame(uint8_t i2c_addr, uint16_t tx_wdata)
{
    uint32_t packet;

    packet = (((uint32_t)i2c_addr & 0x7F) << 16) |
             ((uint32_t)tx_wdata & 0xFFFF);

    Xil_Out32(I2C_DATA_ADDR, packet);
    Xil_Out32(I2C_CTRL_ADDR, I2C_WRITE_TRIGGER);

    


    usleep(3000);
}


static void LCD_SendByte(uint8_t data, uint8_t rs)
{
    uint8_t high_nibble;
    uint8_t low_nibble;
    uint8_t ctrl_en;
    uint8_t ctrl_no_en;
    uint16_t frame;

    high_nibble = (data >> 4) & 0x0F;
    low_nibble  = data & 0x0F;

    if (rs) {
        ctrl_en    = LCD_BACKLIGHT | LCD_ENABLE | LCD_RS;
        ctrl_no_en = LCD_BACKLIGHT | LCD_RS;
    } else {
        ctrl_en    = LCD_BACKLIGHT | LCD_ENABLE;
        ctrl_no_en = LCD_BACKLIGHT;
    }

    frame = ((uint16_t)high_nibble << 12) |
            ((uint16_t)low_nibble  << 8)  |
            ((uint16_t)ctrl_en     << 4)  |
            ((uint16_t)ctrl_no_en);

    LCD_I2C_WriteFrame(LCD_I2C_ADDR, frame);
}


static void LCD_UintTo3Digit(uint16_t value, char *buf)
{
    if (value > 999U) {
        value = 999U;
    }

    buf[0] = (char)('0' + ((value / 100U) % 10U));
    buf[1] = (char)('0' + ((value / 10U)  % 10U));
    buf[2] = (char)('0' + (value % 10U));
    buf[3] = '\0';
}


static void LCD_UintTo2Digit(uint8_t value, char *buf)
{
    if (value > 99U) {
        value = 99U;
    }

    buf[0] = (char)('0' + ((value / 10U) % 10U));
    buf[1] = (char)('0' + (value % 10U));
    buf[2] = '\0';
}


void LCD_Init(void)
{
    usleep(50000);

    LCD_SendCommand(0x33);
    usleep(5000);

    LCD_SendCommand(0x32);
    usleep(5000);

    LCD_SendCommand(LCD_CMD_FUNCTION_SET_4BIT);
    usleep(3000);

    LCD_SendCommand(LCD_CMD_DISPLAY_ON);
    usleep(3000);

    LCD_SendCommand(LCD_CMD_ENTRY_MODE);
    usleep(3000);

    LCD_Clear();
}


void LCD_SendCommand(uint8_t command)
{
    LCD_SendByte(command, 0);

    if ((command == LCD_CMD_CLEAR) || (command == LCD_CMD_RETURN_HOME)) {
        usleep(LCD_CLEAR_DELAY_MS * 1000U);
    } else {
        usleep(LCD_CMD_DELAY_US);
    }
}


void LCD_SendData(uint8_t data)
{
    LCD_SendByte(data, 1);
    usleep(LCD_CMD_DELAY_US);
}


void LCD_Clear(void)
{
    LCD_SendCommand(LCD_CMD_CLEAR);
    usleep(5000);
}


void LCD_SetCursor(uint8_t row, uint8_t col)
{
    uint8_t address;

    if (row >= LCD_ROW_COUNT) {
        row = 0;
    }

    if (col >= LCD_COL_COUNT) {
        col = 0;
    }

    if (row == LCD_LINE_1) {
        address = 0x80 + col;
    } else {
        address = 0xC0 + col;
    }

    LCD_SendCommand(address);
}


void LCD_Print(const char *str)
{
    uint8_t i;

    if (str == 0) {
        return;
    }

    i = 0;

    while ((str[i] != '\0') && (i < LCD_COL_COUNT)) {
        LCD_SendData((uint8_t)str[i]);
        i++;
    }
}


void LCD_PrintLine(uint8_t row, const char *str)
{
    uint8_t i;

    LCD_SetCursor(row, 0);

    i = 0;

    if (str != 0) {
        while ((str[i] != '\0') && (i < LCD_COL_COUNT)) {
            LCD_SendData((uint8_t)str[i]);
            i++;
        }
    }

    while (i < LCD_COL_COUNT) {
        LCD_SendData(' ');
        i++;
    }
}


void LCD_PrintSensorData(uint16_t distance_cm,
                         uint8_t temperature,
                         uint8_t humidity)
{
    char dist_buf[4];
    char temp_buf[3];
    char humid_buf[3];

    char line1[17];
    char line2[17];

    LCD_UintTo3Digit(distance_cm, dist_buf);
    LCD_UintTo2Digit(temperature, temp_buf);
    LCD_UintTo2Digit(humidity, humid_buf);

    


    line1[0]  = 'd';
    line1[1]  = 'i';
    line1[2]  = 's';
    line1[3]  = 't';
    line1[4]  = ' ';
    line1[5]  = '=';
    line1[6]  = ' ';
    line1[7]  = dist_buf[0];
    line1[8]  = dist_buf[1];
    line1[9]  = dist_buf[2];
    line1[10] = 'c';
    line1[11] = 'm';
    line1[12] = '\0';

    


    line2[0]  = 't';
    line2[1]  = 'e';
    line2[2]  = 'm';
    line2[3]  = 'p';
    line2[4]  = '=';
    line2[5]  = temp_buf[0];
    line2[6]  = temp_buf[1];
    line2[7]  = '/';
    line2[8]  = 'h';
    line2[9]  = 'u';
    line2[10] = 'm';
    line2[11] = 'i';
    line2[12] = 'd';
    line2[13] = '=';
    line2[14] = humid_buf[0];
    line2[15] = humid_buf[1];
    line2[16] = '\0';

    LCD_PrintLine(LCD_LINE_1, line1);
    LCD_PrintLine(LCD_LINE_2, line2);
}


void LCD_PrintMessage(const char *line1, const char *line2)
{
    LCD_PrintLine(LCD_LINE_1, line1);
    LCD_PrintLine(LCD_LINE_2, line2);
}
