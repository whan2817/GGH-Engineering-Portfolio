# UART, FIFO, ASCII Decoder SystemVerilog 검증

UART RX/TX, FIFO, ASCII Decoder를 개별 검증한 뒤 두 가지 통합 구조로 확장해 모듈 간 데이터 전달과 제어 신호 타이밍을 확인한 프로젝트입니다. SystemVerilog class를 이용해 입력 생성, DUT 구동, 출력 수집, 기대값 비교를 독립된 구성 요소로 분리했습니다.

## 프로젝트 범위

| 구분 | 검증 대상 | 핵심 비교 |
| --- | --- | --- |
| 개별 | UART RX | UART 입력 데이터와 `rx_data` |
| 개별 | UART TX | `tx_data`와 TX Frame 복원 데이터 |
| 개별 | FIFO | Queue 기대값과 `pop_data` |
| 개별 | ASCII Decoder | 입력 문자별 기대 `button_sel` |
| 통합 | UART + FIFO Loopback | RX 입력 데이터와 최종 TX 복원 데이터 |
| 통합 | UART RX + FIFO + ASCII Decoder | 입력 명령별 기대값과 최종 `button_sel` |

## 구현 핵심

- 100 MHz 시스템 클럭에서 9,600 bps UART를 위한 16배 오버샘플링 Tick 생성
- UART Frame을 Start bit, 8 bit 데이터, Stop bit 순서로 구동하고 LSB First로 복원
- Queue를 FIFO 참조 모델로 사용해 유효한 Pop 데이터의 순서 비교
- D/L/M/R/S/U 대소문자를 6 bit one-hot 제어 신호로 변환
- Mailbox로 Transaction을 전달하고 Event로 다음 입력 생성 시점 동기화
- UART 출력의 하강 에지를 Start bit로 감지해 각 비트 중앙값 수집

## 확인 결과

| 항목 | 결과 |
| --- | ---: |
| UART RX 개별 검증 | Pass |
| UART TX 개별 검증 | Pass |
| FIFO 개별 검증 | Pass |
| ASCII Decoder 개별 검증 | Pass |
| UART + FIFO Loopback 통합 검증 | Pass |
| UART RX + FIFO + ASCII Decoder 통합 검증 | Pass |

## 코드 위치

| 영역 | 경로 |
| --- | --- |
| 개별 RTL | [rtl/unit](../verification/uart-fifo-ascii-sv/rtl/unit/) |
| 통합 RTL | [rtl/integration](../verification/uart-fifo-ascii-sv/rtl/integration/) |
| 개별 Testbench | [tb/unit](../verification/uart-fifo-ascii-sv/tb/unit/) |
| 통합 Testbench | [tb/integration](../verification/uart-fifo-ascii-sv/tb/integration/) |
| 프로젝트 README | [verification/uart-fifo-ascii-sv](../verification/uart-fifo-ascii-sv/) |

