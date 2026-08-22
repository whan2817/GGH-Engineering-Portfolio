# Embedded Firmware

Memory-Mapped Peripheral을 제어하고 시스템 동작 순서를 수행하는 FPGA Soft Processor 및 MCU Firmware를 관리합니다.

| 프로젝트 | 플랫폼 | 구현 범위 |
| --- | --- | --- |
| [MicroBlaze AXI System](microblaze-axi-system/) | MicroBlaze, Vitis | MMIO, Interrupt, Sensor Service, UART Packet, EEPROM Log |

Firmware는 HAL, Driver, Service, Application의 역할이 드러나도록 기존 디렉터리 구조를 유지합니다.
