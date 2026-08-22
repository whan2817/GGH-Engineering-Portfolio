# AXI Peripheral System Firmware

Custom Peripheral의 Memory-Mapped Register를 제어하고 센서 측정부터 경고 결과 저장까지의 시스템 동작을 수행하는 MicroBlaze C Firmware입니다.

[통합 프로젝트 허브에서 전체 시스템 보기](../../project-hub/axi-sensor-monitoring-soc.md)

## Master Firmware

### 계층 구조

| 계층 | 주요 역할 |
| --- | --- |
| HAL | Timer, UART2, HC-SR04, DHT11, LCD, EEPROM, GPIO Register 접근 |
| Driver | Button 입력 처리 |
| Service | 센서 측정, Packet 생성, Warning Log 관리 |
| Application | Manual, Auto, Log Mode 상태 제어 |

### Application 흐름

1. 센서 측정 시작
2. Timer Interrupt 대기
3. 거리, 온도, 습도 결과 확인
4. Sensor Packet 생성과 송신
5. Result Packet 수신과 검증
6. 경고 발생 시 EEPROM Log 저장

## Slave0 Firmware

### 주요 기능

- UART2 Sensor Packet 수신
- XOR Checksum 확인
- 거리, 온도, 습도 조건 판정
- 동일 조건 3회 연속 시 경고 확정
- Result Packet 생성과 송신
- FND에 MM.SS 시간 표시
- I2C LCD에 경고 결과 표시

## Packet 형식

### Sensor Packet

AA | 10 | DIST_H | DIST_L | TEMP | HUMID | XOR

### Result Packet

AA | 20 | MINUTE | SECOND | RESULT_CODE | XOR

## Warning Log

EEPROM의 0x10부터 0xFF 영역에 5 Byte Record를 순환 방식으로 저장합니다.

| Byte | 내용 |
| --- | --- |
| 0 | Sequence |
| 1 | Minute |
| 2 | Second |
| 3 | Warning Code |
| 4 | Checksum |

최대 48개 Record를 유지하며 저장 공간이 가득 차면 오래된 Record부터 덮어씁니다.
