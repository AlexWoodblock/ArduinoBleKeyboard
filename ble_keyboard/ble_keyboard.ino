#include <mbed.h>
#include <USBKeyboard.h>
#include <ArduinoBLE.h>

#define REPORT_ID_KEYBOARD 1

#define KEY_CODE_MASK 0xFFFF
#define KEY_MODIFIER_MASK (0xFFFF << 16)

#define RED_LED 22

#define MESSAGES_SERVICE_UUID "98AD"
#define MESSAGE_TX_CHARACTERISTIC "98AF"

#define DEVICE_NAME "Virtual Keyboard"

#define CONNECT_POLL_INTERVAL 500
#define CONNECTED_POLL_INTERVAL 1

#define CHARACTERISTIC_LENGTH 32

USBKeyboard key;

BLEService messagesService(MESSAGES_SERVICE_UUID);

BLECharacteristic messageTxCharacteristic(
  MESSAGE_TX_CHARACTERISTIC,
  BLEWriteWithoutResponse,
  CHARACTERISTIC_LENGTH,
  true
);

int main() {
  setupBle();

  while (true) {
    // TODO: add LED blinking to signal we're still alive
    // TODO: maybe we should use timeout?
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
  digitalWrite(RED_LED, LOW);
  BLE.stopAdvertise();
}

void onBleDisconnected(BLEDevice device) {
  digitalWrite(RED_LED, HIGH);
  BLE.advertise();
}

void onTxCharacteristicUpdated(BLEDevice device, BLECharacteristic txCharacteristic) {
  const uint8_t* value = txCharacteristic.value();
  
  // unprotected reads FTW! Let that buffer overflow
  uint16_t keyCode = value[1] | value[0] << 8;
  uint16_t keyModifier = value[3] | value[2] << 8;
  sendKeyCode(keyCode, keyModifier);
}

void setupBle() {
  if (!BLE.begin()) {
    while (true);
  }

  BLE.setDeviceName(DEVICE_NAME);
  BLE.setLocalName(DEVICE_NAME);

  messagesService.addCharacteristic(messageTxCharacteristic);

  BLE.setAdvertisedService(messagesService);
  BLE.addService(messagesService);

  BLE.setConnectable(true);

  BLE.setEventHandler(BLEConnected, onBleConnected);
  BLE.setEventHandler(BLEDisconnected, onBleDisconnected);

  messageTxCharacteristic.setEventHandler(BLEWritten, onTxCharacteristicUpdated);

  BLE.advertise();
}