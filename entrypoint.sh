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

eula_check() {
    echo "Do you accept the EULA? (yes/no)"
    read -r EULA_ANSWER
    if [ "$EULA_ANSWER" != "yes" ]; then
        echo "You must accept the EULA to continue."
        exit 1
    fi
    echo "eula=true" > eula.txt
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

print_in_columns() {
    list=($1)
    count=0
    for v in "${list[@]}"; do
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

get_all_versions() {
    local TYPE="$1"
    JSON=$(curl -s "https://versions.mcjars.app/api/v2/lookups/versions/${TYPE}")
    if [ -z "$JSON" ] || [ "$(echo "$JSON" | jq -r '.success')" != "true" ]; then
        echo "Failed to fetch versions for ${TYPE}"
        exit 1
    fi
    ALL_VERSIONS=$(echo "$JSON" | jq -r '.versions | keys[]')
    echo "$ALL_VERSIONS"
}

filter_vanilla_full() {
    grep -E '^[0-9].*' | grep -v 'w' | grep -v 'pre' | grep -v 'rc'
}

filter_vanilla_snapshot() {
    grep 'w'
}

filter_vanilla_prerelease() {
    grep -E 'pre|rc'
}

# Neue download_from_mcjars Funktion mit dem neuen Endpunkt
download_from_mcjars() {
    local TYPE="$1"
    local MC_VERSION="$2"
    JSON=$(curl -s "https://versions.mcjars.app/api/v2/builds/${TYPE}/${MC_VERSION}")
    if [ -z "$JSON" ] || [ "$(echo "$JSON" | jq -r '.success')" != "true" ]; then
        echo "Failed to fetch data for ${TYPE}/${MC_VERSION}"
        exit 1
    fi
    JAR_URL=$(echo "$JSON" | jq -r '.builds[0].jarUrl')
    if [ "$JAR_URL" = "null" ]; then
        echo "Version $MC_VERSION not found for $TYPE"
        exit 1
    fi
    download_file "$JAR_URL" "server.jar"
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

install_neoforge() {
    NEOFORGE_VERSION="$1"
    echo "Installing NeoForge ${NEOFORGE_VERSION}"
    DOWNLOAD_URL="https://maven.neoforged.net/releases/net/neoforged/neoforge/${NEOFORGE_VERSION}/neoforge-${NEOFORGE_VERSION}-installer.jar"
    download_file "${DOWNLOAD_URL}" "neoforge-installer.jar"
    java -jar neoforge-installer.jar --installServer
    mv neoforge-*.jar server.jar 2>/dev/null || true
    rm neoforge-installer.jar
}


menu_plugins() {
    header
    echo "=== Plugins (Bukkit-like) ==="
    echo "1) Paper"
    echo "2) Pufferfish"
    echo "3) Spigot"
    echo "4) Folia"
    echo "5) Purpur"
    echo "6) Quilt"
    echo "7) Canvas"
    echo "0) Back"
    echo "Select an option: "
    read -r option

    case $option in
        1) TYPE="PAPER" ;;
        2) TYPE="PUFFERFISH" ;;
        3) TYPE="SPIGOT" ;;
        4) TYPE="FOLIA" ;;
        5) TYPE="PURPUR" ;;
        6) TYPE="QUILT" ;;
        7) TYPE="CANVAS" ;;
        0) menu_main; return ;;
        *) echo "Invalid option!"; sleep 1; menu_plugins; return ;;
    esac

    ALL_VERSIONS=$(get_all_versions "$TYPE")
    echo "Available Minecraft versions for $TYPE:"
    print_in_columns "$(echo "$ALL_VERSIONS")"
    echo "Please enter a Minecraft version from the above list:"
    read -r MC_VERSION
    eula_check
    download_from_mcjars "$TYPE" "$MC_VERSION"
    save_selection "Plugins" "$TYPE" "$MC_VERSION" ""
    create_start_script
    exit 0
}

