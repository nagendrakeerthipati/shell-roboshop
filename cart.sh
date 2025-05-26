START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$(pwd)

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

dnf module disable nodejs -y &>>LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs "

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Roboshop user created "
else
    echo -e "user already exists......$Y No need to create $N"
fi

mkdir -p /app
VALIDATE $? "creating directory "

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading cart "

rm -rf /app/*
cd /app
unzip -o /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "unzipping cart "

cd /app
npm install &>>$LOG_FILE
VALIDATE $? "dependencies downloading "

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload "

systemctl enable cart &>>$LOG_FILE
VALIDATE $? "enabling cart"

systemctl start cart &>>$LOG_FILE
VALIDATE $? "cart start "

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
