# Verification

SystemVerilog/UVM 기반 검증 환경과 검증 대상 RTL을 프로젝트 단위로 관리합니다.

| 프로젝트 | 검증 범위 | 환경 |
| --- | --- | --- |
| [AXI GPIO UVM](axi-gpio-uvm/) | AXI Read/Write, GPIO Input/Output, Register와 DUT 결과 비교 | Sequence, Driver, Monitor, Scoreboard, Coverage |
| [SPI 및 I2C UVM](spi-i2c-uvm/) | SPI 양방향 송수신, I2C Write/Read, 경계값과 랜덤 시나리오 | UVM 1.2, Scoreboard, Functional Coverage |

검증 프로젝트 내부에서 DUT는 `rtl`, UVM Testbench는 `tb`로 분리합니다.
