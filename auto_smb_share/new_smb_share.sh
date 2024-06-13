#!/bin/bash

# Function to check if a user exists in Samba
user_exists_in_samba() {
    local username=$1
    if sudo pdbedit -L | grep -q "^$username:"; then
        return 0  # User exists
    else
        return 1  # User does not exist
    fi
}

# Function to install Samba packages
install_samba() {
    echo "Updating package list and installing Samba packages..."
    sudo apt update || { echo "Failed to update package list. Exiting."; exit 1; }
    sudo apt install -y samba cifs-utils || { echo "Failed to install Samba packages. Exiting."; exit 1; }
}

# Function to create a new Samba user
create_new_samba_user() {
    read -p "Enter the username for the new Samba share: " username
    
    # Validate username input
    if [ -z "$username" ]; then
        echo "Username cannot be empty. Exiting."
        exit 1
    fi

    # Check if the username already exists
    if user_exists_in_samba "$username"; then
        echo "User $username already exists in Samba. Exiting."
        exit 1
    fi

    sudo smbpasswd -a $username || { echo "Failed to set Samba password for user $username. Exiting."; exit 1; }
}

# Function to select an existing Samba user
select_existing_samba_user() {
    echo "Existing Samba users:"
    sudo pdbedit -L | awk -F: '{print $1}'
    echo "-------------------------------------------------------"
    read -p "Enter the username from the list above to use: " username
    
    # Validate username input
    if [ -z "$username" ]; then
        echo "Username cannot be empty. Exiting."
        exit 1
    fi

    if ! user_exists_in_samba "$username"; then
        echo "User $username does not exist in Samba. Exiting."
        exit 1
    fi
}

# Function to prompt user for Samba user selection or creation
prompt_samba_user() {
    echo "Do you want to use an existing Samba user or create a new one?"
    echo "1) Use an existing user"
    echo "2) Create a new user"
    read -p "Enter your choice (1 or 2): " user_choice
    
    case $user_choice in
        1)
            select_existing_samba_user
            ;;
        2)
            create_new_samba_user
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
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

    # Validate disk number input
    if ! [[ "$disk_number" =~ ^[1-9][0-9]*$ ]]; then
        echo "Invalid input. Please enter a valid number."
        exit 1
    fi

    disk_name=$(lsblk -o NAME | grep -e "disk" -e "part" | sed -n "${disk_number}p")
    mount_point="/mnt/$disk_name"
    
    # Check if mount point already exists
    if [ -d "$mount_point" ]; then
        echo "Mount point $mount_point already exists. Exiting."
        exit 1
    fi

    sudo mkdir -p $mount_point || { echo "Failed to create mount point $mount_point. Exiting."; exit 1; }
    echo "Folder will be created on $disk_name at $mount_point"
}

# Function to create a shared directory on the selected disk
create_shared_directory() {
    read -p "Enter the name for the shared folder: " shared_folder_name
    mount_point="/mnt/$disk_name"
    shared_dir="$mount_point/$shared_folder_name"
    
    # Check if shared directory already exists
    if [ -d "$shared_dir" ]; then
        echo "Shared directory $shared_dir already exists. Exiting."
        exit 1
    fi

    sudo mkdir -p $shared_dir || { echo "Failed to create shared directory $shared_dir. Exiting."; exit 1; }
    echo "Shared directory created at $shared_dir"
}

# Function to configure Samba share
configure_samba_share() {
    read -p "Enter the name for the shared folder: " shared_folder_name
    mount_point="/mnt/$disk_name"
    shared_dir="$mount_point/$shared_folder_name"
    
    echo "Choose the share access type:"
    echo "1) Read/Write/Execute"
    echo "2) Read-Only"
    read -p "Enter your choice (1 or 2): " access_choice
    
    if [ "$access_choice" -eq 1 ]; then
        access="read only = no"
    else
        access="read only = yes"
    fi

    # Append Samba configuration to smb.conf
    sudo bash -c "cat >> /etc/samba/smb.conf <<EOL
[$shared_folder_name]
   path = $shared_dir
   valid users = @$username
   $access
   browseable = yes
   writable = yes
   create mask = 0775
   directory mask = 0775
EOL" || { echo "Failed to configure Samba share. Exiting."; exit 1; }
}

# Function to restart Samba service
restart_samba_service() {
    echo "Restarting Samba service..."
    sudo systemctl restart smbd || { echo "Failed to restart smbd service. Exiting."; exit 1; }
    sudo systemctl restart nmbd || { echo "Failed to restart nmbd service. Exiting."; exit 1; }
}

# Main script execution
install_samba

# Check if there are existing Samba users
if sudo pdbedit -L | grep -q ":"; then
    prompt_samba_user
else
    create_new_samba_user
fi

select_disk_for_shared_folder
create_shared_directory
configure_samba_share
restart_samba_service

# Print the path of the shared directory
echo "Samba share setup complete."
echo "Shared directory is located at: $shared_dir"
