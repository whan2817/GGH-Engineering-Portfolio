# GGH Engineering Portfolio

디지털 회로와 SoC를 설계하고 검증한 코드, FPGA에서 실행한 임베디드 펌웨어, On-Device AI 프로젝트를 한 저장소에서 관리합니다.

현재 저장소에는 MicroBlaze 기반 AXI4-Lite 다중 보드 센서 모니터링 시스템의 설계 코드와 UVM 검증 환경, 펌웨어를 정리했습니다.

## 저장소 구성

| 구분 | 내용 |
| --- | --- |
| [프로젝트 설명](project-hub/) | 시스템 구성, 구현 내용, 검증 결과와 관련 코드 위치 |
| [하드웨어 설계](hardware-design/) | Verilog/SystemVerilog RTL, AXI4-Lite Custom IP, Block Design, Constraint |
| [검증](verification/) | SystemVerilog/UVM Testbench, Scoreboard, Functional Coverage |
| [임베디드](embedded/) | MicroBlaze C Firmware, HAL, Driver, Service, Application |
| [On-Device AI](ondevice-ai/) | Jetson과 TensorRT 기반 프로젝트 |

## AXI4-Lite 다중 보드 센서 모니터링 SoC

Master Board, Slave0 Board, Slave1 Board를 연결해 센서 측정부터 경고 판정, 화면 출력, EEPROM 이벤트 저장까지 수행하도록 구성했습니다.

```mermaid
flowchart LR
    M["Master Board\n센서 측정과 이벤트 저장"]
    S0["Slave0 Board\n경고 판정과 화면 출력"]
    S1["Slave1 Board\nSPI EEPROM"]
    M <-->|"UART Packet"| S0
    M -->|"SPI Mode 0"| S1
```

### 구현 내용

- HC-SR04 거리와 DHT11 온습도 측정
- AXI4-Lite 기반 GPIO16, I2C, SPI, Timer, UART2 Custom Peripheral 구성
- UART Packet을 이용한 Master와 Slave0 간 센서 데이터 및 판정 결과 전송
- SPI EEPROM에 경고 이벤트를 5 Byte Record로 순환 저장
- MicroBlaze Firmware를 HAL, Driver, Service, Application 계층으로 구성
- AXI GPIO를 대상으로 UVM 검증 환경 구성

자세한 시스템 설명과 코드 위치는 [프로젝트 설명](project-hub/axi-sensor-monitoring-soc.md)에서 확인할 수 있습니다.

### 검증 결과

프로젝트 수행 당시 기록한 AXI GPIO UVM 검증 결과입니다.

| 항목 | 결과 |
| --- | ---: |
| Scoreboard Check | 3,821 |
| Pass | 3,821 |
| Fail | 0 |
| Functional Coverage | 100% |

## 사용 기술

| 구분 | 기술 |
| --- | --- |
| Digital Design | Verilog, SystemVerilog, FSM, AXI4-Lite, UART, SPI, I2C |
| FPGA | Basys3, Artix-7 XC7A35T, Vivado 2020.2, MicroBlaze |
| Verification | UVM, Scoreboard, Functional Coverage |
| Embedded | C, Vitis 2020.2, MMIO, Interrupt |
| On-Device AI | Jetson, Computer Vision, TensorRT |

## 코드 관리 기준

- RTL과 Testbench는 `rtl`, `tb` 폴더로 구분합니다.
- Vivado, Vitis, Simulator가 생성하는 Cache와 Build 파일은 저장하지 않습니다.
- 코드 로직과 기존 작성 스타일은 유지하고 필요한 부분에만 설명용 한국어 주석을 작성합니다.
- 프로젝트를 추가할 때 시스템 설명 문서와 관련 코드 경로를 함께 연결합니다.
