# SPI 및 I2C 프로토콜 설계와 UVM 검증

서로 다른 타이밍 규칙을 가진 SPI와 I2C를 RTL로 구현하고, 프로토콜별 UVM 검증 환경을 구성한 프로젝트입니다. 통신 파형의 생성부터 데이터 비교, 기능 커버리지 수집, FPGA 신호 관찰까지 하나의 검증 흐름으로 연결했습니다.

## 프로젝트 범위

| 구분 | SPI | I2C |
| --- | --- | --- |
| 데이터 단위 | 8 bit, MSB First | 7 bit 주소와 8 bit 데이터 |
| 통신 방식 | Full-Duplex, Mode 0 | Open-Drain, ACK/NACK |
| 제어 흐름 | Slave 선택과 동시 송수신 | START, WRITE, READ, STOP |
| 비교 방향 | Master TX와 Slave RX, Slave TX와 Master RX | Master Write와 Slave RX, Slave TX와 Master Read |

## 구현 핵심

### SPI

- 시스템 클럭 기준으로 SCLK, SS, MOSI를 동기화한 뒤 상승 및 하강 에지를 검출
- Mode 0 타이밍에 맞춰 MOSI를 수신하고 다음 MISO 비트를 준비
- 두 슬레이브를 선택해 Master와 양방향 8 bit 데이터를 전송

### I2C

- Master 상태 머신에서 START, 데이터, ACK, STOP을 쿼터 주기로 전개
- Slave에서 주소 `7'h20`과 R/W 비트를 판별해 송신 및 수신 경로 선택
- SDA의 Open-Drain 동작과 ACK/NACK 응답 처리

## UVM 구성

| 구성 요소 | 역할 |
| --- | --- |
| Sequence | 기본, 랜덤, 경계값, 연속 전송 시나리오 생성 |
| Driver | 프로토콜 명령과 데이터를 DUT Interface에 구동 |
| Monitor | 송수신 결과를 트랜잭션 단위로 복원 |
| Scoreboard | 양방향 데이터의 기대값과 실제값 비교 |
| Coverage | 명령, 역할, 슬레이브 선택, 데이터 구간과 조합 수집 |

## 확인 결과

| 항목 | 결과 |
| --- | ---: |
| SPI Functional Coverage | 100% |
| I2C Functional Coverage | 100% |
| Scoreboard | SPI 양방향, I2C Write 및 Read 비교 통과 |
| FPGA | Logic Analyzer로 SPI와 I2C 신호 확인 |

## 코드 위치

| 영역 | 경로 |
| --- | --- |
| SPI 및 I2C RTL | [rtl](../verification/spi-i2c-uvm/rtl/) |
| SPI 및 I2C UVM Testbench | [tb](../verification/spi-i2c-uvm/tb/) |
| 프로젝트 README | [verification/spi-i2c-uvm](../verification/spi-i2c-uvm/) |
