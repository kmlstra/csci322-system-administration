#!/bin/bash

# reportVisitors.sh - Script to report members of visitors group
# Output: /tmp/visitors.txt with one username per line

OUTPUT_FILE="/tmp/visitors.txt"

# Get the GID of the visitors group
visitors_gid=$(getent group visitors | cut -d: -f3)

# Find all users who have visitors as their primary group
# Format of /etc/passwd: username:password:UID:GID:comment:home:shell
# We want field 4 (GID) to match the visitors group GID
getent passwd | awk -F: -v gid="$visitors_gid" '$4 == gid {print $1}' > "$OUTPUT_FILE"

# Check if the operation was successful
if [ $? -eq 0 ]; then
    # Log to syslog
    logger -t "VisitorReport" "Visitor list generated successfully at $OUTPUT_FILE"
    
    # Optional: Display count (useful for manual runs)
    if [ -t 1 ]; then
        user_count=$(wc -l < "$OUTPUT_FILE")
        echo "Visitor report generated: $OUTPUT_FILE"
        echo "Total visitors: $user_count"
    fi
else
    logger -t "VisitorReport" "Error generating visitor list"
    exit 1
fi

exit 0