#ifndef SRC_HAL_LCD_LCD_H_
#define SRC_HAL_LCD_LCD_H_

#include <stdint.h>
#include "../../common/types/app_types.h"


#define LCD_I2C_ADDR              0x27


#define LCD_ROW_COUNT             2
#define LCD_COL_COUNT             16

#define LCD_LINE_1                0
#define LCD_LINE_2                1


#define LCD_RS_BIT                0x01
#define LCD_RW_BIT                0x02
#define LCD_EN_BIT                0x04
#define LCD_BACKLIGHT_BIT         0x08


#define LCD_CMD_CLEAR             0x01
#define LCD_CMD_RETURN_HOME       0x02

#define LCD_CMD_ENTRY_MODE        0x06
#define LCD_CMD_DISPLAY_ON        0x0C
#define LCD_CMD_DISPLAY_OFF       0x08

#define LCD_CMD_FUNCTION_SET_4BIT 0x28
#define LCD_CMD_SET_DDRAM_ADDR    0x80


#define LCD_INIT_DELAY_MS         50U
#define LCD_CMD_DELAY_US          50U
#define LCD_CLEAR_DELAY_MS        2U


void LCD_Init(void);

void LCD_SendCommand(uint8_t command);
void LCD_SendData(uint8_t data);

void LCD_Clear(void);
void LCD_SetCursor(uint8_t row, uint8_t col);

void LCD_Print(const char *str);
void LCD_PrintLine(uint8_t row, const char *str);

void LCD_PrintSensorData(uint16_t distance_cm,
                         uint8_t temperature,
                         uint8_t humidity);

void LCD_PrintMessage(const char *line1, const char *line2);


#endif 
