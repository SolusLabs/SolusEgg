#!/bin/bash

# Farben definieren
BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
DGRAY='\033[0;37m'
RESET='\033[0m'

# Arbeitsverzeichnis setzen
cd /home/container || exit 1

# Header-Funktion (beibehalten aus altem Code, aber Farbanpassungen möglich)
header() {
    clear
    echo -e "
${BLUE}==========================================================================
${BLUE}░██████╗░█████╗░██╗░░░░░██╗░░░██╗░██████╗  ██╗░░░░░░█████╗░██████╗░░██████╗
${BLUE}██╔════╝██╔══██╗██║░░░░░██║░░░██║██╔════╝  ██║░░░░░██╔══██╗██╔══██╗██╔════╝
${BLUE}╚█████╗░██║░░██║██║░░░░░██║░░░██║╚█████╗░  ██║░░░░░███████║██████╦╝╚█████╗░
${BLUE}░╚═══██╗██║░░██║██║░░░░░██║░░░██║░╚═══██╗  ██║░░░░░██╔══██║██╔══██╗░╚═══██╗
${BLUE}██████╔╝╚█████╔╝███████╗╚██████╔╝██████╔╝  ███████╗██║░░██║██████╦╝██████╔╝
${BLUE}╚═════╝░░╚════╝░╚══════╝░╚═════╝░╚═════╝░  ╚══════╝╚═╝░░╚═╝╚═════╝░╚═════╝░
${BLUE}==========================================================================${RESET}
"
}

# Download-Funktion für Dateien
download_file() {
    local url="$1"
    local output="$2"
    echo -e "${CYAN}Downloading: ${LIGHT_BLUE}${url}${RESET}"
    curl -s -L -o "${output}" "${url}"
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Download failed!${RESET}"
        exit 1
    fi
    echo -e "${CYAN}Download complete: ${LIGHT_BLUE}${output}${RESET}"
}

# Installationsfunktionen
install_purpur() {
    local PURPUR_VERSION=$(curl -s https://api.purpurmc.org/v2/purpur | jq -r '.versions[-1]')
    echo -e "${CYAN}Installing Purpur ${LIGHT_BLUE}${PURPUR_VERSION}${RESET}"
    download_file "https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}/latest/download" "server.jar"
}

install_paper() {
    local PAPER_VERSION=$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions[-1]')
    local LATEST_BUILD=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}" | jq -r '.builds[-1]')
    echo -e "${CYAN}Installing PaperMC ${LIGHT_BLUE}${PAPER_VERSION}-${LATEST_BUILD}${RESET}"
    download_file "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}/builds/${LATEST_BUILD}/downloads/paper-${PAPER_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_spigot() {
    # Spigot-Download ist etwas komplizierter, da es keinen direkten DL-Link gibt.
    # Hier könnte man ggf. Buildtools verwenden, aber für das Beispiel nur ein Platzhalter:
    local VERSION="1.20.1" # Beispiel-Version
    echo -e "${CYAN}Installing Spigot ${LIGHT_BLUE}${VERSION}${RESET}"
    # Diese URL ist fiktiv. In der Realität müsstest du hier BuildTools nutzen.
    # download_file "https://example.com/spigot-${VERSION}.jar" "server.jar"
    echo -e "${YELLOW}Spigot installation routine is not defined. Please integrate BuildTools if needed.${RESET}"
}

install_vanilla() {
    local VERSION=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release')
    echo -e "${CYAN}Installing Vanilla Minecraft ${LIGHT_BLUE}${VERSION}${RESET}"
    download_file "https://s3.amazonaws.com/Minecraft.Download/versions/${VERSION}/minecraft_server.${VERSION}.jar" "server.jar"
}

