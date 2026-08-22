# AXI GPIO UVM Verification

AXI4-Lite GPIO RTL을 대상으로 Read, Write, GPIO Input, GPIO Output 동작을 검증하는 UVM 프로젝트입니다.

[통합 프로젝트 허브에서 전체 시스템 보기](../../project-hub/axi-sensor-monitoring-soc.md)

## 검증 구조

| 구성 요소 | 역할 |
| --- | --- |
| Sequence | Reset, AXI 전송, GPIO 입출력 시나리오 생성 |
| Sequencer | Sequence Item 전달 |
| Driver | AXI와 GPIO Interface 구동 |
| Monitor | DUT Interface 신호 수집 |
| Scoreboard | 기준 레지스터 값과 DUT 결과 비교 |
| Coverage | 명령, 주소, 데이터, WSTRB, AXI Channel 조합 수집 |
| Report | 검증 결과 요약 출력 |

## 디렉터리

| 경로 | 내용 |
| --- | --- |
| rtl | AXI Master와 AXI GPIO Slave RTL |
| tb | UVM Testbench, Interface, Package, Top |

## 검증 결과

프로젝트 수행 당시 기록한 결과입니다.

| 검증 항목 | 결과 |
| --- | ---: |
| AXI Read Transaction | 1,265 |
| AXI Write Transaction | 1,255 |
| GPIO I/O Comparison | 2,556 |
| Scoreboard Check | 3,821 |
| Pass | 3,821 |
| Fail | 0 |
| Functional Coverage | 100% |
