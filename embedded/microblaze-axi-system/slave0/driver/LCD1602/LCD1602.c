#include "LCD1602.h"
#include "../../common/delay/delay.h"

static uint8_t s_backlight = LCD1602_BACKLIGHT_ON_MASK;

static char LCD1602_HexDigit(uint8_t value)
{
    value &= 0x0Fu;
    if (value < 10u) {
        return (char)('0' + value);
    }
    return (char)('A' + (value - 10u));
}

static uint16_t LCD1602_PackByte(uint8_t data, uint8_t rs)
{
    uint8_t high_nibble;
    uint8_t low_nibble;
    uint8_t ctrl_en;
    uint8_t ctrl_no_en;

    high_nibble = (uint8_t)((data >> 4) & 0x0Fu);
    low_nibble  = (uint8_t)(data & 0x0Fu);

    ctrl_no_en = (uint8_t)(s_backlight | (rs ? LCD1602_PIN_RS : 0u));
    ctrl_en    = (uint8_t)(ctrl_no_en | LCD1602_PIN_EN);

    


    return (uint16_t)(((uint16_t)high_nibble << 12) |
                      ((uint16_t)low_nibble  << 8)  |
                      ((uint16_t)(ctrl_en & 0x0Fu) << 4) |
                      ((uint16_t)(ctrl_no_en & 0x0Fu)));
}

static void LCD1602_SendByte(uint8_t data, uint8_t rs)
{
    uint16_t packed;

    packed = LCD1602_PackByte(data, rs);
    I2C_Write4BytesPacked(I2C0, LCD1602_I2C_ADDR, packed);
}

static void LCD1602_SendCommand(uint8_t cmd)
{
    LCD1602_SendByte(cmd, 0u);

    if ((cmd == LCD1602_CMD_CLEAR) || (cmd == LCD1602_CMD_HOME)) {
        delay_ms(2u);
    }
}

static void LCD1602_SendData(uint8_t data)
{
    LCD1602_SendByte(data, 1u);
}

void LCD1602_BacklightOn(void)
{
    s_backlight = LCD1602_BACKLIGHT_ON_MASK;

    

    LCD1602_SendCommand(LCD1602_CMD_DISPLAY_ON);
}

void LCD1602_BacklightOff(void)
{
    s_backlight = LCD1602_BACKLIGHT_OFF_MASK;

    

    LCD1602_SendCommand(LCD1602_CMD_DISPLAY_ON);
}

void LCD1602_Init(void)
{
    
    s_backlight = LCD1602_BACKLIGHT_ON_MASK;

    
    delay_ms(50u);

    
    LCD1602_SendCommand(0x33u);
    delay_ms(5u);
    LCD1602_SendCommand(0x32u);
    delay_ms(5u);

    LCD1602_SendCommand(LCD1602_CMD_FUNCTION_SET); 
    LCD1602_SendCommand(LCD1602_CMD_DISPLAY_OFF);
    LCD1602_Clear();
    LCD1602_SendCommand(LCD1602_CMD_ENTRY_MODE);
    LCD1602_SendCommand(LCD1602_CMD_DISPLAY_ON);

    
    LCD1602_BacklightOn();
}

void LCD1602_Clear(void)
{
    LCD1602_SendCommand(LCD1602_CMD_CLEAR);
}

void LCD1602_SetCursor(uint8_t row, uint8_t col)
{
    uint8_t addr;

    if (row > 1u) {
        row = 1u;
    }
    if (col > 15u) {
        col = 15u;
    }

    addr = (row == 0u) ? col : (uint8_t)(0x40u + col);
    LCD1602_SendCommand((uint8_t)(LCD1602_CMD_SET_DDRAM | addr));
}

void LCD1602_WriteChar(char ch)
{
    LCD1602_SendData((uint8_t)ch);
}

void LCD1602_WriteString(const char *str)
{
    while ((str != 0) && (*str != '\0')) {
        LCD1602_WriteChar(*str);
        str++;
    }
}

void LCD1602_WriteStringPadded(const char *str, uint8_t width)
{
    uint8_t count = 0u;

    while ((str != 0) && (*str != '\0') && (count < width)) {
        LCD1602_WriteChar(*str);
        str++;
        count++;
    }

    while (count < width) {
        LCD1602_WriteChar(' ');
        count++;
    }
}

void LCD1602_PrintWarning(uint8_t code, uint8_t minute, uint8_t second, const char *warning_name)
{
    char line1[17];
    char line2[17];

    
    line1[0]  = 'W';
    line1[1]  = 'A';
    line1[2]  = 'R';
    line1[3]  = 'N';
    line1[4]  = ' ';
    line1[5]  = 'C';
    line1[6]  = 'O';
    line1[7]  = 'D';
    line1[8]  = 'E';
    line1[9]  = ':';
    line1[10] = '0';
    line1[11] = 'x';
    line1[12] = LCD1602_HexDigit((uint8_t)(code >> 4));
    line1[13] = LCD1602_HexDigit(code);
    line1[14] = ' ';
    line1[15] = ' ';
    line1[16] = '\0';

    line2[0] = (char)('0' + ((minute / 10u) % 10u));
    line2[1] = (char)('0' + (minute % 10u));
    line2[2] = ':';
    line2[3] = (char)('0' + ((second / 10u) % 10u));
    line2[4] = (char)('0' + (second % 10u));
    line2[5] = ' ';
    line2[6] = '\0';

    LCD1602_SetCursor(0u, 0u);
    LCD1602_WriteStringPadded(line1, 16u);

    LCD1602_SetCursor(1u, 0u);
    LCD1602_WriteStringPadded(line2, 6u);
    LCD1602_WriteStringPadded(warning_name, 10u);
}
