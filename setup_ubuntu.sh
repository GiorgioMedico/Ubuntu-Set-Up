#!/bin/bash

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Check per i permessi di root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}${BOLD}Errore: Questo script deve essere eseguito come root (con sudo)${NC}"
    exit 1
fi

# Array dei pacchetti
UTILS=(
    git
    git-lfs
    make
    cmake
    python3-dev
    clang
    clang-format
    clang-tidy
    python3-pip
    python3-venv
    terminator
    vim-tiny
    curl
    wget
    net-tools
    htop
    unzip
    doxygen
    graphviz
)

LATEX_PACKAGES=(
    texlive-base
    texlive-binaries
    texlive-fonts-recommended
    texlive-lang-english
    texlive-lang-italian
    texlive-lang-greek
    texlive-latex-base
    texlive-latex-extra
    texlive-latex-recommended
    texlive-pictures
    texlive-plain-generic
    texlive-science
)

# Funzione per mostrare banner
show_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════╗"
    echo "║         Ubuntu Setup Assistant           ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Funzione per mostrare messaggi di stato
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Funzione per mostrare progresso
show_progress() {
    local duration=$1
    local progress=0
    local bar_width=40

    while [ $progress -le 100 ]; do
        local bar=""
        local filled=$((progress * bar_width / 100))
        local empty=$((bar_width - filled))
        
        # Costruisci la barra
        for ((i=0; i<filled; i++)); do bar+="█"; done
        for ((i=0; i<empty; i++)); do bar+="░"; done
        
        # Mostra la barra
        echo -ne "\r${CYAN}Progress: [${bar}] ${progress}%${NC}"
        
        progress=$((progress + 2))
        sleep $duration
    done
    echo
}

# Funzione per verificare se un pacchetto è installato
is_package_installed() {
    if dpkg -l | grep -q "^ii  $1 "; then
        return 0
    else
        return 1
    fi
}

