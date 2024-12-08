#!/bin/bash

BLUE='\033[0;34m'
RESET='\033[0m'
cd /home/container || exit 1
SELECTION_FILE="/home/container/.selected_minecraft"

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

download_file() {
    url="$1"
    output="$2"
    echo "Downloading: $url"
    curl -s -L -o "${output}" "${url}"
    if [ $? -ne 0 ]; then
        echo "Download failed!"
        exit 1
    fi
    echo "Download complete: ${output}"
}

select_minecraft_version() {
    echo "Please enter the desired Minecraft version (e.g. 1.21.1):"
    read -r MC_VERSION
    if [ -z "$MC_VERSION" ]; then
        MC_VERSION=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release')
    fi
    echo "Selected Minecraft version: $MC_VERSION"
}

print_in_columns() {
    list=($1)
    count=0
    for v in ${list[@]}; do
        printf "%-20s" "$v"
        count=$((count+1))
        if [ $count -eq 3 ]; then
            echo ""
            count=0
        fi
    done
    if [ $count -ne 0 ]; then
        echo ""
    fi
}

print_forge_versions() {
    MC_VERSION="$1"
    FORGE_URL="https://files.minecraftforge.net/net/minecraftforge/forge/index_${MC_VERSION}.html"
    HTML=$(curl -s "$FORGE_URL")
    if [[ "$HTML" == *"404 Not Found"* ]]; then
        echo "No Forge versions found for Minecraft $MC_VERSION."
        exit 1
    fi
    VERSIONS=$(echo "$HTML" | grep -oE "forge-${MC_VERSION}-[0-9]+\.[0-9]+\.[0-9]+" | sed "s/forge-${MC_VERSION}-//" | sort -V | uniq)
    if [ -z "$VERSIONS" ]; then
        echo "No Forge versions found for $MC_VERSION."
        exit 1
    fi
    echo ""
    echo "Available Forge versions for Minecraft $MC_VERSION:"
    print_in_columns "$(echo "$VERSIONS")"
    echo ""
}

print_fabric_versions() {
    MC_VERSION="$1"
    FABRIC_URL="https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}"
    JSON=$(curl -s "$FABRIC_URL")
    COUNT=$(echo "$JSON" | jq '. | length')
    if [ "$COUNT" -eq 0 ]; then
        echo "No Fabric loader versions found for Minecraft $MC_VERSION."
        exit 1
    fi
    FABRIC_VERSIONS=$(echo "$JSON" | jq -r '.[].loader.version')
    echo ""
    echo "Available Fabric loader versions for Minecraft $MC_VERSION:"
    print_in_columns "$(echo "$FABRIC_VERSIONS")"
    echo ""
}

print_neoforge_versions_new() {
    MC_VERSION="$1"
    RAW=$(curl -s "https://maven.neoforged.net/api/maven/versions/releases/net/neoforged/neoforge")
    ALL_NEO=$(echo "$RAW" | jq -r '.versions[]')
    PART=$(echo "$MC_VERSION" | cut -d '.' -f 2-)
    MATCH=$(echo "$ALL_NEO" | grep "^${PART}")
    if [ -z "$MATCH" ]; then
        echo "No NeoForge versions found for Minecraft $MC_VERSION."
        exit 1
    fi
    echo ""
    echo "Available NeoForge versions for Minecraft $MC_VERSION:"
    print_in_columns "$(echo "$MATCH")"
    echo ""
}

eula_check() {
    echo "Do you accept the EULA? (yes/no)"
    read -r EULA_ANSWER
    if [ "$EULA_ANSWER" != "yes" ]; then
        echo "You must accept the EULA to continue."
        exit 1
    fi
    echo "eula=true" > eula.txt
}

