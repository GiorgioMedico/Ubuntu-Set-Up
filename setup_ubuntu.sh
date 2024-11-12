#!/bin/bash

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

# Funzione per mostrare messaggi colorati
print_message() {
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color
    echo -e "${GREEN}$1${NC}"
}

# Funzione per installare pacchetti di utilità
install_utils() {
    print_message "Installazione pacchetti di utilità..."
    sudo apt update
    for package in "${UTILS[@]}"; do
        print_message "Installazione $package..."
        sudo apt install -y "$package"
    done
}

# Funzione per installare pacchetti LaTeX
install_latex() {
    print_message "Installazione pacchetti LaTeX..."
    sudo apt update
    for package in "${LATEX_PACKAGES[@]}"; do
        print_message "Installazione $package..."
        sudo apt install -y "$package"
    done
}

# Funzione per installare VSCode
install_vscode() {
    print_message "Installazione Visual Studio Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo apt update
    sudo apt install -y code
    rm packages.microsoft.gpg
}

# Funzione per installare Miniconda
install_miniconda() {
    print_message "Installazione Miniconda..."
    MINICONDA_PATH="$HOME/miniconda3"
    if [ ! -d "$MINICONDA_PATH" ]; then
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
        bash miniconda.sh -b -p $MINICONDA_PATH
        rm miniconda.sh
        
        # Aggiungi miniconda al PATH
        echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
        
        # Inizializza conda per bash
        $MINICONDA_PATH/bin/conda init bash
    else
        print_message "Miniconda è già installato in $MINICONDA_PATH"
    fi
}

# Funzione per installare ROS2
install_ros2() {
    print_message "Installazione ROS2 Humble..."
    
    # Locale setup
    sudo apt update && sudo apt install -y locales
    sudo locale-gen en_US en_US.UTF-8
    sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    export LANG=en_US.UTF-8
    
    # Aggiungi il repository ROS2
    sudo apt install -y software-properties-common
    sudo add-apt-repository universe
    
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
    
    # Installa ROS2 Humble
    sudo apt update
    sudo apt install -y ros-humble-desktop
    sudo apt install -y ros-dev-tools
    
    # Aggiungi setup al .bashrc
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
}

# Funzione per configurare Git
configure_git() {
    print_message "Configurazione Git..."
    read -p "Inserisci il tuo nome per Git: " git_name
    read -p "Inserisci la tua email per Git: " git_email
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global color.ui auto
    
    # Genera una chiave SSH se non esiste
    if [ ! -f ~/.ssh/id_rsa ]; then
        print_message "Generazione chiave SSH..."
        ssh-keygen -t rsa -b 4096 -C "$git_email" -f ~/.ssh/id_rsa -N ""
        print_message "La tua chiave pubblica SSH è:"
        cat ~/.ssh/id_rsa.pub
    fi
}

# Funzione per aggiornare il sistema
update_system() {
    print_message "Aggiornamento del sistema..."
    sudo apt update && sudo apt upgrade -y
}

# Menu principale
main() {
    print_message "Script di setup Ubuntu"
    print_message "Scegli cosa installare:"
    echo "1) Installa tutto"
    echo "2) Aggiorna sistema"
    echo "3) Installa utilità"
    echo "4) Installa LaTeX"
    echo "5) Installa VSCode"
    echo "6) Installa Miniconda"
    echo "7) Installa ROS2"
    echo "8) Configura Git"
    echo "0) Esci"
    
    read -p "Inserisci la tua scelta: " choice
    
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
            exit 0
            ;;
        *)
            echo "Scelta non valida"
            ;;
    esac
}

# Esegui il menu principale
main