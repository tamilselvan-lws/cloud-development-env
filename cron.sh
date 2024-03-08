#!/bin/bash
##---------- Author : Thirumoorthi Duraipandi------------------------------------------------##
##---------- Email : thirumoorthi.duraipandi@ladybirdweb.com---------------------------------##
##---------- Purpose : Agent Discovery script for macOS machines.----------------------------##
##---------- Tested on : macOS, Febora, Alma------------------## 
##---------- Initial version : v1.0 (Updated on 4th March 2024) -----------------------------##
##-----NOTE: This script requires root privileges, otherwise one could run the script -------##
##---------- as a sudo user who got root privileges. ----------------------------------------##
##----USAGE: "sudo /bin/bash cron.sh" -------------------------------------------------------##

## 	Banner
echo -e "\n\n\n" 
echo -e "  █████╗  ██████╗ ███████╗███╗   ██╗████████╗                           "
echo -e " ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝                           "
echo -e " ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║                              "
echo -e " ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║                              "
echo -e " ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║                              "
echo -e " ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝                              "
echo -e "                                                                        "
echo -e " ██████╗ ██╗███████╗ ██████╗ ██████╗ ██╗   ██╗███████╗██████╗ ██╗   ██╗ "
echo -e " ██╔══██╗██║██╔════╝██╔════╝██╔═══██╗██║   ██║██╔════╝██╔══██╗╚██╗ ██╔╝ "
echo -e " ██║  ██║██║███████╗██║     ██║   ██║██║   ██║█████╗  ██████╔╝ ╚████╔╝  "
echo -e " ██║  ██║██║╚════██║██║     ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗  ╚██╔╝   "
echo -e " ██████╔╝██║███████║╚██████╗╚██████╔╝ ╚████╔╝ ███████╗██║  ██║   ██║    "
echo -e " ╚═════╝ ╚═╝╚══════╝ ╚═════╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝    "
echo -e "\n\n\n"
                                                                     

#!/bin/bash

# Directory and file creation checks
current_dir=$PWD
script_dir="/etc/faveo-agent"
agent_file="$PWD/agent-discovery.sh"

if [ ! -d "$script_dir" ]; then
    # Create directory for faveo-agent and set permissions.
    mkdir -p "$script_dir"
    chmod -R 777 "$script_dir"
fi

if [ ! -f "$script_dir/$(basename "$agent_file")" ]; then
    # Copy the script to faveo-agent directory.
    cp "$agent_file" "$script_dir"
fi

# Function to create launchd plist file
create_launchd_plist() {
    local interval_choice
    local interval
    local cron_time
    local plist_file="$HOME/Library/LaunchAgents/com.example.agent-discovery.plist"

    echo "Select the cron interval:"
    echo "1. Daily"  #THIS CRON IS FOR EVERYDAY
    echo "2. Weekly"  #THIS CRON IS FOR EVERY WEEK AT SPECIFIED DAY IN THE BELOW INTERVAL CHOICE
    echo "3. Monthly"  #THIS CRON IS FOR EVERY MONTH AT SPECIFIED DATE IN THE BELOW INTERVAL CHOICE
    read -r interval_choice

    # Determine the interval based on user's choice
    case $interval_choice in
        1) interval="day";;
        2) interval="week";;
        3) interval="month";;
        *) echo "Invalid selection. Please select a valid option."; return;;
    esac

    # Prompt the user for custom cron time
    echo "Enter the time of day to run the cron job (in 24-hour format, e.g. 23:30) or press Enter to use the default time of midnight:"
    read -r time_input

    # Convert the user input to launchd time format
    if [ -z "$time_input" ]; then
        cron_time="0 0"
    else
        if [[ "$time_input" =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]]; then
            cron_time="${BASH_REMATCH[2]} ${BASH_REMATCH[1]}"
        else
            echo "Invalid time format. Please enter the time in 24-hour format, e.g. 23:30"
            return
        fi
    fi

    # Create the launchd plist file
    cat > "$plist_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.agent-discovery</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${script_dir}/agent-discovery.sh</string>
    </array>
    <key>StandardOutPath</key>
    <string>${script_dir}/agent-cron.log</string>
    <key>StandardErrorPath</key>
    <string>${script_dir}/agent-cron.log</string>
    <key>StartCalendarInterval</key>
    <dict>
        <key>${interval}</key>
        <true/>
        <key>Hour</key>
        <integer>${cron_time}</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>
EOF

    # Load the launchd plist file
    launchctl load "$plist_file"
    echo "Launchd plist file created and loaded successfully."
}

# Function to remove launchd plist file
remove_launchd_plist() {
    local plist_file="$HOME/Library/LaunchAgents/com.example.agent-discovery.plist"

    if [ -f "$plist_file" ]; then
        launchctl unload "$plist_file"
        rm "$plist_file"
        echo "Launchd plist file removed."
    else
        echo "Launchd plist file not found."
    fi
}

# Function to add or remove the launchd plist
add_or_remove_launchd() {
    echo "Do you want to install or uninstall Agent Discovery?"
    echo "1. Install"
    echo "2. Uninstall"
    read -r choice

    case $choice in
        1) create_launchd_plist;;
        2) remove_launchd_plist;;
        *) echo "Invalid choice. Please enter '1' or '2'."; return;;
    esac
}

# Main function
add_or_remove_launchd