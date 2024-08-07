#include "XKC_KL200.h"
#include <cstring>
#include <iostream>

XKC_KL200::XKC_KL200(const char* portName) : serialPort(-1), _available(false), _distance(0), _lastReceivedDistance(0) {
    serialPort = open(portName, O_RDWR | O_NOCTTY);
    if (serialPort < 0) {
        std::cerr << "Error opening serial port" << std::endl;
    }
}

XKC_KL200::~XKC_KL200() {
    if (serialPort >= 0) {
        close(serialPort);
    }
}

bool XKC_KL200::begin(int baudRate) {
    if (serialPort < 0) {
        return false;
    }

    struct termios tty;
    memset(&tty, 0, sizeof(tty));

    if (tcgetattr(serialPort, &tty) != 0) {
        std::cerr << "Error from tcgetattr" << std::endl;
        return false;
    }

    cfsetospeed(&tty, baudRate);
    cfsetispeed(&tty, baudRate);

    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;
    tty.c_iflag &= ~IGNBRK;
    tty.c_lflag = 0;
    tty.c_oflag = 0;
    tty.c_cc[VMIN] = 0;
    tty.c_cc[VTIME] = 5;

    tty.c_iflag &= ~(IXON | IXOFF | IXANY);
    tty.c_cflag |= (CLOCAL | CREAD);
    tty.c_cflag &= ~(PARENB | PARODD);
    tty.c_cflag &= ~CSTOPB;
    tty.c_cflag &= ~CRTSCTS;

    if (tcsetattr(serialPort, TCSANOW, &tty) != 0) {
        std::cerr << "Error from tcsetattr" << std::endl;
        return false;
    }

    return true;
}

void XKC_KL200::sendCommand(const uint8_t* command, uint8_t length) {
    write(serialPort, command, length);
}

uint8_t XKC_KL200::calculateChecksum(const uint8_t* data, uint8_t length) {
    uint8_t checksum = 0;
    for (uint8_t i = 0; i < length; ++i) {
        checksum ^= data[i];
    }
    return checksum;
}

bool XKC_KL200::restoreFactorySettings(bool hardReset) {
    uint8_t resetByte = hardReset ? 0xFE : 0xFD;
    uint8_t command[] = {0x62, 0x39, 0x09, 0xFF, 0xFF, 0xFF, 0xFF, resetByte, 0x00};
    command[8] = calculateChecksum(command, 8);
    sendCommand(command, 9);
    return true;
}

bool XKC_KL200::changeAddress(uint16_t address) {
    if (address > 0xFFFE) return false;
    uint8_t command[] = {0x62, 0x32, 0x09, 0xFF, 0xFF, (uint8_t)(address >> 8), (uint8_t)address, 0x00, 0x00};
    command[8] = calculateChecksum(command, 8);
    sendCommand(command, 9);
    return true;
}

bool XKC_KL200::changeBaudRate(uint8_t baudRate) {
    if (baudRate > 9) return false;
    uint8_t command[] = {0x62, 0x30, 0x09, 0xFF, 0xFF, baudRate, 0x00, 0x00, 0x00};
    command[8] = calculateChecksum(command, 8);
    sendCommand(command, 9);
    return true;
}

bool XKC_KL200::setUploadMode(bool autoUpload) {
    uint8_t mode = autoUpload ? 1 : 0;
    uint8_t command[] = {0x62, 0x34, 0x09, 0xFF, 0xFF, mode, 0x00, 0x00, 0x00};
    command[8] = calculateChecksum(command, 8);
    sendCommand(command, 9);
    return true;
}

bool XKC_KL200::setUploadInterval(uint8_t interval) {
    if (interval < 1 || interval > 100) return false;
    uint8_t command[] = {0x62, 0x35, 0x09, 0xFF, 0xFF, interval, 0x00, 0x00, 0x00};
    command[8] = calculateChecksum(command, 8);
    sendCommand(command, 9);
    return true;
}

bool XKC_KL200::setLEDMode(uint8_t mode) {
    if (mode > 3) return false;
    uint8_t command[] = {0x62, 0x37, 0x09, 0xFF, 0xFF, mode, 0x00, 0x00, 0x00};
    command[8] = calculateChecksum(command, 8);
    sendCommand(command, 9);
    return true;
}

bool XKC_KL200::setRelayMode(uint8_t mode) {
    if (mode > 1) return false;
    uint8_t command[] = {0x62, 0x38, 0x09, 0xFF, 0xFF, mode, 0x00, 0x00, 0x00};
    command[8] = calculateChecksum(command, 8);
    sendCommand(command, 9);
    return true;
}

bool XKC_KL200::setCommunicationMode(uint8_t mode) {
    if (mode > 1) return false;
    uint8_t command[] = {0x62, 0x31, 0x09, 0xFF, 0xFF, mode, 0x00, 0x00, 0x00};
    command[8] = calculateChecksum(command, 8);
    sendCommand(command, 9);
    return true;
}

uint16_t XKC_KL200::readDistance() {
    uint8_t command[] = {0x62, 0x33, 0x09, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00};
    command[8] = calculateChecksum(command, 8);
    sendCommand(command, 9);

    uint8_t response[9];
    int bytesRead = read(serialPort, response, 9);
    if (bytesRead == 9 && response[0] == 0x62 && response[1] == 0x33) {
        uint16_t rawDistance = (response[5] << 8) | response[6];
        uint8_t checksum = response[8];
        uint8_t calcChecksum = calculateChecksum(response, 8);

        if (checksum == calcChecksum) {
            _distance = rawDistance;
            _lastReceivedDistance = rawDistance;
            _available = true;
        }
    }
    return _distance;
}

bool XKC_KL200::available() {
    return _available;
}

uint16_t XKC_KL200::getDistance() {
    _available = false;
    return _distance;
}

uint16_t XKC_KL200::getLastReceivedDistance() {
    return _lastReceivedDistance;
}

Beispielprogramm: main.cpp

cpp

#include "XKC_KL200.h"
#include <iostream>

int main() {
    XKC_KL200 sensor("/dev/ttyUSB0");

    if (!sensor.begin(B9600)) {
        std::cerr << "Failed to initialize the sensor" << std::endl;
        return 1;
    }

    sensor.setUploadMode(true);
    sensor.setUploadInterval(10);
    sensor.setLEDMode(1);
    sensor.setCommunicationMode(0); // Set to UART mode

    while (true) {
        if (sensor.available()) {
            uint16_t distance = sensor.getDistance();
            std::cout << "Distance: " << distance << " mm" << std::endl;
        }
        usleep(100000); // Sleep for 100ms
    }

    return 0;
}