install_paper() {
    MC_VERSION="$1"
    PAPER_VERSION=$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions[]' | grep "$MC_VERSION" | tail -n1)
    if [ -z "$PAPER_VERSION" ]; then
        PAPER_VERSION=$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions[-1]')
    fi
    LATEST_BUILD=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}" | jq -r '.builds[-1]')
    echo "Installing PaperMC ${PAPER_VERSION}-${LATEST_BUILD}"
    download_file "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}/builds/${LATEST_BUILD}/downloads/paper-${PAPER_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_purpur() {
    MC_VERSION="$1"
    PURPUR_VERSION=$(curl -s https://api.purpurmc.org/v2/purpur | jq -r '.versions[]' | grep "$MC_VERSION" | tail -n1)
    if [ -z "$PURPUR_VERSION" ]; then
        PURPUR_VERSION=$(curl -s https://api.purpurmc.org/v2/purpur | jq -r '.versions[-1]')
    fi
    echo "Installing Purpur ${PURPUR_VERSION}"
    download_file "https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}/latest/download" "server.jar"
}

install_spigot() {
    MC_VERSION="$1"
    echo "Installing Spigot placeholder for $MC_VERSION"
}

install_vanilla() {
    MC_VERSION="$1"
    echo "Installing Vanilla Minecraft ${MC_VERSION}"
    download_file "https://s3.amazonaws.com/Minecraft.Download/versions/${MC_VERSION}/minecraft_server.${MC_VERSION}.jar" "server.jar"
}

install_forge() {
    MC_VERSION="$1"
    FORGE_VERSION="$2"
    echo "Installing Forge ${MC_VERSION}-${FORGE_VERSION}"
    DOWNLOAD_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${MC_VERSION}-${FORGE_VERSION}/forge-${MC_VERSION}-${FORGE_VERSION}-installer.jar"
    download_file "${DOWNLOAD_URL}" "forge-installer.jar"
    java -jar forge-installer.jar --installServer
    mv forge-*.jar server.jar 2>/dev/null || true
    rm forge-installer.jar
}

install_fabric() {
    MC_VERSION="$1"
    FABRIC_VERSION="$2"
    echo "Installing Fabric Loader ${FABRIC_VERSION} for Minecraft ${MC_VERSION}"
    FABRIC_PROFILE_URL="https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}/${FABRIC_VERSION}/profile/json"
    download_file "${FABRIC_PROFILE_URL}" "fabric-installer.json"
}

install_neoforge() {
    NEOFORGE_VERSION="$1"
    echo "Installing NeoForge ${NEOFORGE_VERSION}"
    DOWNLOAD_URL="https://maven.neoforged.net/releases/net/neoforged/neoforge/${NEOFORGE_VERSION}/neoforge-${NEOFORGE_VERSION}-installer.jar"
    download_file "${DOWNLOAD_URL}" "neoforge-installer.jar"
    java -jar neoforge-installer.jar --installServer
    mv neoforge-*.jar server.jar 2>/dev/null || true
    rm neoforge-installer.jar
}

install_velocity() {
    MC_VERSION="$1"
    VELOCITY_VERSION=$(curl -s https://api.papermc.io/v2/projects/velocity | jq -r '.versions[-1]')
    LATEST_BUILD=$(curl -s "https://api.papermc.io/v2/projects/velocity/versions/${VELOCITY_VERSION}" | jq -r '.builds[-1]')
    echo "Installing Velocity ${VELOCITY_VERSION}-${LATEST_BUILD}"
    download_file "https://api.papermc.io/v2/projects/velocity/versions/${VELOCITY_VERSION}/builds/${LATEST_BUILD}/downloads/velocity-${VELOCITY_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_waterfall() {
    MC_VERSION="$1"
    WATERFALL_VERSION=$(curl -s https://papermc.io/api/v2/projects/waterfall | jq -r '.versions[-1]')
    LATEST_BUILD=$(curl -s "https://papermc.io/api/v2/projects/waterfall/versions/${WATERFALL_VERSION}" | jq -r '.builds[-1]')
    echo "Installing Waterfall ${WATERFALL_VERSION}-${LATEST_BUILD}"
    download_file "https://papermc.io/api/v2/projects/waterfall/versions/${WATERFALL_VERSION}/builds/${LATEST_BUILD}/downloads/waterfall-${WATERFALL_VERSION}-${LATEST_BUILD}.jar" "server.jar"
}

install_bungeecord() {
    MC_VERSION="$1"
    BUNGEE_BUILD=$(curl -s https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/buildNumber)
    echo "Installing Bungeecord build ${BUNGEE_BUILD}"
    download_file "https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/BungeeCord.jar" "server.jar"
}

save_selection() {
    echo "$1:$2:$3:$4" > "$SELECTION_FILE"
    echo "Selection saved: $1 - $2 - $3 - $4"
}

create_start_script() {
    cat > run.sh <<EOF
#!/bin/bash
MODIFIED_STARTUP=\`eval echo \$(echo \${STARTUP} | sed -e 's/{{/\${/g' -e 's/}}/}/g')\`
echo ":/home/container \$ \${MODIFIED_STARTUP}"
\${MODIFIED_STARTUP}
EOF
    chmod +x run.sh
    echo "run.sh created."
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
        1) eula_check; install_velocity "$MC_VERSION"; save_selection "Proxy" "Velocity" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        2) eula_check; install_waterfall "$MC_VERSION"; save_selection "Proxy" "Waterfall" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        3) eula_check; install_bungeecord "$MC_VERSION"; save_selection "Proxy" "Bungeecord" "$MC_VERSION" ""; create_start_script; exit 0 ;;
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
        1) eula_check; install_paper "$MC_VERSION"; save_selection "Java" "PaperMC" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        2) eula_check; install_purpur "$MC_VERSION"; save_selection "Java" "Purpur" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        3) eula_check; install_spigot "$MC_VERSION"; save_selection "Java" "Spigot" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        4) eula_check; install_vanilla "$MC_VERSION"; save_selection "Java" "Vanilla" "$MC_VERSION" ""; create_start_script; exit 0 ;;
        5) print_forge_versions "$MC_VERSION"; read -r -p "Please choose a Forge version: " FORGE_VERSION; if ! print_forge_versions "$MC_VERSION" | grep -wq "$FORGE_VERSION"; then echo "Invalid Forge version selected!"; exit 1; fi; eula_check; install_forge "$MC_VERSION" "$FORGE_VERSION"; save_selection "Java" "Forge" "$MC_VERSION" "$FORGE_VERSION"; create_start_script; exit 0 ;;
        6) print_fabric_versions "$MC_VERSION"; read -r -p "Please choose a Fabric loader version: " FABRIC_VERSION; if ! print_fabric_versions "$MC_VERSION" | grep -wq "$FABRIC_VERSION"; then echo "Invalid Fabric version selected!"; exit 1; fi; eula_check; install_fabric "$MC_VERSION" "$FABRIC_VERSION"; save_selection "Java" "Fabric" "$MC_VERSION" "$FABRIC_VERSION"; create_start_script; exit 0 ;;
        7) print_neoforge_versions_new "$MC_VERSION"; read -r -p "Please choose a NeoForge version: " NEOFORGE_VERSION; if ! print_neoforge_versions_new "$MC_VERSION" | grep -wq "$NEOFORGE_VERSION"; then echo "Invalid NeoForge version selected!"; exit 1; fi; eula_check; install_neoforge "$NEOFORGE_VERSION"; save_selection "Java" "NeoForge" "$MC_VERSION" "$NEOFORGE_VERSION"; create_start_script; exit 0 ;;
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

eula_check() {
    echo "Do you accept the EULA? (yes/no)"
    read -r EULA_ANSWER
    if [ "$EULA_ANSWER" != "yes" ]; then
        echo "You must accept the EULA to continue."
        exit 1
    fi
    echo "eula=true" > eula.txt
}

if [ -f "$SELECTION_FILE" ]; then
    ./run.sh
    exit 0
else
    main_menu
fi