menu_vanilla() {
    header
    echo "=== Vanilla Options ==="
    echo "1) Full versions"
    echo "2) Snapshots"
    echo "3) Pre-Releases"
    echo "4) Leaves"
    echo "0) Back"
    echo "Select an option: "
    read -r option

    if [ $option -eq 4 ]; then
        TYPE="LEAVES"
        ALL_VERSIONS=$(get_all_versions "$TYPE")
        echo "Available versions for LEAVES:"
        print_in_columns "$(echo "$ALL_VERSIONS")"
        echo "Please enter a Minecraft version:"
        read -r MC_VERSION
        eula_check
        download_from_mcjars "$TYPE" "$MC_VERSION"
        save_selection "Vanilla" "Leaves" "$MC_VERSION" ""
        create_start_script
        exit 0
    else
        TYPE="VANILLA"
        ALL_VERSIONS=$(get_all_versions "$TYPE")
        case $option in
            1) FILTERED=$(echo "$ALL_VERSIONS" | filter_vanilla_full) ; CATEGORY="Vanilla-Full" ;;
            2) FILTERED=$(echo "$ALL_VERSIONS" | filter_vanilla_snapshot) ; CATEGORY="Vanilla-Snapshot" ;;
            3) FILTERED=$(echo "$ALL_VERSIONS" | filter_vanilla_prerelease) ; CATEGORY="Vanilla-PreRelease" ;;
            0) menu_main; return ;;
            *) echo "Invalid option!"; sleep 1; menu_vanilla; return ;;
        esac

        if [ -z "$FILTERED" ]; then
            echo "No matching versions found."
            sleep 1
            menu_vanilla
            return
        fi

        echo "Available versions:"
        print_in_columns "$(echo "$FILTERED")"
        echo "Please enter a Minecraft version from the above list:"
        read -r MC_VERSION
        eula_check
        download_from_mcjars "$TYPE" "$MC_VERSION"
        save_selection "Vanilla" "$CATEGORY" "$MC_VERSION" ""
        create_start_script
        exit 0
    fi
}

menu_modded() {
    header
    echo "=== Modded Options ==="
    echo "1) Forge"
    echo "2) NeoForge"
    echo "3) Fabric"
    echo "4) Mohist"
    echo "5) Sponge"
    echo "0) Back"
    echo "Select an option: "
    read -r option

    case $option in
        1)
            echo "Please enter the desired Minecraft version (e.g. 1.20.1):"
            read -r MC_VERSION
            print_forge_versions "$MC_VERSION"
            read -r -p "Please choose a Forge version: " FORGE_VERSION
            if ! print_forge_versions "$MC_VERSION" | grep -wq "$FORGE_VERSION"; then echo "Invalid Forge version selected!"; exit 1; fi
            eula_check
            install_forge "$MC_VERSION" "$FORGE_VERSION"
            save_selection "Modded" "Forge" "$MC_VERSION" "$FORGE_VERSION"
            exit 0
            ;;
        2)
            echo "Please enter the desired Minecraft version (e.g. 1.20.1):"
            read -r MC_VERSION
            print_neoforge_versions_new "$MC_VERSION"
            read -r -p "Please choose a NeoForge version: " NEOFORGE_VERSION
            if ! print_neoforge_versions_new "$MC_VERSION" | grep -wq "$NEOFORGE_VERSION"; then echo "Invalid NeoForge version selected!"; exit 1; fi
            eula_check
            install_neoforge "$NEOFORGE_VERSION"
            save_selection "Modded" "NeoForge" "$MC_VERSION" "$NEOFORGE_VERSION"
            exit 0
            ;;
        3)
            TYPE="FABRIC"
            ALL_VERSIONS=$(get_all_versions "$TYPE")
            echo "Available Minecraft versions for $TYPE:"
            print_in_columns "$(echo "$ALL_VERSIONS")"
            echo "Please enter a Minecraft version:"
            read -r MC_VERSION
            eula_check
            download_from_mcjars "$TYPE" "$MC_VERSION"
            save_selection "Modded" "Fabric" "$MC_VERSION" ""
            create_start_script
            exit 0
            ;;
        4)
            TYPE="MOHIST"
            ALL_VERSIONS=$(get_all_versions "$TYPE")
            echo "Available Minecraft versions for $TYPE:"
            print_in_columns "$(echo "$ALL_VERSIONS")"
            echo "Please enter a Minecraft version:"
            read -r MC_VERSION
            eula_check
            download_from_mcjars "$TYPE" "$MC_VERSION"
            save_selection "Modded" "Mohist" "$MC_VERSION" ""
            create_start_script
            exit 0
            ;;
        5)
            TYPE="SPONGE"
            ALL_VERSIONS=$(get_all_versions "$TYPE")
            echo "Available Minecraft versions for $TYPE:"
            print_in_columns "$(echo "$ALL_VERSIONS")"
            echo "Please enter a Minecraft version:"
            read -r MC_VERSION
            eula_check
            download_from_mcjars "$TYPE" "$MC_VERSION"
            save_selection "Modded" "Sponge" "$MC_VERSION" ""
            create_start_script
            exit 0
            ;;
        0) menu_main ;;
        *) echo "Invalid option!"; sleep 1; menu_modded ;;
    esac
}

menu_main() {
    header
    echo "=== Main Menu ==="
    echo "1) Plugins (Paper, Purpur, Spigot, etc.)"
    echo "2) Vanilla (Full, Snapshots, Pre-Releases, Leaves)"
    echo "3) Modded (Forge, NeoForge, Fabric, Mohist, Sponge)"
    echo "0) Exit"
    echo "Select an option: "
    read -r option
    case $option in
        1) menu_plugins ;;
        2) menu_vanilla ;;
        3) menu_modded ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option!"; sleep 1; menu_main ;;
    esac
}

if [ -f "$SELECTION_FILE" ]; then
    ./run.sh
    exit 0
else
    menu_main
fi