# Funzione per verificare se un comando esiste
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Funzione per installare pacchetti di utilità
install_utils() {
    print_status "Controllo pacchetti di utilità..."
    local packages_to_install=()
    
    for package in "${UTILS[@]}"; do
        if ! is_package_installed "$package"; then
            packages_to_install+=("$package")
        else
            print_success "$package è già installato"
        fi
    done
    
    if [ ${#packages_to_install[@]} -eq 0 ]; then
        print_success "Tutti i pacchetti di utilità sono già installati!"
        return
    fi
    
    print_status "Installazione dei pacchetti mancanti..."
    apt update
    for package in "${packages_to_install[@]}"; do
        print_status "Installazione $package..."
        if apt install -y "$package"; then
            print_success "$package installato con successo"
        else
            print_error "Errore nell'installazione di $package"
        fi
    done
}

# Funzione per installare pacchetti LaTeX
install_latex() {
    print_status "Controllo pacchetti LaTeX..."
    local packages_to_install=()
    
    for package in "${LATEX_PACKAGES[@]}"; do
        if ! is_package_installed "$package"; then
            packages_to_install+=("$package")
        else
            print_success "$package è già installato"
        fi
    done
    
    if [ ${#packages_to_install[@]} -eq 0 ]; then
        print_success "Tutti i pacchetti LaTeX sono già installati!"
        return
    fi
    
    print_status "Installazione dei pacchetti LaTeX mancanti..."
    apt update
    for package in "${packages_to_install[@]}"; do
        print_status "Installazione $package..."
        if apt install -y "$package"; then
            print_success "$package installato con successo"
            show_progress 0.01
        else
            print_error "Errore nell'installazione di $package"
        fi
    done
}

# Funzione per installare VSCode
install_vscode() {
    if command_exists code; then
        print_success "Visual Studio Code è già installato!"
        return
    fi
    
    print_status "Installazione Visual Studio Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    apt update
    if apt install -y code; then
        print_success "Visual Studio Code installato con successo"
        show_progress 0.05
    else
        print_error "Errore nell'installazione di Visual Studio Code"
    fi
    rm packages.microsoft.gpg
}

# Funzione per installare Miniconda
install_miniconda() {
    REAL_USER=$(logname || echo $SUDO_USER)
    MINICONDA_PATH="/home/$REAL_USER/miniconda3"
    
    if [ -d "$MINICONDA_PATH" ]; then
        print_success "Miniconda è già installato in $MINICONDA_PATH"
        return
    fi
    
    print_status "Installazione Miniconda..."
    
    # Crea directory e scarica l'installer come utente reale
    su - $REAL_USER -c "
        mkdir -p ~/miniconda3
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
        bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
        rm ~/miniconda3/miniconda.sh
    "
    
    # Attiva, inizializza conda e configura per non attivarsi automaticamente
    su - $REAL_USER -c "
        source ~/miniconda3/bin/activate
        conda init --all
        conda config --set auto_activate_base false
    "
    
    print_success "Miniconda installato con successo"
    print_warning "Per completare l'installazione, chiudi e riapri il terminale o esegui: source ~/.bashrc"
    show_progress 0.05
}

# Funzione per installare ROS2
install_ros2() {
    if [ -d "/opt/ros/humble" ]; then
        print_success "ROS2 Humble è già installato!"
        return
    fi
    
    print_status "Installazione ROS2 Humble..."
    
    # Locale setup
    apt update && apt install -y locales
    locale-gen en_US en_US.UTF-8
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    export LANG=en_US.UTF-8
    
    print_status "Configurazione repository ROS2..."
    apt install -y software-properties-common
    add-apt-repository universe
    
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null
    
    print_status "Installazione ROS2 Humble Desktop..."
    apt update
    if apt install -y ros-humble-desktop ros-dev-tools; then
        print_success "ROS2 Humble installato con successo"
        show_progress 0.05
    else
        print_error "Errore nell'installazione di ROS2 Humble"
        return
    fi
    
    # Aggiungi setup al .bashrc dell'utente reale
    REAL_USER=$(logname || echo $SUDO_USER)
    su - $REAL_USER -c "echo 'source /opt/ros/humble/setup.bash' >> ~/.bashrc"
}

# Funzione per configurare Git
configure_git() {
    REAL_USER=$(logname || echo $SUDO_USER)
    if [ -f "/home/$REAL_USER/.gitconfig" ]; then
        print_warning "Git è già configurato. Vuoi riconfigurarlo? [y/N]"
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    print_status "Configurazione Git..."
    
    # Esegui la configurazione come utente reale
    su - $REAL_USER -c "
        echo -e '${MAGENTA}Configurazione Git${NC}'
        read -p 'Inserisci il tuo nome per Git: ' git_name
        read -p 'Inserisci la tua email per Git: ' git_email
        git config --global user.name \"\$git_name\"
        git config --global user.email \"\$git_email\"
        git config --global init.defaultBranch main
        git config --global color.ui auto
    "
    
    # Genera una chiave SSH se non esiste
    if [ ! -f "/home/$REAL_USER/.ssh/id_rsa" ]; then
        print_status "Generazione chiave SSH..."
        su - $REAL_USER -c "ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ''"
        print_success "Chiave SSH generata con successo"
        print_status "La tua chiave pubblica SSH è:"
        su - $REAL_USER -c "cat ~/.ssh/id_rsa.pub"
    else
        print_success "Chiave SSH già presente"
    fi
}

# Funzione per aggiornare il sistema
update_system() {
    print_status "Aggiornamento del sistema..."
    if apt update && apt upgrade -y; then
        print_success "Sistema aggiornato con successo"
        show_progress 0.05
    else
        print_error "Errore durante l'aggiornamento del sistema"
    fi
}

# Menu principale con interfaccia migliorata
main() {
    clear
    show_banner
    echo -e "${CYAN}${BOLD}Menu Principale${NC}"
    echo -e "${BLUE}─────────────────────────${NC}"
    echo -e "${CYAN}1)${NC} Installa tutto"
    echo -e "${CYAN}2)${NC} Aggiorna sistema"
    echo -e "${CYAN}3)${NC} Installa utilità"
    echo -e "${CYAN}4)${NC} Installa LaTeX"
    echo -e "${CYAN}5)${NC} Installa VSCode"
    echo -e "${CYAN}6)${NC} Installa Miniconda"
    echo -e "${CYAN}7)${NC} Installa ROS2"
    echo -e "${CYAN}8)${NC} Configura Git"
    echo -e "${CYAN}0)${NC} Esci"
    echo -e "${BLUE}─────────────────────────${NC}"
    
    read -p "$(echo -e ${CYAN}Inserisci la tua scelta: ${NC})" choice
    
    case $choice in
        1)
            update_system
            install_utils
            install_latex
            install_vscode
            install_miniconda
            install_ros2
            configure_git
            ;;
        2)
            update_system
            ;;
        3)
            install_utils
            ;;
        4)
            install_latex
            ;;
        5)
            install_vscode
            ;;
        6)
            install_miniconda
            ;;
        7)
            install_ros2
            ;;
        8)
            configure_git
            ;;
        0)
            echo -e "${GREEN}Arrivederci!${NC}"
            exit 0
            ;;
        *)
            print_error "Scelta non valida"
            sleep 2
            main
            ;;
    esac
    
    echo -e "\n${GREEN}Operazione completata! Premi INVIO per tornare al menu principale${NC}"
    read
    main
}

# Esegui il menu principale
main