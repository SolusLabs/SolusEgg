#!/bin/bash

# Arbeitsverzeichnis festlegen
cd /home/container

# Pfad zur Auswahldatei
SELECTION_FILE="/home/container/.selected_minecraft"

# Funktion zur Abfrage von Eingaben
get_input() {
    local prompt="$1"
    read -p "$prompt" input
    echo $input
}

# Funktion zum Abrufen der verfügbaren Minecraft-Versionen
list_mc_versions() {
    local url="https://launchermeta.mojang.com/mc/game/version_manifest.json"
    curl -s "$url" | jq -r '.versions[] | select(.type == "release") | .id'
}

# Funktion zum Abrufen von Server-Versionen anderer Software
list_server_versions() {
    local software=$1
    case $software in
        "Paper")
            curl -s "https://papermc.io/api/v2/projects/paper" | jq -r '.versions[]'
            ;;
        "Purpur")
            curl -s "https://api.purpurmc.org/v2/purpur" | jq -r '.versions[]'
            ;;
        "Forge")
            curl -s "https://maven.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json" | jq -r '.promos | keys[] | select(contains("latest")) | split("-")[0]'
            ;;
        "Fabric")
            curl -s "https://meta.fabricmc.net/v2/versions/game" | jq -r '.[].version'
            ;;
        *)
            echo "Keine unterstützte Software für Versionen gefunden."
            ;;
    esac
}

# Funktion zum Herunterladen und Installieren der Software
download_and_install() {
    local category=$1
    local software=$2
    local version=$3
    local mc_version=$4

    echo "\nDownloading and installing $software $version for Minecraft $mc_version in category $category..."
    
    case $category in
        "Bukkit" | "Plugins")
            wget -O server.jar "https://papermc.io/api/v2/projects/$software/versions/$mc_version/builds/$version/downloads/$software-$version.jar"
            ;;
        "Vanilla")
            wget -O server.jar "https://s3.amazonaws.com/Minecraft.Download/versions/$mc_version/minecraft_server.$mc_version.jar"
            ;;
        "Modded")
            case $software in
                "Forge")
                    wget -O installer.jar "https://maven.minecraftforge.net/net/minecraftforge/forge/$mc_version-$version/forge-$mc_version-$version-installer.jar"
                    java -jar installer.jar --installServer
                    rm installer.jar
                    ;;
                "Fabric")
                    wget -O installer.jar "https://maven.fabricmc.net/net/fabricmc/fabric-installer/$version/fabric-installer-$version.jar"
                    java -jar installer.jar server -mcversion $mc_version
                    rm installer.jar
                    ;;
            esac
            ;;
    esac

    echo "Installation complete."
}

# Funktion zur Erstellung der Startdatei
create_start_script() {
    local category=$1
    local software=$2
    local version=$3

    echo "#!/bin/bash" > start.sh
    echo "java -Xms1G -Xmx2G -jar server.jar nogui" >> start.sh
    chmod +x start.sh
}

# Wenn noch keine Auswahl getroffen wurde
if [ ! -f "$SELECTION_FILE" ]; then
    BLUE='\033[0;34m' 
    clear
    echo -e "
    
    ==========================================================================
    
    ${BLUE}░██████╗░█████╗░██╗░░░░░██╗░░░██╗░██████╗  ██╗░░░░░░█████╗░██████╗░░██████╗
    ${BLUE}██╔════╝██╔══██╗██║░░░░░██║░░░██║██╔════╝  ██║░░░░░██╔══██╗██╔══██╗██╔════╝
    ${BLUE}╚█████╗░██║░░██║██║░░░░░██║░░░██║╚█████╗░  ██║░░░░░███████║██████╦╝╚█████╗░
    ${BLUE}░╚═══██╗██║░░██║██║░░░░░██║░░░██║░╚═══██╗  ██║░░░░░██╔══██║██╔══██╗░╚═══██╗
    ${BLUE}██████╔╝╚█████╔╝███████╗╚██████╔╝██████╔╝  ███████╗██║░░██║██████╦╝██████╔╝
    ${BLUE}╚═════╝░░╚════╝░╚══════╝░╚═════╝░╚═════╝░  ╚══════╝╚═╝░░╚═╝╚═════╝░╚═════╝░
    
    ==========================================================================

    "
    echo "Bitte wählen Sie eine Kategorie:"
    echo "1) Bukkit (oder ähnliche Plugins)"
    echo "2) Vanilla"
    echo "3) Modded (Forge, Fabric, usw.)"
    category_selection=$(get_input "Auswahl (1-3): ")

    case $category_selection in
        1)
            category="Bukkit"
            echo "Bitte wählen Sie eine Software (z.B. Paper, Purpur, Spigot):"
            software=$(get_input "Software: ")
            echo "Verfügbare Versionen für $software:"
            server_versions=$(list_server_versions "$software")
            echo "$server_versions"
            ;;
        2)
            category="Vanilla"
            software="Vanilla"
            echo "Verfügbare Minecraft-Versionen:"
            mc_versions=$(list_mc_versions)
            echo "$mc_versions"
            ;;
        3)
            category="Modded"
            echo "Bitte wählen Sie eine Modding-Plattform (Forge, Fabric):"
            software=$(get_input "Modding-Plattform: ")
            echo "Verfügbare Versionen für $software:"
            server_versions=$(list_server_versions "$software")
            echo "$server_versions"
            ;;
        *)
            echo "Ungültige Auswahl."
            exit 1
            ;;
    esac

    echo "Bitte wählen Sie die Minecraft-Version (Drücken Sie Enter für die neueste Version):"
    mc_version=$(get_input "Minecraft-Version: ")
    if [ -z "$mc_version" ]; then
        mc_version=$(echo "$mc_versions" | head -n 1)
    fi

    echo "Bitte geben Sie die Software-Version an (Drücken Sie Enter für die neueste Version):"
    version=$(get_input "Software-Version: ")
    if [ -z "$version" ]; then
        version=$(echo "$server_versions" | head -n 1)
    fi

    echo "Bitte wählen Sie die Java-Version (8, 11, 17, 21):"
    java_version=$(get_input "Java-Version: ")
    if [ -z "$java_version" ]; then
        java_version="21"
    fi

    echo "Bitte akzeptieren Sie die EULA (ja/nein):"
    eula=$(get_input "EULA akzeptieren (ja/nein): ")

    if [ "$eula" != "ja" ]; then
        echo "Sie müssen die EULA akzeptieren, um fortzufahren."
        exit 1
    fi

    echo "eula=true" > eula.txt

    # Auswahl speichern
    echo "$category:$software:$mc_version:$version:$java_version" > "$SELECTION_FILE"

    # Herunterladen und Installieren
    download_and_install "$category" "$software" "$version" "$mc_version"

    # Startdatei erstellen
    create_start_script "$category" "$software" "$version"

else
    # Auswahl aus Datei lesen
    IFS=":" read -r category software mc_version version java_version < "$SELECTION_FILE"
    echo "Starte $software $version für Minecraft $mc_version aus Kategorie $category mit Java $java_version..."
fi

# Java-Version setzen
export JAVA_HOME="/opt/java$java_version"
export PATH="$JAVA_HOME/bin:$PATH"

# Server starten
./start.sh
