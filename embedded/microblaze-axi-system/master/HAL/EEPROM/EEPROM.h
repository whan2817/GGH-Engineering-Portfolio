#ifndef SRC_HAL_EEPROM_EEPROM_H_
#define SRC_HAL_EEPROM_EEPROM_H_

#include <stdint.h>
#include "../../common/types/app_types.h"


#define EEPROM_ADDR_MIN        0x00
#define EEPROM_ADDR_MAX        0xFF
#define EEPROM_SIZE_BYTES      256


#define EEPROM_CMD_WRITE       0x02
#define EEPROM_CMD_READ        0x03
#define EEPROM_DUMMY_BYTE      0x00


void EEPROM_Init(void);

int EEPROM_WriteByte(uint8_t addr, uint8_t data);
int EEPROM_ReadByte(uint8_t addr, uint8_t *data);

int EEPROM_WriteBytes(uint8_t start_addr, const uint8_t *data, uint8_t len);
int EEPROM_ReadBytes(uint8_t start_addr, uint8_t *data, uint8_t len);

#endif 
