#!/bin/bash

# Farben und Textstile
NC='\033[0m'            # No Color (Reset)
BLUE='\033[0;34m'        # Blau
CYAN='\033[0;36m'        # Heller Cyan
LIGHT_BLUE='\033[1;34m'  # Hellblau
DGRAY='\033[1;30m'       # Dunkelgrau
YELLOW='\033[1;33m'      # Gelb
WHITE='\033[1;37m'       # Weiß



# Funktionen
header() {
    clear
    echo "
    ==========================================================================
    
    ${BLUE}░██████╗░█████╗░██╗░░░░░██╗░░░██╗░██████╗  ██╗░░░░░░█████╗░██████╗░░██████╗
    ${BLUE}██╔════╝██╔══██╗██║░░░░░██║░░░██║██╔════╝  ██║░░░░░██╔══██╗██╔══██╗██╔════╝
    ${BLUE}╚█████╗░██║░░██║██║░░░░░██║░░░██║╚█████╗░  ██║░░░░░███████║██████╦╝╚█████╗░
    ${BLUE}░╚═══██╗██║░░██║██║░░░░░██║░░░██║░╚═══██╗  ██║░░░░░██╔══██║██╔══██╗░╚═══██╗
    ${BLUE}██████╔╝╚█████╔╝███████╗╚██████╔╝██████╔╝  ███████╗██║░░██║██████╦╝██████╔╝
    ${BLUE}╚═════╝░░╚════╝░╚══════╝░╚═════╝░╚═════╝░  ╚══════╝╚═╝░░╚═╝╚═════╝░╚═════╝░
    
    ==========================================================================
    "  
}

load_java() {
    if [[ ! -d "/home/container/.jabba" ]]; then
        echo -e "${CYAN}Jabba not found! Installing Jabba..."
        curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash -s -- --skip-rc | awk -W interactive -v c="$DGRAY" '{ print c $0 }'
        . /home/container/.jabba/jabba.sh
    fi
    
    source /home/container/.jabba/jabba.sh
    
    local JAVA_VERSION=$1
    case $JAVA_VERSION in
        8)  JAVA_VERSION="adopt@1.8-0" ;;
        11) JAVA_VERSION="adopt@1.11.0-0" ;;
        17) JAVA_VERSION="openjdk@1.17.0" ;;
        21) JAVA_VERSION="openjdk@21.0.0" ;;
        *)  echo -e "${YELLOW}Invalid Java version!"; exit 1 ;;
    esac

    echo -e "${CYAN}Installing Java ${LIGHT_BLUE}${JAVA_VERSION}${CYAN}..."
    jabba install "$JAVA_VERSION" > /dev/null 2>&1
    jabba use "$JAVA_VERSION"
}


download_file() {
    local URL=$1
    local OUTPUT=$2
    curl -s -L "$URL" -o "$OUTPUT"
}

install_buildtools() {
    local BUILD_DIR="/home/container/.breaker/buildtools"
    mkdir -p "$BUILD_DIR"
    download_file "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar" "$BUILD_DIR/BuildTools.jar"
}

compile_spigot() {
    install_buildtools
    local BUILD_DIR="/home/container/.breaker/buildtools"
    cd "$BUILD_DIR" || return
    java -Xms256M -Xmx"${SERVER_MEMORY}M" -jar BuildTools.jar --rev "$1" --compile SPIGOT | awk -W interactive -v c="$DGRAY" '{ print c $0 }'
    mv "$BUILD_DIR/Spigot/Spigot-Server/target/spigot-*.jar" /home/container/server.jar
    find . ! -name 'BuildTools.jar' -exec rm -rf {} + > /dev/null 2>&1
}

