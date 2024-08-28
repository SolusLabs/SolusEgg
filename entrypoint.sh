#!/bin/bash

################################################
#                    Colors                    #
################################################

#reset
NC='\033[0m'

#normal colors
RED='\033[0;31m'
BLACK='\033[0;30m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
DGRAY='\033[1;30m'

#light colors
LRED='\033[0;31m'
LBLACK='\033[0;30m'
LGREEN='\033[0;32m'
LYELLOW='\033[1;33m'
LBLUE='\033[1;34m'
LPURPLE='\033[1;35m'
LCYAN='\033[1;36m'
LWHITE='\033[1;37m'

#text types
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
UNDERLINE=$(tput smul)
BLINK=$(tput blink)
REV=$(tput rev)
STANDOUT=$(tput smso)

#################################################
#                   Functions                   #
#################################################

##############################
#        Display Header      #
##############################

function display_header {
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

##############################
#        Dependencies        #
##############################

load () {
  if [ -z "$JAVA_VERSION" ]; then
    echo -e "${PURPLE}No Java version set! Please choose a Java version."
    tip "You can set the Java version in the startup section to skip this prompt!"
    echo -e "${PURPLE}Recommended values:"
    echo -e "${PURPLE}Java ${LPURPLE}8${PURPLE} for Minecraft 1.12.2 or older"
    echo -e "${PURPLE}Java ${LPURPLE}11${PURPLE} for Minecraft 1.12.2 to Minecraft 1.16.5"
    echo -e "${PURPLE}Java ${LPURPLE}17${PURPLE} for Minecraft 1.17 or newer."
    read -r -p "$(echo -e "${YELLOW}Selection: ${LPURPLE}")" JAVA_VERSION
  fi
  if [ "$JAVA_VERSION" = "8" ]; then
    JAVA_VERSION="adopt@1.8-0"
  elif [ "$JAVA_VERSION" = "11" ]; then
    JAVA_VERSION="adopt@1.11.0-0"
  elif [ "$JAVA_VERSION" = "17" ]; then
    JAVA_VERSION="openjdk@1.17.0"
  fi
  echo -e "${PURPLE}Installing Java ${LPURPLE}${JAVA_VERSION}${PURPLE}!"
  jabba install "$JAVA_VERSION" >> /dev/null 2>&1
  sleep 0.5
  jabba use "$JAVA_VERSION"
}

install_buildtools () {
  if ! [ -f "/home/container/.breaker/buildtools/BuildTools.jar" ]; then
    mkdir /home/container/.breaker/buildtools -p
    echo -e "${DGRAY}Installing BuildTools..."
    curl -s -L https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar -o /home/container/.breaker/buildtools/BuildTools.jar
  fi
}

##############################
#           Spigot           #
##############################

compile_spigot () {
  install_buildtools
  cd /home/container/.breaker/buildtools || return
  echo "${DGRAY}Compiling Spigot..."
  java -Xms256M -Xmx"${SERVER_MEMORY}"M -jar BuildTools.jar --rev "${!1}" --compile SPIGOT | awk -W interactive -v c="$DGRAY" '{ print c $0 }'
  mv /home/container/.breaker/buildtools/Spigot/Spigot-Server/target/spigot-*.jar /home/container/server.jar
  find . ! -name 'BuildTools.jar' -exec rm -rf {} + > /dev/null 2>&1
}

install_spigot () {
  load
  SPIGOT_VERSIONS_LIST=$(curl -s https://hub.spigotmc.org/versions/ | grep -i -E -w '"(.*.json)"' -o | tr '\n' ', ' | awk '{ print "[" substr($0, 1, length($0)-1) "]" }')
  ask_till_valid "${PURPLE}Please choose the Minecraft version you want to install! If you wish to view the list of available versions, enter ${YELLOW}list" "list" display_spigot_versions SPIGOT_VERSION "$(echo "${SPIGOT_VERSIONS_LIST}" | jq -r '. | map(. | sub(".json";""))')"
  echo -e "${PURPLE}Installing Spigot ${LPURPLE}${SPIGOT_VERSION}"
  compile_spigot SPIGOT_VERSION
}

display_spigot_versions () {
  if [ -z "${SPIGOT_VERSIONS_LIST+x}" ];  then
      SPIGOT_VERSIONS_LIST=$(curl -s https://hub.spigotmc.org/versions/ | grep -i -E -w '"(.*.json)"' -o | tr '\n' ', ' | awk '{ print "[" substr($0, 1, length($0)-1) "]" }')
  fi
  echo "$SPIGOT_VERSIONS_LIST" | jq -r '.[] | sub(".json";"") | select(test(".*\\..*")) | "\u001b[32m\(.)"'
}

##############################
#           Purpur           #
##############################

install_purpur () {
  PURPUR_VERSIONS_LIST=$(curl -s https://api.purpurmc.org/v2/purpur)
  ask_till_valid "${PURPLE}Please choose the Minecraft version you want to install! If you wish to view the list of available versions, enter ${YELLOW}list" "list" display_purpur_versions PURPUR_VERSION "$(echo "${PURPUR_VERSIONS_LIST}" | jq -r '.versions')"
  echo -e "${PURPLE}Installing Purpur ${LPURPLE}${PURPUR_VERSION}"
  curl -s "https://api.purpurmc.org/v2/purpur/${PURPUR_VERSION}/latest/download" -o server.jar
  echo -e "${PURPLE}Purpur installed!"
  run_jar
}

display_purpur_versions () {
  if [ -z "${PURPUR_VERSIONS_LIST+x}" ];  then
      PURPUR_VERSIONS_LIST=$(curl -s https://api.purpurmc.org/v2/purpur)
    fi
    echo "$PURPUR_VERSIONS_LIST" | jq -r '.versions | .[] | "\u001b[32m\(.)"'
}

#############################
#           Paper           #
#############################

install_paper () {
  PAPER_VERSIONS_LIST=$(curl -s https://papermc.io/api/v2/projects/paper)
  ask_till_valid "${PURPLE}Please choose the Minecraft version you want to install! If you wish to view the list of available versions, enter ${YELLOW}list" "list" display_paper_versions PAPER_VERSION "$(echo "${PAPER_VERSIONS_LIST}" | jq -r '.versions')"
  echo -e "${PURPLE}Installing PaperMC ${LPURPLE}${PAPER_VERSION}"
  LATEST_BUILD=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}" | jq -r '.builds[-1]')
  curl -s "https://papermc.io/api/v2/projects/paper/versions/${PAPER_VERSION}/builds/${LATEST_BUILD}/downloads/paper-${PAPER_VERSION}-${LATEST_BUILD}.jar" -o server.jar
  echo -e "${PURPLE}PaperMC installed!"
  run_jar
}

display_paper_versions () {
  if [ -z "${PAPER_VERSIONS_LIST+x}" ];  then
      PAPER_VERSIONS_LIST=$(curl -s https://papermc.io/api/v2/projects/paper)
  fi
  echo "$PAPER_VERSIONS_LIST" | jq -r '.versions | .[] | "\u001b[32m\(.)"'
}

##############################
#    Install Minecraft Java  #
##############################

install_minecraft_java () {
  display_header
  echo -e "${YELLOW}=============================================================="
  echo -e "              ${PURPLE}Select Minecraft Java Edition Server              "
  echo -e "${YELLOW}=============================================================="
  echo -e "${YELLOW}1${LPURPLE}) ${PURPLE}PaperMC"
  echo -e "${YELLOW}2${LPURPLE}) ${PURPLE}Purpur"
  echo -e "${YELLOW}3${LPURPLE}) ${PURPLE}Spigot"
  echo -e "${YELLOW}0${LPURPLE}) ${PURPLE}Back"

  read -r -p "$(echo -e "${PURPLE}Please select an option: ${LPURPLE}")" option

  case $option in
    1)
      echo -e "${DGRAY}Installing PaperMC${DGRAY}"
      install_paper
      ;;
    2)
      echo -e "${DGRAY}Installing Purpur${DGRAY}"
      install_purpur
      ;;
    3)
      echo -e "${DGRAY}Installing Spigot${DGRAY}"
      install_spigot
      ;;
    0)
      echo -e "${DGRAY}Going back to main menu...${DGRAY}"
      main_menu
      ;;
    *)
      echo -e "${DGRAY}Invalid option! Please choose a valid option.${DGRAY}"
      install_minecraft_java
      ;;
  esac
}

##############################
#           Server           #
##############################

run_jar () {
  echo -e "${PURPLE}Starting the Minecraft server..."
  java -Xms"${SERVER_MEMORY}"M -Xmx"${SERVER_MEMORY}"M -jar server.jar nogui
}

main_menu () {
  display_header
  echo -e "${YELLOW}=============================================================="
  echo -e "                          ${PURPLE}Main Menu                            "
  echo -e "${YELLOW}=============================================================="
  echo -e "${YELLOW}1${LPURPLE}) ${PURPLE}Install Minecraft Java Edition Server"
  echo -e "${YELLOW}0${LPURPLE}) ${PURPLE}Exit"
  
  read -r -p "$(echo -e "${PURPLE}Please select an option: ${LPURPLE}")" option
  
  case $option in
    1)
      install_minecraft_java
      ;;
    0)
      echo -e "${PURPLE}Exiting..."
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid option! Please choose a valid option."
      main_menu
      ;;
  esac
}

################################################
#                  Variables                   #
################################################

SERVER_MEMORY="${1:-1024}" # Default to 1024M if not provided

################################################
#                  Execution                   #
################################################

main_menu
