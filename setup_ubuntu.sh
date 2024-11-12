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
    
    print_success "Installazione utilità completata"
    show_progress 0.05
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
        else
            print_error "Errore nell'installazione di $package"
        fi
    done
    
    print_success "Installazione LaTeX completata"
    show_progress 0.05
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
    if [ -d "/opt/ros/jazzy" ]; then
        print_success "ROS2 Jazzy è già installato!"
        return
    fi

    print_status "Installazione ROS2 Jazzy..."
    
    # Verifica e setup locale
    print_status "Configurazione locale..."
    locale  # Verifica iniziale UTF-8
    apt update && apt install -y locales
    locale-gen en_US en_US.UTF-8
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    export LANG=en_US.UTF-8
    locale  # Verifica configurazione

    # Installazione prerequisiti
    print_status "Installazione prerequisiti..."
    apt install -y software-properties-common
    add-apt-repository universe

    # Configurazione repository ROS2
    print_status "Configurazione repository ROS2..."
    apt update && apt install -y curl
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

    # Installazione ros-dev-tools
    print_status "Installazione ROS development tools..."
    apt update && apt install -y ros-dev-tools

    # Aggiornamento sistema
    print_status "Aggiornamento sistema..."
    apt update && apt upgrade -y

    # Installazione ROS2 Jazzy
    print_status "Installazione ROS2 Jazzy Desktop..."
    if apt install -y ros-jazzy-desktop; then
        print_success "ROS2 Jazzy installato con successo"
    else
        print_error "Errore nell'installazione di ROS2 Jazzy"
        return
    fi

    # Configurazione ambiente
    REAL_USER=$(logname || echo $SUDO_USER)
    print_status "Configurazione ambiente per l'utente $REAL_USER..."
    
    # Aggiungi source al .bashrc dell'utente
    su - $REAL_USER -c "echo 'source /opt/ros/jazzy/setup.bash' >> ~/.bashrc"
    
    print_success "Configurazione ROS2 Jazzy completata"
    print_warning "Per completare l'installazione, chiudi e riapri il terminale o esegui: source ~/.bashrc"
    show_progress 0.05
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
    
    print_success "Git configurato con successo"
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

# Function to install Docker and Docker Compose
install_docker() {
    if command_exists docker && command_exists docker-compose; then
        print_success "Docker e Docker Compose sono già installati!"
        return
    fi

    print_status "Installazione Docker e Docker Compose..."

    # Remove old versions if present
    print_status "Rimozione versioni precedenti..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        apt-get remove -y $pkg || true
    done

    # Install prerequisites
    print_status "Installazione prerequisiti..."
    apt-get update
    apt-get install -y ca-certificates curl

    # Add Docker's official GPG key
    print_status "Aggiunta della chiave GPG di Docker..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources
    print_status "Configurazione repository Docker..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine and Docker Compose
    print_status "Installazione Docker Engine e Docker Compose..."
    apt-get update
    if apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        print_success "Docker installato con successo"
    else
        print_error "Errore nell'installazione di Docker"
        return
    fi

    # Add user to docker group
    REAL_USER=$(logname || echo $SUDO_USER)
    print_status "Aggiunta dell'utente $REAL_USER al gruppo docker..."
    usermod -aG docker $REAL_USER

    # Test Docker installation
    print_status "Verifica installazione Docker..."
    if docker run --rm hello-world > /dev/null 2>&1; then
        print_success "Test Docker completato con successo"
    else
        print_warning "Test Docker fallito. Potrebbe essere necessario riavviare il sistema"
    fi

    print_success "Installazione Docker completata"
    print_warning "Per utilizzare Docker senza sudo, disconnetti e riconnetti la sessione o riavvia il sistema"
    show_progress 0.05
}

# Funzione per configurare Terminator
configure_terminator() {
    REAL_USER=$(logname || echo $SUDO_USER)
    CONFIG_DIR="/home/$REAL_USER/.config/terminator"
    CONFIG_FILE="$CONFIG_DIR/config"
    
    # Verifica se terminator è installato
    if ! command_exists terminator; then
        print_error "Terminator non è installato. Installalo prima di configurarlo."
        return
    fi
    
    print_status "Configurazione Terminator..."
    
    # Crea la directory di configurazione se non esiste
    su - $REAL_USER -c "mkdir -p $CONFIG_DIR"
    
    # Crea il nuovo file di configurazione
    su - $REAL_USER -c "cat > '$CONFIG_FILE' << 'EOL'
[global_config]
 suppress_multiple_term_dialog = True
[keybindings]
broadcast_off = <Alt>o
broadcast_all = <Alt>a
[profiles]
 [[default]]
cursor_color = \"#aaaaaa\"
[layouts]
 [[default]]
 [[[child0]]]
type = Window
parent = \"\"
order = 0
position = 26:23
maximised = False
fullscreen = False
size = 734, 451
title = giorgio@cb0xx-22: ~
last_active_term = b169cbcc-f260-4676-b46b-f157a2f1c9d9
last_active_window = True
 [[[child1]]]
type = VPaned
parent = child0
order = 0
position = 223
ratio = 0.5
 [[[child2]]]
type = HPaned
parent = child1
order = 0
position = 364
ratio = 0.4993141289437586
 [[[terminal3]]]
type = Terminal
parent = child2
order = 0
profile = default
uuid = 40e3a1fd-1359-43e2-8cf6-a8476f08935d
 [[[terminal4]]]
type = Terminal
parent = child2
order = 1
profile = default
uuid = c99a7833-6c8a-4085-8432-4aae2d249a97
 [[[child5]]]
type = HPaned
parent = child1
order = 1
position = 364
ratio = 0.4993141289437586
 [[[terminal6]]]
type = Terminal
parent = child5
order = 0
profile = default
uuid = 437a2cb8-2c05-4c04-a0ab-7f3f1129f247
 [[[child7]]]
type = VPaned
parent = child5
order = 1
position = 109
ratio = 0.5
 [[[terminal8]]]
type = Terminal
parent = child7
order = 0
profile = default
uuid = b169cbcc-f260-4676-b46b-f157a2f1c9d9
 [[[terminal9]]]
type = Terminal
parent = child7
order = 1
profile = default
uuid = a4c256e0-a420-4ec4-91b8-aa98014127e7
[plugins]
EOL"
    
    # Imposta i permessi corretti
    chown -R $REAL_USER:$REAL_USER "$CONFIG_DIR"
    
    print_success "Configurazione Terminator completata"
    print_warning "Riavvia Terminator per applicare le modifiche"
    show_progress 0.05
}

