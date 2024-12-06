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

############################################
# Funktionen zur Auswahl von Minecraft-Versionen
############################################

# Fragt den Benutzer nach einer Minecraft-Version
select_minecraft_version() {
    echo "Please enter the desired Minecraft version (e.g. 1.20.1):"
    read -r MC_VERSION
    if [ -z "$MC_VERSION" ]; then
        echo "No version entered, using latest release."
        # Hole neueste Vanilla-Version als Fallback
        MC_VERSION=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release')
    fi
    echo "Selected Minecraft version: $MC_VERSION"
}

# Für Forge: Liste verfügbare Forge-Versionen für eine gegebene Minecraft-Version
select_forge_version() {
    local MC_VERSION="$1"
    local FORGE_URL="https://files.minecraftforge.net/net/minecraftforge/forge/index_${MC_VERSION}.html"
    local HTML=$(curl -s "$FORGE_URL")

    if [[ "$HTML" == *"404 Not Found"* ]]; then
        echo "No Forge versions found for Minecraft $MC_VERSION."
        exit 1
    fi

    # Extrahiere Forge-Versionen
    local VERSIONS=$(echo "$HTML" | grep -oP "forge-${MC_VERSION}-\K[0-9]+\.[0-9]+\.[0-9]+" | sort -V | uniq)

    if [ -z "$VERSIONS" ]; then
        echo "No Forge versions for $MC_VERSION found."
        exit 1
    fi

    echo "Available Forge versions for Minecraft $MC_VERSION:"
    echo "$VERSIONS"
    echo -n "Please choose a Forge version: "
    read -r FORGE_VERSION
    echo "$FORGE_VERSION"
}

# Für Fabric: Hole verfügbares Loader-Listing für gegebene MC-Version
select_fabric_version() {
    local MC_VERSION="$1"
    # Fabric API Endpoint für Loader-Versionen für eine spezifische MC-Version
    local FABRIC_URL="https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}"
    local JSON=$(curl -s "$FABRIC_URL")

    # Prüfe, ob Ergebnisse vorhanden sind
    local COUNT=$(echo "$JSON" | jq '. | length')
    if [ "$COUNT" -eq 0 ]; then
        echo "No Fabric loader versions found for Minecraft $MC_VERSION."
        exit 1
    fi

    echo "Available Fabric loader versions for Minecraft $MC_VERSION:"
    # Liste Loader-Versionen
    echo "$JSON" | jq -r '.[].loader.version'
    echo -n "Please choose a Fabric loader version: "
    read -r FABRIC_VERSION
    echo "$FABRIC_VERSION"
}

# Für NeoForge: Ähnlich wie Forge, wir nehmen an, dass es einen ähnlichen Endpoint gibt.
# Wir nutzen Promotions-Slim ähnlich wie bei Forge, angenommen:
# https://maven.neoforged.net/net/neoforged/neoforge/promotions_slim.json
select_neoforge_version() {
    local MC_VERSION="$1"
    local NEOFORGE_URL="https://maven.neoforged.net/net/neoforged/neoforge/promotions_slim.json"
    local JSON=$(curl -s "$NEOFORGE_URL")

    # Hier gehen wir davon aus, dass .promos ähnlich wie bei Forge aufgebaut ist:
    # "promos": {
    #  "1.20.1-latest": "46.0.14",
    #  ...
    # }
    # Extrahiere Versionskeys, die MC_VERSION enthalten
    local PROMOS=$(echo "$JSON" | jq -r '.promos | keys[]' | grep "$MC_VERSION")

    if [ -z "$PROMOS" ]; then
        echo "No NeoForge versions found for Minecraft $MC_VERSION."
        exit 1
    fi

    echo "Available NeoForge versions for Minecraft $MC_VERSION:"
    # Extrahiere nur den Zahlenanteil nach MC_VERSION-
    echo "$PROMOS" | sed "s/${MC_VERSION}-//g"
    echo -n "Please choose a NeoForge version: "
    read -r NEOFORGE_VERSION
    echo "$NEOFORGE_VERSION"
}

############################################
# Installationsfunktionen
############################################

