#!/bin/bash

# Farben und Textstile
NC='\033[0m'
PURPLE='\033[0;35m'
LPURPLE='\033[1;35m'
DGRAY='\033[1;30m'
YELLOW='\033[1;33m'

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
        echo -e "${PURPLE}Jabba not found! Installing Jabba..."
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

    echo -e "${PURPLE}Installing Java ${LPURPLE}${JAVA_VERSION}${PURPLE}..."
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
    echo -e "${PURPLE}Installing Spigot ${LPURPLE}${SPIGOT_VERSION}"
    compile_spigot "$SPIGOT_VERSION"
}

install_purpur() {
    local PURPUR_VERSION=$(curl -s https://api.purpurmc.org/v2/purpur | jq -r '.versions[-1]')
    echo -e "${PURPLE}Installing Purpur ${LPURPLE}${PURPUR_VERSION}"
    download_file "https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}/latest/download" "server.jar"
}

install_paper() {
    local PAPER_VERSION=$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions[-1]')
    local LATEST_BUILD=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}" | jq -r '.builds[-1]')
    echo -e "${PURPLE}Installing PaperMC ${LPURPLE}${PAPER_VERSION}-${LATEST_BUILD}"
    download_file "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}/builds/${LATEST_BUILD}/downloads/paper-${PAPER_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_vanilla() {
    local VERSION=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release')
    echo -e "${PURPLE}Installing Vanilla Minecraft ${LPURPLE}${VERSION}"
    download_file "https://s3.amazonaws.com/Minecraft.Download/versions/${VERSION}/minecraft_server.${VERSION}.jar" "server.jar"
}

install_forge() {
    local VERSION=$(curl -s https://files.minecraftforge.net/maven/net/minecraftforge/forge/promotions_slim.json | jq -r '.promos["1.16.5-latest"]')
    echo -e "${PURPLE}Installing Forge ${LPURPLE}${VERSION}"
    download_file "https://files.minecraftforge.net/maven/net/minecraftforge/forge/${VERSION}/forge-${VERSION}-installer.jar" "forge-installer.jar"
    java -jar forge-installer.jar --installServer
    mv forge-*.jar server.jar
}

install_fabric() {
    local FABRIC_VERSION=$(curl -s https://meta.fabricmc.net/v2/versions/loader | jq -r '.[0].version')
    echo -e "${PURPLE}Installing Fabric ${LPURPLE}${FABRIC_VERSION}"
    download_file "https://meta.fabricmc.net/v2/versions/loader/${FABRIC_VERSION}/profile/json" "fabric-installer.json"
    java -jar fabric-installer.json --installServer
}

install_velocity() {
    local VELOCITY_VERSION=$(curl -s https://api.papermc.io/v2/projects/velocity | jq -r '.versions[-1]')
    echo -e "${PURPLE}Installing Velocity ${LPURPLE}${VELOCITY_VERSION}"
    download_file "https://api.papermc.io/v2/projects/velocity/versions/${VELOCITY_VERSION}/latest/download" "server.jar"
}

install_waterfall() {
    local WATERFALL_VERSION=$(curl -s https://papermc.io/api/v2/projects/waterfall | jq -r '.versions[-1]')
    echo -e "${PURPLE}Installing Waterfall ${LPURPLE}${WATERFALL_VERSION}"
    download_file "https://papermc.io/api/v2/projects/waterfall/versions/${WATERFALL_VERSION}/builds/latest/download" "server.jar"
}

install_bungeecord() {
    local BUNGEE_VERSION=$(curl -s https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target | grep -oP 'BungeeCord-\d+\.jar')
    echo -e "${PURPLE}Installing Bungeecord ${LPURPLE}${BUNGEE_VERSION}"
    download_file "https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/${BUNGEE_VERSION}" "server.jar"
}

install_pycord() {
    echo -e "${PURPLE}Installing Pycord..."
    pip install py-cord
}

install_discord_py() {
    echo -e "${PURPLE}Installing discord.py..."
    pip install discord.py
}

install_flask() {
    echo -e "${PURPLE}Installing Flask..."
    pip install Flask
}

install_fastapi() {
    echo -e "${PURPLE}Installing FastAPI..."
    pip install fastapi
}

start_server() {
    echo -e "${PURPLE}Starting Minecraft server..."
    MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
    ${MODIFIED_STARTUP}
}

menu_minecraft_proxy() {
    header
    echo -e "${YELLOW}1${LPURPLE}) ${PURPLE}Install Velocity"
    echo -e "${YELLOW}2${LPURPLE}) ${PURPLE}Install Waterfall"
    echo -e "${YELLOW}3${LPURPLE}) ${PURPLE}Install Bungeecord"
    echo -e "${YELLOW}0${LPURPLE}) ${PURPLE}Back"
    
    read -r -p "$(echo -e "${PURPLE}Select an option: ${LPURPLE}")" option

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
    echo -e "${YELLOW}1${LPURPLE}) ${PURPLE}Install PaperMC"
    echo -e "${YELLOW}2${LPURPLE}) ${PURPLE}Install Purpur"
    echo -e "${YELLOW}3${LPURPLE}) ${PURPLE}Install Spigot"
    echo -e "${YELLOW}4${LPURPLE}) ${PURPLE}Install Vanilla"
    echo -e "${YELLOW}5${LPURPLE}) ${PURPLE}Install Forge"
    echo -e "${YELLOW}6${LPURPLE}) ${PURPLE}Install Fabric"
    echo -e "${YELLOW}0${LPURPLE}) ${PURPLE}Back"
    
    read -r -p "$(echo -e "${PURPLE}Select an option: ${LPURPLE}")" option

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
    echo -e "${YELLOW}1${LPURPLE}) ${PURPLE}Install Pycord"
    echo -e "${YELLOW}2${LPURPLE}) ${PURPLE}Install discord.py"
    echo -e "${YELLOW}3${LPURPLE}) ${PURPLE}Install Flask"
    echo -e "${YELLOW}4${LPURPLE}) ${PURPLE}Install FastAPI"
    echo -e "${YELLOW}0${LPURPLE}) ${PURPLE}Back"
    
    read -r -p "$(echo -e "${PURPLE}Select an option: ${LPURPLE}")" option

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
    echo -e "${YELLOW}1${LPURPLE}) ${PURPLE}Minecraft Proxy"
    echo -e "${YELLOW}2${LPURPLE}) ${PURPLE}Minecraft Java Edition Server"
    echo -e "${YELLOW}3${LPURPLE}) ${PURPLE}Python"
    echo -e "${YELLOW}0${LPURPLE}) ${PURPLE}Exit"

    read -r -p "$(echo -e "${PURPLE}Select an option: ${LPURPLE}")" option

    case $option in
        1) menu_minecraft_proxy ;;
        2) menu_minecraft_java ;;
        3) menu_python ;;
        0) echo -e "${PURPLE}Exiting..."; exit 0 ;;
        *) echo -e "${DGRAY}Invalid option!"; main_menu ;;
    esac
}

# Variablen
SERVER_MEMORY="${1:-1024}" 

# Start
main_menu
