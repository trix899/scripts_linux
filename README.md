# Linux Scripts 

Welcome to my collection of Linux scripts designed to automate common tasks and setups.

## Scripts

### ⭕ **Automate User Creation with Root Access**
   - **Purpose:** Automates the creation of a new user with root access privileges.
   - **Filename:** `create_user.sh`
   - **Usage:**
     ```bash
     sudo ./create_user.sh username password
     ```
     Replace `username` and `password` with the desired username and password for the new user.
   - **Necessary Packages:**
     - `sudo` (should already be installed on most systems)

### ⭕ **Set Up Samba File Share**
   - **Purpose:** Simplifies the configuration of a Samba file share.
   - **Filename:** `new_smb_share.sh`
   - **Usage:**
     ```bash
     sudo ./new_smb_share.sh
     ```
     Follow the prompts to configure the Samba share settings interactively.
   - **Necessary Packages:**
     - `samba`

### ⭕ **Mount Samba Share**
   - **Purpose:** Mounts a Samba share with username/password authentication.
   - **Filename:** `mount_samba_share.sh`
   - **Usage:**
     ```bash
     sudo ./mount_samba_share.sh
     ```
     Follow the prompts to specify the IP address, share name, username, and password.
   - **Necessary Packages:**
     - `smbclient`
     - `cifs-utils`


## Usage
- Clone the repository or download the individual scripts.
- Make scripts executable: `chmod +x script_name.sh`
- Run scripts with sudo privileges: `sudo ./script_name.sh`

## Notes
- Ensure you understand the purpose and usage of each script before running them.
- The scripts will automatically install necessary packages if they are not already installed on your system.
- Customize scripts as per your specific requirements and environment.
- Contributions and improvements are welcome. Feel free to submit pull requests.


