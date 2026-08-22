# AXI4-Lite 다중 보드 센서 모니터링 SoC

MicroBlaze와 AXI4-Lite Custom Peripheral을 기반으로 센서 측정, 보드 간 통신, 경고 판정, 사용자 표시, 이벤트 저장을 하나의 시스템으로 통합한 설계 프로젝트입니다.

[통합 프로젝트 허브에서 전체 시스템 보기](../../project-hub/axi-sensor-monitoring-soc.md)

## 시스템 구성

### Master Board

- HC-SR04 거리 측정
- DHT11 온도와 습도 측정
- I2C LCD와 Serial Terminal 출력
- UART2 Sensor Packet 송신과 Result Packet 수신
- Warning Event의 SPI EEPROM 저장

### Slave0 Board

- Sensor Packet 수신
- 거리, 온도, 습도 조건 판정
- Result Packet 회신
- FND 시간 표시
- I2C LCD 경고 표시

### Slave1 Board

- SPI Mode 0 EEPROM 동작
- 0x02 Write Command
- 0x03 Read Command
- 256 Byte Memory
- 순차 읽기와 쓰기

## Custom Peripheral

| Peripheral | Master Base Address | 기능 |
| --- | --- | --- |
| AXI UART Lite | 0x4060_0000 | Serial Terminal |
| AXI INTC | 0x4120_0000 | Interrupt Control |
| DHT11 | 0x44A0_0000 | 온도와 습도 측정 |
| GPIO16 | 0x44A1_0000 | Button, LED, FND 제어 |
| HC-SR04 | 0x44A2_0000 | 거리 측정 |
| I2C | 0x44A3_0000 | LCD 제어 |
| SPI | 0x44A4_0000 | EEPROM 읽기와 쓰기 |
| Timer | 0x44A5_0000 | 2초 측정 주기 생성 |
| UART2 | 0x44A6_0000 | Master와 Slave0 Packet 통신 |

## 디렉터리

| 경로 | 내용 |
| --- | --- |
| rtl/ip | AXI4-Lite Custom Peripheral 소스와 IP 패키지 정보 |
| tb | 설계와 연결된 검증 프로젝트 안내 |
| bd/master | Master MicroBlaze Block Design |
| bd/slave0 | Slave0 MicroBlaze Block Design |
| constraints/master | Master Board 핀 제약 |
| constraints/slave0 | Slave0 Board 핀 제약 |

## 개발 환경

- Vivado 2020.2
- Vitis 2020.2
- Basys3
- Artix-7 XC7A35T
- System Clock 100 MHz
