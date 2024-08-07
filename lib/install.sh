#!/bin/bash

# Install script for XKC_KL200 library

echo "Compiling and installing XKC_KL200 library..."

# Compile and install the library
make clean
make
sudo make install

if [ $? -eq 0 ]; then
    echo "XKC_KL200 library installed successfully."
else
    echo "Failed to install XKC_KL200 library."
    exit 1
fi

echo "Cleaning up..."
make clean

echo "Installation completed."
