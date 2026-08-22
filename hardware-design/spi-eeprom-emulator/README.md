# SPI EEPROM Emulator

FPGA 내부 256 Byte Memory를 SPI Mode 0 방식으로 읽고 쓰는 EEPROM Emulator입니다. Master Board의 SPI Peripheral과 연동하여 Warning Event Log 저장 장치로 사용합니다.

[통합 프로젝트 허브에서 전체 시스템 보기](../../project-hub/axi-sensor-monitoring-soc.md)

## 통신 형식

### Write

| 순서 | 값 |
| --- | --- |
| 1 | Command 0x02 |
| 2 | Start Address |
| 3 이후 | Write Data |

### Read

| 순서 | 값 |
| --- | --- |
| 1 | Command 0x03 |
| 2 | Start Address |
| 3 이후 | Dummy 전송과 MISO Data 수신 |

## 디렉터리

| 경로 | 내용 |
| --- | --- |
| rtl/spi_eeprom_emulator.v | SPI 명령 해석과 Memory 읽기, 쓰기 |
| rtl/spi_eeprom_top.v | 보드 연결용 Top Module |
| tb/tb_spi_eeprom.v | 단일 읽기, 단일 쓰기, 순차 전송 테스트 |

## 테스트 항목

- 초기 Memory Read
- 단일 Byte Write와 Read Back
- 여러 Byte Sequential Write
- 여러 Byte Sequential Read
