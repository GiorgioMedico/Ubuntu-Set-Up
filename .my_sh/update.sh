#!/bin/bash

# Definizione dei colori e stili
BOLD='\e[1m'
RESET='\e[0m'
GREEN='\e[32m'
BLUE='\e[34m'
YELLOW='\e[33m'
RED='\e[31m'
CYAN='\e[36m'

# Funzione per stampare una linea di separazione
print_line() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# Verifica se lo script è eseguito con privilegi di root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}${BOLD}⚠️  Per favore esegui lo script con sudo${RESET}"
    exit 1
fi

print_line
echo -e "${BOLD}${GREEN}🚀 AGGIORNAMENTO DEL SISTEMA UBUNTU${RESET}"
print_line

echo -e "\n${BOLD}${CYAN}📥 FASE 1: Aggiornamento della lista dei pacchetti...${RESET}"
apt update

echo -e "\n${BOLD}${CYAN}⬆️  FASE 2: Installazione degli aggiornamenti...${RESET}"
apt upgrade -y

echo -e "\n${BOLD}${CYAN}🔍 FASE 3: Installazione aggiornamenti di sicurezza...${RESET}"
apt dist-upgrade -y

echo -e "\n${BOLD}${CYAN}🧹 FASE 4: Pulizia del sistema...${RESET}"
echo -e "${YELLOW}Rimozione pacchetti non necessari...${RESET}"
apt autoremove -y
echo -e "${YELLOW}Pulizia della cache di apt...${RESET}"
apt clean
echo -e "${YELLOW}Rimozione pacchetti .deb scaricati...${RESET}"
apt autoclean

print_line
echo -e "${BOLD}${GREEN}✅ OPERAZIONI COMPLETATE CON SUCCESSO!${RESET}"
echo -e "${BOLD}${GREEN}🎉 Il sistema è stato aggiornato e pulito${RESET}"
print_line
