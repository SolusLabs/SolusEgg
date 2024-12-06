#!/bin/bash

# Farben
BLUE='\033[0;34m'
RESET='\033[0m'

cd /home/container || exit 1

SELECTION_FILE="/home/container/.selected_minecraft"

# Header anzeigen
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
${BLUE}==========================================================================
${RESET}
"
}

# Download-Hilfsfunktion
download_file() {
    local url="$1"
    local output="$2"
    echo "Downloading: $url"
    curl -s -L -o "${output}" "${url}"
    if [ $? -ne 0 ]; then
        echo "Download failed!"
        exit 1
    fi
    echo "Download complete: ${output}"
}

# Installationsfunktionen (Beispiele)
install_paper() {
    local PAPER_VERSION=$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions[-1]')
    local LATEST_BUILD=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}" | jq -r '.builds[-1]')
    echo "Installing PaperMC ${PAPER_VERSION}-${LATEST_BUILD}"
    download_file "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}/builds/${LATEST_BUILD}/downloads/paper-${PAPER_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_purpur() {
    local PURPUR_VERSION=$(curl -s https://api.purpurmc.org/v2/purpur | jq -r '.versions[-1]')
    echo "Installing Purpur ${PURPUR_VERSION}"
    download_file "https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}/latest/download" "server.jar"
}

install_spigot() {
    # Hier müsste eigentlich BuildTools eingesetzt werden, dies ist nur ein Platzhalter.
    echo "Installing Spigot placeholder"
    # download_file "irgendein_spigot_link" "server.jar"
    echo "Spigot installation needs manual integration of BuildTools."
}

install_vanilla() {
    local VERSION=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release')
    echo "Installing Vanilla Minecraft ${VERSION}"
    download_file "https://s3.amazonaws.com/Minecraft.Download/versions/${VERSION}/minecraft_server.${VERSION}.jar" "server.jar"
}

install_forge() {
    local VERSION=$(curl -s https://maven.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json | jq -r '.promos["1.16.5-latest"]')
    echo "Installing Forge ${VERSION}"
    download_file "https://maven.minecraftforge.net/net/minecraftforge/forge/${VERSION}/forge-${VERSION}-installer.jar" "forge-installer.jar"
    java -jar forge-installer.jar --installServer
    mv forge-*.jar server.jar
    rm forge-installer.jar
}

install_fabric() {
    echo "Fabric installation needs full integration. Placeholder."
}

install_velocity() {
    local VELOCITY_VERSION=$(curl -s https://api.papermc.io/v2/projects/velocity | jq -r '.versions[-1]')
    local LATEST_BUILD=$(curl -s "https://api.papermc.io/v2/projects/velocity/versions/${VELOCITY_VERSION}" | jq -r '.builds[-1]')
    echo "Installing Velocity ${VELOCITY_VERSION}-${LATEST_BUILD}"
    download_file "https://api.papermc.io/v2/projects/velocity/versions/${VELOCITY_VERSION}/builds/${LATEST_BUILD}/downloads/velocity-${VELOCITY_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_waterfall() {
    local WATERFALL_VERSION=$(curl -s https://papermc.io/api/v2/projects/waterfall | jq -r '.versions[-1]')
    local LATEST_BUILD=$(curl -s "https://papermc.io/api/v2/projects/waterfall/versions/${WATERFALL_VERSION}" | jq -r '.builds[-1]')
    echo "Installing Waterfall ${WATERFALL_VERSION}-${LATEST_BUILD}"
    download_file "https://papermc.io/api/v2/projects/waterfall/versions/${WATERFALL_VERSION}/builds/${LATEST_BUILD}/downloads/waterfall-${WATERFALL_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_bungeecord() {
    local BUNGEE_BUILD=$(curl -s https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/buildNumber)
    echo "Installing Bungeecord build ${BUNGEE_BUILD}"
    download_file "https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/BungeeCord.jar" "server.jar"
}

# Menüfunktionen
menu_minecraft_proxy() {
    header
    echo "=== Minecraft Proxy Installation ==="
    echo "1) Install Velocity"
    echo "2) Install Waterfall"
    echo "3) Install Bungeecord"
    echo "0) Back"
    echo -n "Select an option: "
    read -r option

    case $option in
        1) install_velocity; save_selection "Proxy" "Velocity"; create_start_script; exit 0 ;;
        2) install_waterfall; save_selection "Proxy" "Waterfall"; create_start_script; exit 0 ;;
        3) install_bungeecord; save_selection "Proxy" "Bungeecord"; create_start_script; exit 0 ;;
        0) main_menu ;;
        *) echo "Invalid option!"; sleep 1; menu_minecraft_proxy ;;
    esac
}

