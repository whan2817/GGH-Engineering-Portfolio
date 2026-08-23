# Hardware Design

합성 가능한 RTL, AXI4-Lite Custom IP, Vivado Block Design, FPGA Constraint를 관리합니다.

| 프로젝트 | 설계 범위 | 코드 |
| --- | --- | --- |
| RV32I Single-Cycle CPU | RV32I 명령어 Decode, Datapath, Memory, 프로그램 실행 | [소스 보기](rv32i-single-cycle-cpu/) |
| AXI Sensor Monitoring SoC | Sensor Interface, GPIO, I2C, SPI, Timer, UART2, MicroBlaze Integration | [소스 보기](axi-sensor-monitoring-soc/) |
| SPI EEPROM Emulator | SPI Mode 0 Command 처리, 256 Byte Memory, Sequential Transfer | [소스 보기](spi-eeprom-emulator/) |

설계 소스는 `rtl`, 별도 Testbench가 있는 프로젝트는 `tb`로 구분하며 Block Design과 Constraint는 프로젝트 내부에서 별도로 관리합니다.
