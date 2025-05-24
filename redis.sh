USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e " $2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e " $2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable redis -y
dnf module enable redis:7 -y
VALIDATE $? "redis enable " | tee -a $LOG_FILE
dnf install redis -y | tee -a $LOG_FILE

# Update listen address from 127.0.0.1 to 0.0.0.0 in /etc/redis/redis.conf
sed -i 's/127.0.0.1/0.0.0.0/' /etc/redis/redis.conf
sed -i 's/yes/no/' etc/redis/redis.conf
VALIDATE $? "updating conf " | tee -a $LOG_FILE

# Update protected-mode from yes to no in /etc/redis/redis.conf

Start &
Enable Redis Service | tee -a $LOG_FILE

systemctl enable redis
systemctl start redis | tee -a $LOG_FILE