install_paper() {
    local MC_VERSION="$1"
    local PAPER_VERSION=$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions[]' | grep "$MC_VERSION" | tail -n1)
    if [ -z "$PAPER_VERSION" ]; then
        echo "No matching Paper version for $MC_VERSION found. Using latest."
        PAPER_VERSION=$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions[-1]')
    fi
    local LATEST_BUILD=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}" | jq -r '.builds[-1]')
    echo "Installing PaperMC ${PAPER_VERSION}-${LATEST_BUILD}"
    download_file "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}/builds/${LATEST_BUILD}/downloads/paper-${PAPER_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_purpur() {
    local MC_VERSION="$1"
    local PURPUR_VERSION=$(curl -s https://api.purpurmc.org/v2/purpur | jq -r '.versions[]' | grep "$MC_VERSION" | tail -n1)
    if [ -z "$PURPUR_VERSION" ]; then
        echo "No matching Purpur version for $MC_VERSION found. Using latest."
        PURPUR_VERSION=$(curl -s https://api.purpurmc.org/v2/purpur | jq -r '.versions[-1]')
    fi
    echo "Installing Purpur ${PURPUR_VERSION}"
    download_file "https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}/latest/download" "server.jar"
}

install_spigot() {
    local MC_VERSION="$1"
    echo "Installing Spigot placeholder for $MC_VERSION"
    echo "Please integrate Spigot BuildTools if needed."
    # Kein echter Download hier, da Spigot kein direktes Download-API hat.
}

install_vanilla() {
    local MC_VERSION="$1"
    echo "Installing Vanilla Minecraft ${MC_VERSION}"
    download_file "https://s3.amazonaws.com/Minecraft.Download/versions/${MC_VERSION}/minecraft_server.${MC_VERSION}.jar" "server.jar"
}

install_forge() {
    local MC_VERSION="$1"
    local FORGE_VERSION="$2"
    echo "Installing Forge ${MC_VERSION}-${FORGE_VERSION}"
    local DOWNLOAD_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${MC_VERSION}-${FORGE_VERSION}/forge-${MC_VERSION}-${FORGE_VERSION}-installer.jar"
    download_file "${DOWNLOAD_URL}" "forge-installer.jar"
    java -jar forge-installer.jar --installServer
    mv forge-*.jar server.jar
    rm forge-installer.jar
}

install_fabric() {
    local MC_VERSION="$1"
    local FABRIC_VERSION="$2"
    echo "Fabric installation placeholder. Integrate actual fabric installer logic soon."
}

install_neoforge() {
    local MC_VERSION="$1"
    local NEOFORGE_VERSION="$2"
    echo "Installing NeoForge ${MC_VERSION}-${NEOFORGE_VERSION}"
    # Analog zu Forge:
    local DOWNLOAD_URL="https://maven.neoforged.net/net/neoforged/neoforge/${MC_VERSION}-${NEOFORGE_VERSION}/neoforge-${MC_VERSION}-${NEOFORGE_VERSION}-installer.jar"
    download_file "${DOWNLOAD_URL}" "neoforge-installer.jar"
    java -jar neoforge-installer.jar --installServer
    mv neoforge-*.jar server.jar
    rm neoforge-installer.jar
}

install_velocity() {
    local MC_VERSION="$1"
    # Velocity MC-Version ist eigentlich nicht zwingend relevant, da Proxy.
    local VELOCITY_VERSION=$(curl -s https://api.papermc.io/v2/projects/velocity | jq -r '.versions[-1]')
    local LATEST_BUILD=$(curl -s "https://api.papermc.io/v2/projects/velocity/versions/${VELOCITY_VERSION}" | jq -r '.builds[-1]')
    echo "Installing Velocity ${VELOCITY_VERSION}-${LATEST_BUILD}"
    download_file "https://api.papermc.io/v2/projects/velocity/versions/${VELOCITY_VERSION}/builds/${LATEST_BUILD}/downloads/velocity-${VELOCITY_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_waterfall() {
    local MC_VERSION="$1"
    local WATERFALL_VERSION=$(curl -s https://papermc.io/api/v2/projects/waterfall | jq -r '.versions[-1]')
    local LATEST_BUILD=$(curl -s "https://papermc.io/api/v2/projects/waterfall/versions/${WATERFALL_VERSION}" | jq -r '.builds[-1]')
    echo "Installing Waterfall ${WATERFALL_VERSION}-${LATEST_BUILD}"
    download_file "https://papermc.io/api/v2/projects/waterfall/versions/${WATERFALL_VERSION}/builds/${LATEST_BUILD}/downloads/waterfall-${WATERFALL_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_bungeecord() {
    local MC_VERSION="$1"
    local BUNGEE_BUILD=$(curl -s https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/buildNumber)
    echo "Installing Bungeecord build ${BUNGEE_BUILD}"
    download_file "https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/BungeeCord.jar" "server.jar"
}


############################################
# Hilfsfunktionen Menü
############################################

save_selection() {
    # Parameter: category, software, mc_version, subversion
    # z.B. "Java:Forge:1.20.1:46.0.14"
    echo "$1:$2:$3:$4" > "$SELECTION_FILE"
    echo "Selection saved: $1 - $2 - $3 - $4"
}

create_start_script() {
    cat > start.sh <<EOF
#!/bin/bash
MODIFIED_STARTUP=\`eval echo \$(echo \${STARTUP} | sed -e 's/{{/\${/g' -e 's/}}/}/g')\`
echo ":/home/container \$ \${MODIFIED_STARTUP}"
\${MODIFIED_STARTUP}
EOF
    chmod +x start.sh
    echo "start.sh created."
}

menu_minecraft_proxy() {
    header
    echo "=== Minecraft Proxy Installation ==="
    echo "1) Install Velocity"
    echo "2) Install Waterfall"
    echo "3) Install Bungeecord"
    echo "0) Back"
    echo -n "Select an option: "
    read -r option

    select_minecraft_version

    case $option in
        1) install_velocity "$MC_VERSION"; save_selection "Proxy" "Velocity" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        2) install_waterfall "$MC_VERSION"; save_selection "Proxy" "Waterfall" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        3) install_bungeecord "$MC_VERSION"; save_selection "Proxy" "Bungeecord" "$MC_VERSION" ""; create_start_script; exit 0 ;;
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
    echo "7) Install NeoForge"
    echo "0) Back"
    echo -n "Select an option: "
    read -r option

    select_minecraft_version

    case $option in
        1) install_paper "$MC_VERSION"; save_selection "Java" "PaperMC" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        2) install_purpur "$MC_VERSION"; save_selection "Java" "Purpur" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        3) install_spigot "$MC_VERSION"; save_selection "Java" "Spigot" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        4) install_vanilla "$MC_VERSION"; save_selection "Java" "Vanilla" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        5) # Forge: erst Subversion wählen
           FORGE_VERSION=$(select_forge_version "$MC_VERSION")
           install_forge "$MC_VERSION" "$FORGE_VERSION"
           save_selection "Java" "Forge" "$MC_VERSION" "$FORGE_VERSION"
           create_start_script
           exit 0
           ;;
        6) # Fabric: erst Subversion wählen
           FABRIC_VERSION=$(select_fabric_version "$MC_VERSION")
           install_fabric "$MC_VERSION" "$FABRIC_VERSION"
           save_selection "Java" "Fabric" "$MC_VERSION" "$FABRIC_VERSION"
           create_start_script
           exit 0
           ;;
        7) # NeoForge: Subversion wählen
           NEOFORGE_VERSION=$(select_neoforge_version "$MC_VERSION")
           install_neoforge "$MC_VERSION" "$NEOFORGE_VERSION"
           save_selection "Java" "NeoForge" "$MC_VERSION" "$NEOFORGE_VERSION"
           create_start_script
           exit 0
           ;;
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

# Prüfen, ob schon eine Auswahl getroffen wurde
if [ -f "$SELECTION_FILE" ]; then
    # Datei existiert, also direkt start.sh ausführen (sofern start.sh existieren)
    if [ -f "start.sh" ]; then
        echo "Using previously selected server configuration..."
        ./start.sh
        exit 0
    else
        # Falls aus irgendeinem Grund start.sh fehlt, neu installieren
        rm -f "$SELECTION_FILE"
        main_menu
    fi
else
    # Keine Auswahl -> Menü anzeigen
    main_menu
fi