#include "FND.h"

static uint32_t s_fndNumber = 0u;
static uint32_t s_fndDPData = 0u;


static const uint8_t s_fndFont[16] = {
    0xC0u, 0xF9u, 0xA4u, 0xB0u,
    0x99u, 0x92u, 0x82u, 0xF8u,
    0x80u, 0x90u, 0x88u, 0x83u,
    0xC6u, 0xA1u, 0x86u, 0x8Eu
};

static uint8_t FND_GetDigitData(uint32_t num, uint32_t digit)
{
    switch (digit) {
    case FND_DIGIT_0: return (uint8_t)(num % 10u);
    case FND_DIGIT_1: return (uint8_t)((num / 10u) % 10u);
    case FND_DIGIT_2: return (uint8_t)((num / 100u) % 10u);
    case FND_DIGIT_3: return (uint8_t)((num / 1000u) % 10u);
    default:          return 0u;
    }
}

static uint8_t FND_MakeSegmentData(uint8_t num, uint32_t dp_on)
{
    uint8_t data;

    data = s_fndFont[num & 0x0Fu];

    
    if (dp_on) {
        data &= (uint8_t)~0x80u;
    } else {
        data |= 0x80u;
    }

    return data;
}

void FND_Init(void)
{
    uint32_t mode;

    
    mode = GPIO_GetCR(FND_GPIO);
    mode |= FND_OUTPUT_MASK;
    mode &= ~0x000Fu;
    GPIO_SetMode(FND_GPIO, mode);

    FND_DispAllOff();
}

void FND_SetNum(uint32_t num)
{
    s_fndNumber = num % 10000u;
}

void FND_SetTime(uint8_t minute, uint8_t second)
{
    uint32_t mmss;

    minute %= 60u;
    second %= 60u;

    mmss = ((uint32_t)minute * 100u) + (uint32_t)second;
    FND_SetNum(mmss);

    
    s_fndDPData = (1u << FND_DIGIT_2);
}

void FND_SetDP(uint32_t fndDigitSel, uint32_t fndDpState)
{
    if (fndDigitSel > FND_DIGIT_3) {
        return;
    }

    if (fndDpState == FND_DP_ON) {
        s_fndDPData |= (1u << fndDigitSel);
    } else {
        s_fndDPData &= ~(1u << fndDigitSel);
    }
}

static void FND_WriteSegment(uint8_t segmentData)
{
    GPIO_WriteMasked(FND_GPIO,
                     FND_DATA_MASK,
                     ((uint32_t)segmentData << FND_DATA_SHIFT));
}

static void FND_SelectDigit(uint32_t digit)
{
    uint32_t digit_bits;

    
    digit_bits = FND_DIGIT_MASK;
    digit_bits &= ~((uint32_t)(1u << digit) << FND_DIGIT_SHIFT);

    GPIO_WriteMasked(FND_GPIO, FND_DIGIT_MASK, digit_bits);
}

void FND_DispAllOff(void)
{
    
    GPIO_WriteMasked(FND_GPIO,
                     FND_OUTPUT_MASK,
                     ((uint32_t)0xFFu << FND_DATA_SHIFT) | FND_DIGIT_MASK);
}

void FND_Execute(void)
{
    static uint32_t fndDigitState = FND_DIGIT_3;
    uint8_t digitValue;
    uint8_t segmentData;

    
    fndDigitState = (fndDigitState + 1u) & 0x03u;

    digitValue = FND_GetDigitData(s_fndNumber, fndDigitState);
    segmentData = FND_MakeSegmentData(digitValue,
                                      (s_fndDPData & (1u << fndDigitState)) ? 1u : 0u);

    FND_DispAllOff();
    FND_WriteSegment(segmentData);
    FND_SelectDigit(fndDigitState);
}

void FND_Excute(void)
{
    FND_Execute();
}
