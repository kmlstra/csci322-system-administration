#!/bin/bash

# createUsers.sh - Script to create user accounts for staff and visitors
# Usage: sudo ./createUsers.sh Usernames.txt

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Check if input file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <usernames_file>"
    exit 1
fi

USERFILE="$1"

# Check if file exists
if [ ! -f "$USERFILE" ]; then
    echo "Error: File $USERFILE not found!"
    exit 1
fi

# Function to log messages to syslog
log_message() {
    logger -t "UserManagement" "$1"
}

# Create groups if they don't exist
echo "Creating groups..."

if ! getent group visitors > /dev/null 2>&1; then
    groupadd visitors
    log_message "Created group: visitors"
    echo "Group 'visitors' created"
else
    echo "Group 'visitors' already exists"
    log_message "Group 'visitors' already exists"
fi

if ! getent group staff > /dev/null 2>&1; then
    groupadd staff
    log_message "Created group: staff"
    echo "Group 'staff' created"
else
    echo "Group 'staff' already exists"
    log_message "Group 'staff' already exists"
fi

echo ""
echo "Processing users from $USERFILE..."
echo ""

# Read the file line by line
while IFS=',' read -r username usertype; do
    # Remove any whitespace or carriage returns
    username=$(echo "$username" | tr -d '[:space:]')
    usertype=$(echo "$usertype" | tr -d '[:space:]')
    
    # Skip empty lines
    if [ -z "$username" ]; then
        continue
    fi
    
    # Determine the group based on user type
    if [ "$usertype" = "staff" ]; then
        group="staff"
    elif [ "$usertype" = "visitor" ]; then
        group="visitors"
    else
        echo "Warning: Unknown user type '$usertype' for user '$username'. Skipping."
        log_message "Warning: Unknown user type '$usertype' for user '$username'"
        continue
    fi
    
    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo "User '$username' already exists. Skipping."
        log_message "User '$username' already exists"
        continue
    fi
    
    # Create user with home directory, bash shell, and add to group in one command
    useradd -m -d "/home/$username" -s /bin/bash -g "$group" -p "$(openssl passwd -1 "$username")" "$username"
    
    if [ $? -eq 0 ]; then
        echo "Created user: $username (group: $group)"
        log_message "Created user: $username with group: $group"
    else
        echo "Error creating user: $username"
        log_message "Error creating user: $username"
    fi
    
done < "$USERFILE"

echo ""
echo "User creation completed!"
echo ""
echo "Summary:"
echo "--------"
echo "Staff group members: $(getent group staff | cut -d: -f4 | tr ',' '\n' | wc -l)"
echo "Visitors group members: $(getent group visitors | cut -d: -f4 | tr ',' '\n' | wc -l)"

log_message "User creation process completed"
