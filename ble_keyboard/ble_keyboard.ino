#include <mbed.h>
#include <USBKeyboard.h>
#include <ArduinoBLE.h>
#include <nrf_rtc.h>

// HID
#define REPORT_ID_KEYBOARD 1

// BLE data protocol
#define KEY_CODE_MASK 0xFFFF
#define KEY_MODIFIER_MASK (0xFFFF << 16)
#define MESSAGES_SERVICE_UUID "98AD"
#define MESSAGE_RX_CHARACTERISTIC "98AF"
#define DEVICE_NAME "Virtual Keyboard"
#define CHARACTERISTIC_LENGTH 32

// Custom LED declarations
#define RED_LED 22

// Keyboard declaration
USBKeyboard key;

// BLE definitions
BLEService messagesService(MESSAGES_SERVICE_UUID);

BLECharacteristic messageRxCharacteristic(
  MESSAGE_RX_CHARACTERISTIC,
  BLEWriteWithoutResponse,
  CHARACTERISTIC_LENGTH,
  true
);

int main() {
  fixBootloader();
  
  if (!setupBle()) {
    return -1;
  }

  while (true) {
    BLE.poll();
  }

  return 0;
}

void sendKeyCode(uint16_t keyCode, uint16_t keyModifier) {
  // we need to send raw report, since there's no API to provide
  // raw HID input - only input for characters, which we don't need
  HID_REPORT report;

  // report pressed button
  report.data[0] = REPORT_ID_KEYBOARD;
  report.data[1] = keyModifier;
  report.data[2] = 0;
  report.data[3] = keyCode;
  report.data[4] = 0;
  report.data[5] = 0;
  report.data[6] = 0;
  report.data[7] = 0;
  report.data[8] = 0;

  report.length = 9;

  key.send(&report);

  // depress the button
  report.data[1] = 0;
  report.data[3] = 0;

  key.send(&report);
}

void onBleConnected(BLEDevice device) {
  BLE.stopAdvertise();
  digitalWrite(RED_LED, LOW);
}

void onBleDisconnected(BLEDevice device) {
  BLE.advertise();
  digitalWrite(RED_LED, HIGH);
}

void onRxCharacteristicUpdated(BLEDevice device, BLECharacteristic rxCharacteristic) {
  const uint8_t* value = rxCharacteristic.value();
  
  // unprotected reads FTW! Let that buffer overflow
  uint16_t keyCode = value[1] | value[0] << 8;
  uint16_t keyModifier = value[3] | value[2] << 8;
  sendKeyCode(keyCode, keyModifier);
}

bool setupBle() {
  if (!BLE.begin()) {
    return false;
  }

  BLE.setDeviceName(DEVICE_NAME);
  BLE.setLocalName(DEVICE_NAME);

  messagesService.addCharacteristic(messageRxCharacteristic);

  BLE.setAdvertisedService(messagesService);
  BLE.addService(messagesService);

  BLE.setConnectable(true);

  BLE.setEventHandler(BLEConnected, onBleConnected);
  BLE.setEventHandler(BLEDisconnected, onBleDisconnected);

  messageRxCharacteristic.setEventHandler(BLEWritten, onRxCharacteristicUpdated);

  BLE.advertise();

  return true;
}

void fixBootloader() {
  // This code fixes the device hanging after approximately 8 minutes and 40 seconds, see
  // https://github.com/ARMmbed/mbed-os/issues/15307

  // turn power LED on
  pinMode(LED_PWR, OUTPUT);
  digitalWrite(LED_PWR, HIGH);

  // Errata Nano33BLE - I2C pullup is controlled by the SWO pin.
  // Configure the TRACEMUX to disable routing SWO signal to pin.
  NRF_CLOCK->TRACECONFIG = 0;

  // FIXME: bootloader enables interrupt on COMPARE[0], which we don't handle
  // Disable it here to avoid getting stuck when OVERFLOW irq is triggered
  nrf_rtc_event_disable(NRF_RTC1, NRF_RTC_INT_COMPARE0_MASK);
  nrf_rtc_int_disable(NRF_RTC1, NRF_RTC_INT_COMPARE0_MASK);

  // FIXME: always enable I2C pullup and power @startup
  // Change for maximum powersave
  pinMode(PIN_ENABLE_SENSORS_3V3, OUTPUT);
  pinMode(PIN_ENABLE_I2C_PULLUP, OUTPUT);

  digitalWrite(PIN_ENABLE_SENSORS_3V3, HIGH);
  digitalWrite(PIN_ENABLE_I2C_PULLUP, HIGH);

  // Disable UARTE0 which is initially enabled by the bootloader
  nrf_uarte_task_trigger(NRF_UARTE0, NRF_UARTE_TASK_STOPRX); 
  while (!nrf_uarte_event_check(NRF_UARTE0, NRF_UARTE_EVENT_RXTO)) ; 
  NRF_UARTE0->ENABLE = 0; 
  NRF_UART0->ENABLE = 0; 

  NRF_PWM_Type* PWM[] = {
    NRF_PWM0, NRF_PWM1, NRF_PWM2
#ifdef NRF_PWM3
    ,NRF_PWM3
#endif
  };

  for (unsigned int i = 0; i < (sizeof(PWM)/sizeof(PWM[0])); i++) {
    PWM[i]->ENABLE = 0;
    PWM[i]->PSEL.OUT[0] = 0xFFFFFFFFUL;
  } 
}