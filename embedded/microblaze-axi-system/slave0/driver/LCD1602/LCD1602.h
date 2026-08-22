#ifndef SRC_DRIVER_LCD1602_LCD1602_H_
#define SRC_DRIVER_LCD1602_LCD1602_H_

#include <stdint.h>
#include "../../HAL/I2C/I2C.h"


#ifndef LCD1602_I2C_ADDR
#define LCD1602_I2C_ADDR 0x27u
#endif


#define LCD1602_PIN_RS       0x01u
#define LCD1602_PIN_RW       0x02u
#define LCD1602_PIN_EN       0x04u
#define LCD1602_PIN_BL       0x08u


#ifndef LCD1602_BACKLIGHT_ACTIVE_LOW
#define LCD1602_BACKLIGHT_ACTIVE_LOW 0u
#endif

#if LCD1602_BACKLIGHT_ACTIVE_LOW
#define LCD1602_BACKLIGHT_ON_MASK   0x00u
#define LCD1602_BACKLIGHT_OFF_MASK  LCD1602_PIN_BL
#else
#define LCD1602_BACKLIGHT_ON_MASK   LCD1602_PIN_BL
#define LCD1602_BACKLIGHT_OFF_MASK  0x00u
#endif

#define LCD1602_CMD_CLEAR            0x01u
#define LCD1602_CMD_HOME             0x02u
#define LCD1602_CMD_ENTRY_MODE       0x06u
#define LCD1602_CMD_DISPLAY_OFF      0x08u
#define LCD1602_CMD_DISPLAY_ON       0x0Cu
#define LCD1602_CMD_FUNCTION_SET     0x28u
#define LCD1602_CMD_SET_DDRAM        0x80u

void LCD1602_Init(void);
void LCD1602_BacklightOn(void);
void LCD1602_BacklightOff(void);
void LCD1602_Clear(void);
void LCD1602_SetCursor(uint8_t row, uint8_t col);
void LCD1602_WriteChar(char ch);
void LCD1602_WriteString(const char *str);
void LCD1602_WriteStringPadded(const char *str, uint8_t width);
void LCD1602_PrintWarning(uint8_t code, uint8_t minute, uint8_t second, const char *warning_name);

#endif 
