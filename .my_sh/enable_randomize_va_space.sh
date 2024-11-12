#!/bin/bash

# Abilita la randomizzazione dell'indirizzo virtuale
echo 2 | sudo tee /proc/sys/kernel/randomize_va_space

