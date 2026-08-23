# RV32I Single-Cycle CPU 설계와 프로그램 실행

RISC-V RV32I 명령어 형식을 직접 해석하는 Control Unit과 명령어 실행에 필요한 Datapath를 설계하고, Instruction Memory와 Data Memory를 연결해 하나의 CPU 시스템으로 구성한 프로젝트입니다.

## 설계 목표

- 32 bit RV32I 기본 정수 명령어 실행
- Instruction Fetch부터 Write Back까지 한 클럭에 처리
- Register, Immediate, Memory, Branch, Jump 경로 통합
- C 프로그램을 Machine Code로 변환해 실제 명령어 흐름 확인

## CPU 구조

| 영역 | 처리 내용 |
| --- | --- |
| Instruction Memory | PC를 Word 인덱스로 변환해 32 bit 명령어 출력 |
| Control Unit | opcode, funct3, funct7을 해석해 제어 신호 생성 |
| Datapath | Register File, Immediate 확장, ALU, Write Back 처리 |
| Program Counter | PC + 4, Branch Target, JAL, JALR 주소 선택 |
| Data Memory | Byte 주소를 Word 인덱스와 내부 Offset으로 분리 |

## 검증 범위

| 명령어 분류 | 확인 내용 |
| --- | --- |
| R-Type과 I-Type | 산술, 논리, 비교, Shift와 Register Write Back |
| Load와 Store | Byte, Half-Word, Word 접근과 부호 및 0 확장 |
| Branch | signed와 unsigned 조건 비교 및 PC 갱신 |
| LUI와 AUIPC | 상위 Immediate 생성과 PC 상대 연산 |
| JAL과 JALR | Jump, 복귀 주소 저장, 함수 호출과 복귀 |

## 프로그램 단위 결과

### Adder

반복문에서 1부터 10까지의 값을 누적하고 함수를 호출한 뒤 복귀하는 흐름을 실행했습니다. 최종적으로 `sum = 55`와 `a = 0x12345678`이 Data Memory에 저장된 것을 확인했습니다.

### Bubble Sort

초기 배열 `{3, 5, 9, 1, 7}`을 비교하고 Swap 함수를 실행해 최종 배열 `{1, 3, 5, 7, 9}`가 저장된 것을 확인했습니다.

## 코드 위치

| 영역 | 경로 |
| --- | --- |
| 프로젝트 README | [RV32I Single-Cycle CPU](../hardware-design/rv32i-single-cycle-cpu/) |
| RTL과 Machine Code | [rtl](../hardware-design/rv32i-single-cycle-cpu/rtl/) |
