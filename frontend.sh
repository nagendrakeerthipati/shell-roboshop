#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$(dirname "$(realpath "$0")")

mkdir -p "$LOGS_FOLDER"
echo "Script started executing at: $(date)" | tee -a "$LOG_FILE"

# Check if the script is run as root
if [ "$USERID" -ne 0 ]; then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a "$LOG_FILE"
    exit 1
else
    echo "You are running with root access" | tee -a "$LOG_FILE"
fi

# Validate function: takes exit code and message
VALIDATE() {
    if [ "$1" -eq 0 ]; then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a "$LOG_FILE"
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Nginx installation and setup
dnf module disable nginx -y &>>"$LOG_FILE"
VALIDATE $? "Disabling default Nginx module"

dnf module enable nginx:1.24 -y &>>"$LOG_FILE"
VALIDATE $? "Enabling Nginx:1.24 module"

dnf install nginx -y &>>"$LOG_FILE"
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>"$LOG_FILE"
systemctl start nginx &>>"$LOG_FILE"
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* &>>"$LOG_FILE"
VALIDATE $? "Removing default Nginx HTML content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>"$LOG_FILE"
VALIDATE $? "Downloading frontend zip"

cd /usr/share/nginx/html || exit
unzip /tmp/frontend.zip &>>"$LOG_FILE"
VALIDATE $? "Unzipping frontend content"

rm -f /etc/nginx/nginx.conf &>>"$LOG_FILE"
VALIDATE $? "Removing default nginx.conf"

cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/nginx.conf &>>"$LOG_FILE"
VALIDATE $? "Copying custom nginx.conf"

systemctl restart nginx &>>"$LOG_FILE"
VALIDATE $? "Restarting Nginx"