# Funzione per installare Orca-Slicer
install_orca_slicer() {
    print_status "Installazione Orca-Slicer..."
    
    REAL_USER=$(logname || echo $SUDO_USER)
    INSTALL_DIR="/home/$REAL_USER/.local/bin"
    DESKTOP_DIR="/home/$REAL_USER/.local/share/applications"
    ICONS_DIR="/home/$REAL_USER/.local/share/icons/hicolor/256x256/apps"
    
    # Aggiungi il repository per webkit2gtk-4.1
    print_status "Configurazione repository per webkit2gtk-4.1..."
    add-apt-repository -y ppa:webkit-team/ppa
    apt-get update

    # Installa tutte le dipendenze necessarie
    print_status "Installazione dipendenze..."
    apt-get install -y \
        libfuse2 \
        wget \
        libwebkit2gtk-4.1-0 \
        libglib2.0-0 \
        libgtk-3-0 \
        libpango-1.0-0 \
        libcairo2 \
        libjpeg-dev \
        libhunspell-1.7-0

    # Crea le directory necessarie
    print_status "Creazione directory..."
    su - $REAL_USER -c "
        mkdir -p '$INSTALL_DIR'
        mkdir -p '$DESKTOP_DIR'
        mkdir -p '$ICONS_DIR'
    "
    
    # Scarica l'ultima versione di Orca-Slicer
    print_status "Download ultima versione di Orca-Slicer..."
    API_URL="https://api.github.com/repos/SoftFever/OrcaSlicer/releases/latest"
    DOWNLOAD_URL=$(curl -s $API_URL | grep "browser_download_url.*Ubuntu.*AppImage" | cut -d '"' -f 4)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        print_error "Impossibile trovare l'URL di download"
        return 1
    fi
    
    print_status "Download da: $DOWNLOAD_URL"
    
    # Rimuovi versione precedente se esiste
    if [ -f "$INSTALL_DIR/orca-slicer.AppImage" ]; then
        print_status "Rimozione versione precedente..."
        rm "$INSTALL_DIR/orca-slicer.AppImage"
    fi
    
    # Scarica il file
    if ! su - $REAL_USER -c "wget -q '$DOWNLOAD_URL' -O '$INSTALL_DIR/orca-slicer.AppImage'"; then
        print_error "Download fallito"
        return 1
    fi
    
    # Imposta i permessi
    print_status "Configurazione permessi..."
    chmod +x "$INSTALL_DIR/orca-slicer.AppImage"
    chown $REAL_USER:$REAL_USER "$INSTALL_DIR/orca-slicer.AppImage"
    
    # Scarica l'icona
    print_status "Download icona..."
    ICON_URL="https://raw.githubusercontent.com/SoftFever/OrcaSlicer/main/resources/images/OrcaSlicer.png"
    su - $REAL_USER -c "wget -q '$ICON_URL' -O '$ICONS_DIR/orca-slicer.png'"
    
    # Crea il file .desktop
    print_status "Creazione collegamento nel menu applicazioni..."
    su - $REAL_USER -c "cat > '$DESKTOP_DIR/orca-slicer.desktop' << EOL
[Desktop Entry]
Name=Orca-Slicer
Comment=Advanced 3D Printing Slicer
Exec=$INSTALL_DIR/orca-slicer.AppImage
Icon=orca-slicer
Terminal=false
Type=Application
Categories=Graphics;3DGraphics;Engineering;
StartupNotify=true
EOL"
    
    # Imposta i permessi corretti per il file .desktop
    chmod +x "$DESKTOP_DIR/orca-slicer.desktop"
    
    # Aggiorna il database delle applicazioni
    su - $REAL_USER -c "update-desktop-database '$DESKTOP_DIR'"
    
    # Verifica l'installazione
    if [ -x "$INSTALL_DIR/orca-slicer.AppImage" ]; then
        print_success "Installazione Orca-Slicer completata con successo"
        print_success "Puoi avviare Orca-Slicer dal menu delle applicazioni o eseguendo 'orca-slicer.AppImage'"
    else
        print_error "Si è verificato un problema durante l'installazione"
        return 1
    fi
    
    show_progress 0.05
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
    echo -e "${CYAN}9)${NC} Installa Docker"
    echo -e "${CYAN}10)${NC} Installa Orca-Slicer"
    echo -e "${CYAN}11)${NC} Configura Terminator"
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
            install_docker
            install_orca_slicer
            configure_git
            configure_terminator
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
        9)
            install_docker
            ;;
        10)
            install_orca_slicer
            ;;
        11)
            configure_terminator
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