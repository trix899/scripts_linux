#!/bin/bash

# Color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if cifs-utils is installed
function check_cifs_utils {
    if ! dpkg -s cifs-utils > /dev/null 2>&1; then
        echo -e "${RED}Error:${NC} cifs-utils is not installed."
        read -p "Do you want to install cifs-utils now? (y/n): " install_cifs
        if [[ "$install_cifs" == "y" || "$install_cifs" == "Y" ]]; then
            sudo apt-get update
            sudo apt-get install -y cifs-utils
            if [ $? -ne 0 ]; then
                echo -e "${RED}Error:${NC} Failed to install cifs-utils. Aborting."
                exit 1
            fi
        else
            echo "Please install cifs-utils manually and run the script again."
            exit 1
        fi
    fi
}

# Function to list available shares on the SMB server
function list_shares {
    local ip_address="$1"
    smbclient -L "$ip_address" -N 2>/dev/null | awk '/Disk/{print $1}' | grep -v 'Disk|----' | sed 's/\$//'
}

# Function to validate IP address
function validate_ip {
    local ip="$1"
    if [[ ! "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error:${NC} Invalid IP address format: $ip"
        exit 1
    fi
}

# Function to mount SMB share
function mount_share {
    local ip_address="$1"
    local share_name="$2"
    local password="$3"
    local mount_dir="/mnt/${share_name}"

    # Create mount directory if it doesn't exist
    if [ ! -d "$mount_dir" ]; then
        sudo mkdir -p "$mount_dir"
    fi

    # Mount the SMB share
    sudo mount -t cifs //"$ip_address"/"$share_name" "$mount_dir" -o username=,password="$password",vers=3.0

    # Check if mount was successful
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Success:${NC} SMB share '$share_name' mounted successfully at ${mount_dir}."
    else
        echo -e "${RED}Error:${NC} Failed to mount SMB share '$share_name'."
        exit 1
    fi
}

# Function to create symbolic link in user's home directory
function create_symlink {
    local share_name="$1"
    local symlink_name="$2"
    local mount_dir="/mnt/${share_name}"
    local user_home="$(eval echo ~$USER)"

    # Create symbolic link
    ln -s "$mount_dir" "$user_home/$symlink_name"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Success:${NC} Symbolic link '$symlink_name' created in $user_home pointing to '$mount_dir'."
    else
        echo -e "${RED}Error:${NC} Failed to create symbolic link."
    fi
}

# Main script starts here

# Section header
echo -e "${YELLOW}### Mount SMB Share Script ###${NC}"

# Prompt for IP address
read -p "Enter the IP address of the SMB server: " ip_address
validate_ip "$ip_address"

# Check if cifs-utils is installed
check_cifs_utils

# List available shares on the server
echo -e "Fetching available shares from ${GREEN}$ip_address${NC}..."
shares=($(list_shares "$ip_address"))

# Check if any shares were found
if [ ${#shares[@]} -eq 0 ]; then
    echo -e "${RED}Error:${NC} No shares found on $ip_address."
    exit 1
fi

# Display available shares and prompt for selection
echo
echo -e "Available shares on ${GREEN}$ip_address${NC}:"
for ((i=0; i<${#shares[@]}; i++)); do
    echo "$((i+1)). ${shares[i]}"
done

# Prompt for share selection
read -p "Enter the number of the share to mount: " share_choice

# Validate user input
if ! [[ "$share_choice" =~ ^[0-9]+$ ]] || (( share_choice < 1 || share_choice > ${#shares[@]} )); then
    echo -e "${RED}Error:${NC} Invalid choice. Please enter a valid number."
    exit 1
fi

# Select the share based on user's choice
share_name="${shares[$((share_choice-1))]}"
echo -e "Selected share: ${GREEN}$share_name${NC}"

# Prompt for password (note: use -s to hide input for security)
read -s -p "Enter the password for $share_name: " password
echo # move to a new line after password input

# Mount the selected SMB share
mount_share "$ip_address" "$share_name" "$password"

# Ask if user wants to mount on boot
read -p "Do you want to mount this share on boot? (y/n): " mount_on_boot

if [[ "$mount_on_boot" == "y" || "$mount_on_boot" == "Y" ]]; then
    # Add entry to /etc/fstab for auto-mount on boot
    echo -e "Adding mount entry to ${GREEN}/etc/fstab${NC}..."
    echo "//${ip_address}/${share_name} ${mount_dir} cifs credentials=/etc/.smbcredentials,vers=3.0 0 0" | sudo tee -a /etc/fstab > /dev/null

    # Create credentials file with username and password (replace with actual username if needed)
    echo "username=${share_name}" | sudo tee /etc/.smbcredentials > /dev/null
    echo "password=${password}" | sudo tee -a /etc/.smbcredentials > /dev/null

    # Secure permissions on credentials file
    sudo chmod 600 /etc/.smbcredentials

    echo -e "${GREEN}Success:${NC} SMB share '$share_name' will be mounted on boot."
else
    echo -e "${YELLOW}Warning:${NC} SMB share '$share_name' will not be mounted on boot."
fi

# Ask if user wants to create a symbolic link in their home directory
read -p "Do you want to create a symbolic link to this share in your home directory? (y/n): " create_symlink_choice

if [[ "$create_symlink_choice" == "y" || "$create_symlink_choice" == "Y" ]]; then
    read -p "Enter a name for the symbolic link (default: $share_name): " symlink_name
    symlink_name="${symlink_name:-$share_name}"  # Use default share name if no input provided
    create_symlink "$share_name" "$symlink_name"
else
    echo -e "${YELLOW}Warning:${NC} No symbolic link created."
fi

echo -e "${GREEN}### Mount and Symlink Creation Completed Successfully ###${NC}"