install_spigot() {
    load_java "$1"
    local SPIGOT_VERSION=$(curl -s https://hub.spigotmc.org/versions/ | grep -oP '"\K[^"]+')
    echo -e "${CYAN}Installing Spigot ${LIGHT_BLUE}${SPIGOT_VERSION}"
    compile_spigot "$SPIGOT_VERSION"
}

install_purpur() {
    local PURPUR_VERSION=$(curl -s https://api.purpurmc.org/v2/purpur | jq -r '.versions[-1]')
    echo -e "${CYAN}Installing Purpur ${LIGHT_BLUE}${PURPUR_VERSION}"
    download_file "https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}/latest/download" "server.jar"
}

install_paper() {
    local PAPER_VERSION=$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions[-1]')
    local LATEST_BUILD=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}" | jq -r '.builds[-1]')
    echo -e "${CYAN}Installing PaperMC ${LIGHT_BLUE}${PAPER_VERSION}-${LATEST_BUILD}"
    download_file "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}/builds/${LATEST_BUILD}/downloads/paper-${PAPER_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_vanilla() {
    local VERSION=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release')
    echo -e "${CYAN}Installing Vanilla Minecraft ${LIGHT_BLUE}${VERSION}"
    download_file "https://s3.amazonaws.com/Minecraft.Download/versions/${VERSION}/minecraft_server.${VERSION}.jar" "server.jar"
}

install_forge() {
    local VERSION=$(curl -s https://files.minecraftforge.net/maven/net/minecraftforge/forge/promotions_slim.json | jq -r '.promos["1.16.5-latest"]')
    echo -e "${CYAN}Installing Forge ${LIGHT_BLUE}${VERSION}"
    download_file "https://files.minecraftforge.net/maven/net/minecraftforge/forge/${VERSION}/forge-${VERSION}-installer.jar" "forge-installer.jar"
    java -jar forge-installer.jar --installServer
    mv forge-*.jar server.jar
}

install_fabric() {
    local FABRIC_VERSION=$(curl -s https://meta.fabricmc.net/v2/versions/loader | jq -r '.[0].version')
    echo -e "${CYAN}Installing Fabric ${LIGHT_BLUE}${FABRIC_VERSION}"
    download_file "https://meta.fabricmc.net/v2/versions/loader/${FABRIC_VERSION}/profile/json" "fabric-installer.json"
    java -jar fabric-installer.json --installServer
}

install_velocity() {
    local VELOCITY_VERSION=$(curl -s https://api.papermc.io/v2/projects/velocity | jq -r '.versions[-1]')
    echo -e "${CYAN}Installing Velocity ${LIGHT_BLUE}${VELOCITY_VERSION}"
    download_file "https://api.papermc.io/v2/projects/velocity/versions/${VELOCITY_VERSION}/latest/download" "server.jar"
}

install_waterfall() {
    local WATERFALL_VERSION=$(curl -s https://papermc.io/api/v2/projects/waterfall | jq -r '.versions[-1]')
    echo -e "${CYAN}Installing Waterfall ${LIGHT_BLUE}${WATERFALL_VERSION}"
    download_file "https://papermc.io/api/v2/projects/waterfall/versions/${WATERFALL_VERSION}/builds/latest/download" "server.jar"
}

install_bungeecord() {
    local BUNGEE_VERSION=$(curl -s https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target | grep -oP 'BungeeCord-\d+\.jar')
    echo -e "${CYAN}Installing Bungeecord ${LIGHT_BLUE}${BUNGEE_VERSION}"
    download_file "https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/${BUNGEE_VERSION}" "server.jar"
}

install_pycord() {
    echo -e "${CYAN}Installing Pycord..."
    pip install py-cord
}

install_discord_py() {
    echo -e "${CYAN}Installing discord.py..."
    pip install discord.py
}

install_flask() {
    echo -e "${CYAN}Installing Flask..."
    pip install Flask
}

install_fastapi() {
    echo -e "${CYAN}Installing FastAPI..."
    pip install fastapi
}

start_server() {
    echo -e "${CYAN}Starting Minecraft server..."
    MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
    ${MODIFIED_STARTUP}
}

menu_minecraft_proxy() {
    header
    echo -e "${YELLOW}1${LIGHT_BLUE}) ${CYAN}Install Velocity"
    echo -e "${YELLOW}2${LIGHT_BLUE}) ${CYAN}Install Waterfall"
    echo -e "${YELLOW}3${LIGHT_BLUE}) ${CYAN}Install Bungeecord"
    echo -e "${YELLOW}0${LIGHT_BLUE}) ${CYAN}Back"
    
    read -r -p "$(echo -e "${CYAN}Select an option: ${LIGHT_BLUE}")" option

    case $option in
        1) install_velocity ;;
        2) install_waterfall ;;
        3) install_bungeecord ;;
        0) main_menu ;;
        *) echo -e "${DGRAY}Invalid option!"; menu_minecraft_proxy ;;
    esac
}

