# Hardware Design

합성 가능한 RTL, AXI4-Lite Custom IP, Vivado Block Design, FPGA Constraint를 관리합니다.

| 프로젝트 | 설계 범위 | 코드 |
| --- | --- | --- |
| AXI Sensor Monitoring SoC | Sensor Interface, GPIO, I2C, SPI, Timer, UART2, MicroBlaze Integration | [소스 보기](axi-sensor-monitoring-soc/) |
| SPI EEPROM Emulator | SPI Mode 0 Command 처리, 256 Byte Memory, Sequential Transfer | [소스 보기](spi-eeprom-emulator/) |

각 프로젝트는 `rtl`과 `tb`를 구분하며 Block Design과 Constraint는 설계 프로젝트 내부에서 별도로 관리합니다.
