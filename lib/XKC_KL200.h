#ifndef XKC_KL200_H
#define XKC_KL200_H

#include <cstdint>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>

class XKC_KL200 {
public:
    XKC_KL200(const char* portName);
    ~XKC_KL200();

    bool begin(int baudRate);
    bool restoreFactorySettings(bool hardReset = true);
    bool changeAddress(uint16_t address);
    bool changeBaudRate(uint8_t baudRate);
    bool setUploadMode(bool autoUpload);
    bool setUploadInterval(uint8_t interval);
    bool setLEDMode(uint8_t mode);
    bool setRelayMode(uint8_t mode);
    bool setCommunicationMode(uint8_t mode);
    uint16_t readDistance();

    bool available();
    uint16_t getDistance();
    uint16_t getLastReceivedDistance();

private:
    int serialPort;
    bool _available;
    uint16_t _distance;
    uint16_t _lastReceivedDistance;

    void sendCommand(const uint8_t* command, uint8_t length);
    uint8_t calculateChecksum(const uint8_t* data, uint8_t length);
};

#endif
