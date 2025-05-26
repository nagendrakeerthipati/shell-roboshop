USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

SCRIPT_DIR=$PWD #this help us save

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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disable nodejs "

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs "

dnf install nodejs -y
VALIDATE $? "installing nodejs " &>>$LOG_FILE

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "user creaton " &>>$LOG_FILE
else
    echo -e "roboshop user already exists"

fi

mkdir -p /app # -p refers if the directory already exists means it won't create again
VALIDATE $?

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "catalogue downlaoding "

rm -rf /app/*
cd /app
unzip -o /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzip is catalogue.zip"

cd /app
npm install &>>$LOG_FILE
VALIDATE $? "npm install "

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying from catalogue"

# sed -i 's/<MONGODB-SERVER-IPADDRESS>/mongodb.nagendrablog.site/' catalogue.service &>>$LOG_FILE
# VALIDATE $? "replaceing ip address with site name "

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload "

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "enabling catalogue"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "catalogue start "

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB Client"

# mongosh --host mongodb.nagendrablog.site </app/db/master-data.js &>>$LOG_FILE
# VALIDATE $? "Loading data into MongoDB"

STATUS=$(mongosh --host mongodb.daws84s.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]; then
    mongosh --host mongodb.nagendrablog.site </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi
