#include "Button.h"

#include "xparameters.h"
#include "../../HAL/GPIO/GPIO.h"


#if defined(XPAR_GPIOB_S00_AXI_BASEADDR)
    #define BUTTON_GPIO_BASEADDR XPAR_GPIOB_S00_AXI_BASEADDR
#elif defined(XPAR_BUTTON_GPIO_S00_AXI_BASEADDR)
    #define BUTTON_GPIO_BASEADDR XPAR_BUTTON_GPIO_S00_AXI_BASEADDR
#elif defined(XPAR_GPIO_BUTTON_S00_AXI_BASEADDR)
    #define BUTTON_GPIO_BASEADDR XPAR_GPIO_BUTTON_S00_AXI_BASEADDR
#elif defined(XPAR_GPIO_1_S00_AXI_BASEADDR)
    #define BUTTON_GPIO_BASEADDR XPAR_GPIO_1_S00_AXI_BASEADDR
#elif defined(XPAR_GPIO_0_S00_AXI_BASEADDR)
    #define BUTTON_GPIO_BASEADDR XPAR_GPIO_0_S00_AXI_BASEADDR
#elif defined(XPAR_GPIO_S00_AXI_BASEADDR)
    #define BUTTON_GPIO_BASEADDR XPAR_GPIO_S00_AXI_BASEADDR
#elif defined(XPAR_GPIO_GPIO_BASEADDR)
    #define BUTTON_GPIO_BASEADDR XPAR_GPIO_GPIO_BASEADDR
#else
    #error "Button GPIO base address macro not found. Check xparameters.h."
#endif


static uint8_t button_prev_state = 0;
static uint8_t button_curr_state = 0;
static uint8_t button_event_flag = BUTTON_EVENT_NONE;


static uint8_t Button_PinToMask(uint8_t pin)
{
    return (uint8_t)(1U << pin);
}


static uint8_t Button_NormalizePressed(uint8_t raw_level)
{
#if (BUTTON_ACTIVE_LEVEL == 1)
    return raw_level ? 1U : 0U;
#else
    return raw_level ? 0U : 1U;
#endif
}


static uint8_t Button_ReadRawState(void)
{
    uint8_t raw_port;
    uint8_t state;

    raw_port = GPIO_ReadInputPort(BUTTON_GPIO_BASEADDR);

    state = 0;

    if (Button_NormalizePressed((raw_port >> BUTTON_MANUAL_PIN) & 0x01U)) {
        state |= BUTTON_EVENT_MANUAL;
    }

    if (Button_NormalizePressed((raw_port >> BUTTON_AUTO_PIN) & 0x01U)) {
        state |= BUTTON_EVENT_AUTO;
    }

    if (Button_NormalizePressed((raw_port >> BUTTON_LOG_PIN) & 0x01U)) {
        state |= BUTTON_EVENT_LOG;
    }

    return state;
}


void Button_Init(void)
{
    GPIO_SetMode(BUTTON_GPIO_BASEADDR, 0x00);

    button_prev_state = Button_ReadRawState();
    button_curr_state = button_prev_state;
    button_event_flag = BUTTON_EVENT_NONE;
}


void Button_Update(void)
{
    uint8_t rising_edge;

    button_curr_state = Button_ReadRawState();

    rising_edge = (uint8_t)((~button_prev_state) & button_curr_state);

    button_event_flag |= rising_edge;

    button_prev_state = button_curr_state;
}


uint8_t Button_GetEvent(void)
{
    return button_event_flag;
}


void Button_ClearEvent(uint8_t event_mask)
{
    button_event_flag &= (uint8_t)(~event_mask);
}


uint8_t Button_IsManualPressed(void)
{
    if (button_curr_state & BUTTON_EVENT_MANUAL) {
        return 1;
    }

    return 0;
}


uint8_t Button_IsAutoPressed(void)
{
    if (button_curr_state & BUTTON_EVENT_AUTO) {
        return 1;
    }

    return 0;
}


uint8_t Button_IsLogPressed(void)
{
    if (button_curr_state & BUTTON_EVENT_LOG) {
        return 1;
    }

    return 0;
}
