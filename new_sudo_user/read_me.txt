# User Creation Script

This script automates the creation of a new Linux user with sudo privileges on a Debian-based system, such as Proxmox VE. 
It prompts for a username and password during execution, installs `sudo` if it is not already installed, and sets up the 
user with a home directory and sudo access.

## How to Use

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/trix899/scripts_linux
   cd scripts_linux

2. cd /new_sudo_user

3. chmod +x create_user.sh (file is then executable) 

4.sudo ./create_user.sh    #if another user
  ./create_user.sh         #if you are root user

5 Follow the steps to make a new user.

