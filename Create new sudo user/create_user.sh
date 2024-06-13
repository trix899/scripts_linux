#!/bin/bash

# Check if the script is run as root
if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root. Please use sudo or run as root."
    exit 1
fi

# Prompt for the username
read -p "Enter the username: " username

# Prompt for the password (input will be hidden)
read -s -p "Enter the password: " password
echo

# Update the package list
apt-get update

# Install sudo if it is not already installed
if ! command -v sudo &> /dev/null; then
    echo "sudo not found. Installing sudo..."
    apt-get install -y sudo
else
    echo "sudo is already installed."
fi

# Create the user with a home directory and default shell /bin/bash
useradd -m -s /bin/bash "$username"

# Set the password for the user
echo "$username:$password" | chpasswd

# Add the user to the sudo group
usermod -aG sudo "$username"

echo "User $username has been created with a home directory and added to the sudo group."
