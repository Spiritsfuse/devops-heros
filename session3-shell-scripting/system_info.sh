#!/bin/bash

# ==============================================================================
# Script Name: system_info.sh
# Description: Collects and displays system information, takes user input,
#              creates a directory and file, and saves running processes to it.
# ==============================================================================

echo "=========================================="
echo "         SYSTEM INFORMATION SCRIPT        "
echo "=========================================="

# 1. Variables to store system information
current_date=$(date)
host_name=$(hostname)
current_user=$(whoami)

# 2. Print System Details
echo ""
echo "[+] Date and Time   : $current_date"
echo "[+] Hostname        : $host_name"
echo "[+] Current User    : $current_user"
echo ""

# 3. Print Disk Usage
echo "------------------------------------------"
echo "Disk Usage Summary (df -h):"
echo "------------------------------------------"
df -h
echo ""

# 4. Print Running Processes
echo "------------------------------------------"
echo "Currently Running Processes (ps):"
echo "------------------------------------------"
ps
echo ""

# 5. Take user input using read -p
echo "------------------------------------------"
echo "User Input & File Operations:"
echo "------------------------------------------"
read -p "Enter directory name to create [default: system_logs]: " dir_name
read -p "Enter file name for process log [default: process_info.txt]: " file_name

# Use default values if input is empty
dir_name=${dir_name:-system_logs}
file_name=${file_name:-process_info.txt}

# 6. Create directory using mkdir
echo "[*] Creating directory '$dir_name' using mkdir..."
mkdir -p "$dir_name"

# 7. Create file using touch
target_file="$dir_name/$file_name"
echo "[*] Creating file '$target_file' using touch..."
touch "$target_file"

# 8. Store running processes information in the file using > output redirection
echo "[*] Redirecting running processes into '$target_file' using '>' redirection..."
ps > "$target_file"

echo ""
echo "[✓] Process information successfully saved to $target_file!"
echo "------------------------------------------"
echo "Preview of '$target_file':"
echo "------------------------------------------"
head -n 10 "$target_file"
echo "=========================================="
echo "      SCRIPT EXECUTION COMPLETED          "
echo "=========================================="