menu_minecraft_java() {
    header
    echo -e "${YELLOW}1${LIGHT_BLUE}) ${CYAN}Install PaperMC"
    echo -e "${YELLOW}2${LIGHT_BLUE}) ${CYAN}Install Purpur"
    echo -e "${YELLOW}3${LIGHT_BLUE}) ${CYAN}Install Spigot"
    echo -e "${YELLOW}4${LIGHT_BLUE}) ${CYAN}Install Vanilla"
    echo -e "${YELLOW}5${LIGHT_BLUE}) ${CYAN}Install Forge"
    echo -e "${YELLOW}6${LIGHT_BLUE}) ${CYAN}Install Fabric"
    echo -e "${YELLOW}0${LIGHT_BLUE}) ${CYAN}Back"
    
    read -r -p "$(echo -e "${CYAN}Select an option: ${LIGHT_BLUE}")" option

    case $option in
        1) install_paper ;;
        2) install_purpur ;;
        3) install_spigot ;;
        4) install_vanilla ;;
        5) install_forge ;;
        6) install_fabric ;;
        0) main_menu ;;
        *) echo -e "${DGRAY}Invalid option!"; menu_minecraft_java ;;
    esac
}

menu_python() {
    header
    echo -e "${YELLOW}1${LIGHT_BLUE}) ${CYAN}Install Pycord"
    echo -e "${YELLOW}2${LIGHT_BLUE}) ${CYAN}Install discord.py"
    echo -e "${YELLOW}3${LIGHT_BLUE}) ${CYAN}Install Flask"
    echo -e "${YELLOW}4${LIGHT_BLUE}) ${CYAN}Install FastAPI"
    echo -e "${YELLOW}0${LIGHT_BLUE}) ${CYAN}Back"
    
    read -r -p "$(echo -e "${CYAN}Select an option: ${LIGHT_BLUE}")" option

    case $option in
        1) install_pycord ;;
        2) install_discord_py ;;
        3) install_flask ;;
        4) install_fastapi ;;
        0) main_menu ;;
        *) echo -e "${DGRAY}Invalid option!"; menu_python ;;
    esac
}

main_menu() {
    header
    echo -e "${YELLOW}1${LIGHT_BLUE}) ${CYAN}Minecraft Proxy"
    echo -e "${YELLOW}2${LIGHT_BLUE}) ${CYAN}Minecraft Java Edition Server"
    echo -e "${YELLOW}3${LIGHT_BLUE}) ${CYAN}Python"
    echo -e "${YELLOW}0${LIGHT_BLUE}) ${CYAN}Exit"

    read -r -p "$(echo -e "${CYAN}Select an option: ${LIGHT_BLUE}")" option

    case $option in
        1) menu_minecraft_proxy ;;
        2) menu_minecraft_java ;;
        3) menu_python ;;
        0) echo -e "${CYAN}Exiting..."; exit 0 ;;
        *) echo -e "${DGRAY}Invalid option!"; main_menu ;;
    esac
}

# Variablen
SERVER_MEMORY="${1:-1024}" 

# Start
main_menu
