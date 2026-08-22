#include "DHT11.h"

#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"


#if defined(XPAR_DHT11_0_S00_AXI_BASEADDR)
    #define DHT11_BASEADDR XPAR_DHT11_0_S00_AXI_BASEADDR
#elif defined(XPAR_DHT11_S00_AXI_BASEADDR)
    #define DHT11_BASEADDR XPAR_DHT11_S00_AXI_BASEADDR
#elif defined(XPAR_DHT11_BASEADDR)
    #define DHT11_BASEADDR XPAR_DHT11_BASEADDR
#else
    #error "DHT11 base address macro not found. Check xparameters.h."
#endif


#define DHT11_CTRL_OFFSET           0x00
#define DHT11_HUMIDITY_OFFSET       0x04
#define DHT11_TEMPERATURE_OFFSET    0x08
#define DHT11_VALID_OFFSET          0x0C

#define DHT11_CTRL_ADDR             (DHT11_BASEADDR + DHT11_CTRL_OFFSET)
#define DHT11_HUMIDITY_ADDR         (DHT11_BASEADDR + DHT11_HUMIDITY_OFFSET)
#define DHT11_TEMPERATURE_ADDR      (DHT11_BASEADDR + DHT11_TEMPERATURE_OFFSET)
#define DHT11_VALID_ADDR            (DHT11_BASEADDR + DHT11_VALID_OFFSET)


void DHT11_Init(void)
{
    Xil_Out32(DHT11_CTRL_ADDR, 0x00);
}


void DHT11_Start(void)
{
    Xil_Out32(DHT11_CTRL_ADDR, DHT11_START_MASK);
    usleep(1);
    Xil_Out32(DHT11_CTRL_ADDR, 0x00);
}


uint8_t DHT11_IsValid(void)
{
    uint32_t valid;

    valid = Xil_In32(DHT11_VALID_ADDR);

    if (valid & DHT11_VALID_MASK) {
        return 1;
    }

    return 0;
}


uint8_t DHT11_GetTemperature(void)
{
    return (uint8_t)(Xil_In32(DHT11_TEMPERATURE_ADDR) & 0xFF);
}


uint8_t DHT11_GetHumidity(void)
{
    return (uint8_t)(Xil_In32(DHT11_HUMIDITY_ADDR) & 0xFF);
}


int DHT11_ReadData(uint8_t *temperature,
                   uint8_t *humidity,
                   uint32_t timeout_ms)
{
    uint32_t elapsed_ms;

    if ((temperature == 0) || (humidity == 0)) {
        return APP_INVALID_ARG;
    }

    DHT11_Start();

    elapsed_ms = 0;

    while (elapsed_ms < timeout_ms) {
        if (DHT11_IsValid()) {
            *temperature = DHT11_GetTemperature();
            *humidity    = DHT11_GetHumidity();

            return APP_OK;
        }

        usleep(1000);
        elapsed_ms++;
    }

    return APP_TIMEOUT;
}