menu_minecraft_java() {
    header
    echo "=== Minecraft Java Edition Server Installation ==="
    echo "1) Install PaperMC"
    echo "2) Install Purpur"
    echo "3) Install Spigot"
    echo "4) Install Vanilla"
    echo "5) Install Forge"
    echo "6) Install Fabric"
    echo "0) Back"
    echo -n "Select an option: "
    read -r option

    case $option in
        1) install_paper; save_selection "Java" "PaperMC"; create_start_script; exit 0 ;;
        2) install_purpur; save_selection "Java" "Purpur"; create_start_script; exit 0 ;;
        3) install_spigot; save_selection "Java" "Spigot"; create_start_script; exit 0 ;;
        4) install_vanilla; save_selection "Java" "Vanilla"; create_start_script; exit 0 ;;
        5) install_forge; save_selection "Java" "Forge"; create_start_script; exit 0 ;;
        6) install_fabric; save_selection "Java" "Fabric"; create_start_script; exit 0 ;;
        0) main_menu ;;
        *) echo "Invalid option!"; sleep 1; menu_minecraft_java ;;
    esac
}

main_menu() {
    header
    echo "=== Main Menu ==="
    echo "1) Minecraft Proxy"
    echo "2) Minecraft Java Edition Server"
    echo "3) More coming soon"
    echo "0) Exit"
    echo -n "Select an option: "
    read -r option

    case $option in
        1) menu_minecraft_proxy ;;
        2) menu_minecraft_java ;;
        3) echo "More options will be added soon!"; sleep 1; main_menu ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option!"; sleep 1; main_menu ;;
    esac
}

save_selection() {
    # Speichert die Auswahl in einer Datei, damit beim nächsten Start kein Menü erscheint
    # Parameter 1: Kategorie
    # Parameter 2: Software
    echo "$1:$2" > "$SELECTION_FILE"
    echo "Selection saved: $1 - $2"
}

create_start_script() {
    # Erstellt ein start.sh Skript, welches den Startbefehl des Pterodactyl-Containers nutzt
    cat > start.sh <<EOF
#!/bin/bash
MODIFIED_STARTUP=\`eval echo \$(echo \${STARTUP} | sed -e 's/{{/\${/g' -e 's/}}/}/g')\`
echo ":/home/container \$ \${MODIFIED_STARTUP}"
\${MODIFIED_STARTUP}
EOF
    chmod +x start.sh
    echo "start.sh created."
}

# Prüfen, ob schon eine Auswahl getroffen wurde
if [ -f "$SELECTION_FILE" ]; then
    # Datei existiert, also direkt start.sh ausführen (sofern server.jar und start.sh existieren)
    if [ -f "server.jar" ] && [ -f "start.sh" ]; then
        echo "Using previously selected server configuration..."
        ./start.sh
        exit 0
    else
        # Falls aus irgendeinem Grund server.jar oder start.sh fehlen, neu installieren
        rm -f "$SELECTION_FILE"
        main_menu
    fi
else
    # Keine Auswahl -> Menü anzeigen
    main_menu
fi