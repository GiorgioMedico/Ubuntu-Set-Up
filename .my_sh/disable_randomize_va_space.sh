#!/bin/bash

# Disabilita la randomizzazione dell'indirizzo virtuale
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space