install_forge() {
    local VERSION=$(curl -s https://maven.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json | jq -r '.promos["1.16.5-latest"]')
    echo -e "${CYAN}Installing Forge ${LIGHT_BLUE}${VERSION}${RESET}"
    download_file "https://maven.minecraftforge.net/net/minecraftforge/forge/${VERSION}/forge-${VERSION}-installer.jar" "forge-installer.jar"
    java -jar forge-installer.jar --installServer
    mv forge-*.jar server.jar
    rm forge-installer.jar
}

install_fabric() {
    # Fabric Installation ist hier nur exemplarisch.
    # Eigentlich benötigt man den Fabric Installer:
    local FABRIC_LOADER=$(curl -s https://meta.fabricmc.net/v2/versions/loader | jq -r '.[0].version')
    echo -e "${CYAN}Installing Fabric Loader ${LIGHT_BLUE}${FABRIC_LOADER}${RESET}"
    # Beispiel: Der Fabric Installer, je nach Version.
    # Für eine echte Installation müsste man den Installer korrekt einsetzen:
    # download_file "https://maven.fabricmc.net/net/fabricmc/fabric-installer/${FABRIC_LOADER}/fabric-installer-${FABRIC_LOADER}.jar" "fabric-installer.jar"
    # java -jar fabric-installer.jar server -mcversion $SOME_MC_VERSION -downloadMinecraft
    # rm fabric-installer.jar
    echo -e "${YELLOW}Fabric installation routine is simplified. Please integrate full installer steps.${RESET}"
}

install_velocity() {
    local VELOCITY_VERSION=$(curl -s https://api.papermc.io/v2/projects/velocity | jq -r '.versions[-1]')
    local LATEST_BUILD=$(curl -s "https://api.papermc.io/v2/projects/velocity/versions/${VELOCITY_VERSION}" | jq -r '.builds[-1]')
    echo -e "${CYAN}Installing Velocity ${LIGHT_BLUE}${VELOCITY_VERSION}-${LATEST_BUILD}${RESET}"
    download_file "https://api.papermc.io/v2/projects/velocity/versions/${VELOCITY_VERSION}/builds/${LATEST_BUILD}/downloads/velocity-${VELOCITY_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_waterfall() {
    local WATERFALL_VERSION=$(curl -s https://papermc.io/api/v2/projects/waterfall | jq -r '.versions[-1]')
    local LATEST_BUILD=$(curl -s "https://papermc.io/api/v2/projects/waterfall/versions/${WATERFALL_VERSION}" | jq -r '.builds[-1]')
    echo -e "${CYAN}Installing Waterfall ${LIGHT_BLUE}${WATERFALL_VERSION}-${LATEST_BUILD}${RESET}"
    download_file "https://papermc.io/api/v2/projects/waterfall/versions/${WATERFALL_VERSION}/builds/${LATEST_BUILD}/downloads/waterfall-${WATERFALL_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_bungeecord() {
    # Bungeecord braucht einen direkten Download vom Jenkins:
    local BUNGEE_BUILD=$(curl -s https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/buildNumber)
    echo -e "${CYAN}Installing Bungeecord build ${LIGHT_BLUE}${BUNGEE_BUILD}${RESET}"
    download_file "https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/BungeeCord.jar" "server.jar"
}

menu_minecraft_proxy() {
    header
    echo -e "${LIGHT_BLUE}=== Minecraft Proxy Installation ===${RESET}"
    echo -e "${YELLOW}1${LIGHT_BLUE})${CYAN} Install Velocity"
    echo -e "${YELLOW}2${LIGHT_BLUE})${CYAN} Install Waterfall"
    echo -e "${YELLOW}3${LIGHT_BLUE})${CYAN} Install Bungeecord"
    echo -e "${YELLOW}0${LIGHT_BLUE})${CYAN} Back"
    echo -en "${CYAN}Select an option: ${LIGHT_BLUE}"
    read -r option

    case $option in
        1) install_velocity ;;
        2) install_waterfall ;;
        3) install_bungeecord ;;
        0) main_menu ;;
        *) echo -e "${DGRAY}Invalid option!${RESET}"; sleep 1; menu_minecraft_proxy ;;
    esac
}

menu_minecraft_java() {
    header
    echo -e "${LIGHT_BLUE}=== Minecraft Java Edition Server Installation ===${RESET}"
    echo -e "${YELLOW}1${LIGHT_BLUE})${CYAN} Install PaperMC"
    echo -e "${YELLOW}2${LIGHT_BLUE})${CYAN} Install Purpur"
    echo -e "${YELLOW}3${LIGHT_BLUE})${CYAN} Install Spigot"
    echo -e "${YELLOW}4${LIGHT_BLUE})${CYAN} Install Vanilla"
    echo -e "${YELLOW}5${LIGHT_BLUE})${CYAN} Install Forge"
    echo -e "${YELLOW}6${LIGHT_BLUE})${CYAN} Install Fabric"
    echo -e "${YELLOW}0${LIGHT_BLUE})${CYAN} Back"
    echo -en "${CYAN}Select an option: ${LIGHT_BLUE}"
    read -r option

    case $option in
        1) install_paper ;;
        2) install_purpur ;;
        3) install_spigot ;;
        4) install_vanilla ;;
        5) install_forge ;;
        6) install_fabric ;;
        0) main_menu ;;
        *) echo -e "${DGRAY}Invalid option!${RESET}"; sleep 1; menu_minecraft_java ;;
    esac
}

main_menu() {
    header
    echo -e "${LIGHT_BLUE}=== Main Menu ===${RESET}"
    echo -e "${YELLOW}1${LIGHT_BLUE})${CYAN} Minecraft Proxy"
    echo -e "${YELLOW}2${LIGHT_BLUE})${CYAN} Minecraft Java Edition Server"
    echo -e "${YELLOW}3${LIGHT_BLUE})${CYAN} More coming soon"
    echo -e "${YELLOW}0${LIGHT_BLUE})${CYAN} Exit"
    echo -en "${CYAN}Select an option: ${LIGHT_BLUE}"
    read -r option

    case $option in
        1) menu_minecraft_proxy ;;
        2) menu_minecraft_java ;;
        3) echo -e "${CYAN}More options will be added soon!${RESET}"; sleep 1; main_menu ;;
        0) echo -e "${CYAN}Exiting...${RESET}"; exit 0 ;;
        *) echo -e "${DGRAY}Invalid option!${RESET}"; sleep 1; main_menu ;;
    esac
}

# Einstiegspunkt: Main Menu
main_menu
