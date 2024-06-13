#!/bin/bash

# Function to install Samba packages
install_samba() {
    echo "Installing Samba and dependencies..."
    # Add commands to install Samba based on your distribution
    # For example:
    # sudo apt update && sudo apt install -y samba cifs-utils
}

# Function to create a Samba user
create_samba_user() {
    read -p "Enter the username for the Samba share: " username
    echo "Choose the group for the Samba share:"
    echo "1) sambashare"
    echo "2) users"
    read -p "Enter your choice (1 or 2): " group_choice
    
    case $group_choice in
        1)
            groupname="sambashare"
            ;;
        2)
            groupname="users"
            ;;
        *)
            echo "Invalid choice. Using default group 'users'."
            groupname="users"
            ;;
    esac
    
    sudo groupadd $groupname
    sudo usermod -aG $groupname $username
    sudo smbpasswd -a $username
}

# Function to list available disks and their sizes
list_disks() {
    echo "Available disks and their sizes:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -e "disk" -e "part" | awk '{print NR ". " $0}'
    echo "-------------------------------------------------------"
}

# Function to prompt user to select a disk for the shared folder
select_disk_for_shared_folder() {
    list_disks
    read -p "Enter the number corresponding to the disk to create the shared folder: " disk_number

    # Retrieve disk name based on user selection
    disk_name=$(lsblk -o NAME | grep -e "disk" -e "part" | sed -n "${disk_number}p")
    
    mount_point="/mnt/$disk_name"
    sudo mkdir -p $mount_point
    echo "Folder will be created on $disk_name at $mount_point"
}

# Function to create a shared directory in user's home directory
create_shared_directory_in_home() {
    read -p "Enter the name for the shared folder in your home directory: " shared_folder_name

    # Get user's home directory
    user_home=$(getent passwd $SUDO_USER | cut -d: -f6)
    
    # Create the shared directory in user's home
    shared_dir="$user_home/$shared_folder_name"
    
    # Check if directory already exists
    if [ -d "$shared_dir" ]; then
        echo "Directory $shared_dir already exists. Exiting."
        exit 1
    fi
    
    mkdir -p $shared_dir
    sudo chown $username:$groupname $shared_dir
    echo "Shared directory created at $shared_dir"
}

# Function to prompt user to choose where to create the shared directory
choose_location_for_shared_directory() {
    echo "Where would you like to create the shared directory?"
    echo "1) Home directory"
    echo "2) Select disk"
    read -p "Enter your choice (1 or 2): " location_choice

    case $location_choice in
        1)
            create_shared_directory_in_home
            ;;
        2)
            select_disk_for_shared_folder
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
}

# Function to configure Samba share
configure_samba_share() {
    read -p "Enter the name for the shared folder: " shared_folder_name

    # Determine path based on user's choice
    if [[ "$location_choice" == "home" ]]; then
        user_home=$(getent passwd $SUDO_USER | cut -d: -f6)
        shared_dir="$user_home/$shared_folder_name"
    else
        shared_dir="/mnt/$disk_name/$shared_folder_name"
    fi
    
    echo "Choose the share access type:"
    echo "1) Read/Write/Execute"
    echo "2) Read-Only"
    read -p "Enter your choice (1 or 2): " access_choice
    
    if [ "$access_choice" -eq 1 ]; then
        access="read only = no"
    else
        access="read only = yes"
    fi

    sudo bash -c "cat >> /etc/samba/smb.conf <<EOL

[$shared_folder_name]
   path = $shared_dir
   valid users = @$groupname
   $access
   browseable = yes
   writable = yes
   create mask = 0775
   directory mask = 0775
EOL"
}

# Function to restart Samba service
restart_samba_service() {
    echo "Restarting Samba service..."
    sudo systemctl restart smbd
    sudo systemctl restart nmbd
}

# Main script execution
install_samba
create_samba_user

# Prompt user to choose where to create the shared directory
choose_location_for_shared_directory
configure_samba_share
restart_samba_service

echo "Samba share setup complete."
