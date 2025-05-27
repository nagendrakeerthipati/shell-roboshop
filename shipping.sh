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
dnf install maven -y &>>LOG_FILE
VALIDATE $? "installing maveen "

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "roboshop user is creating "
else
    echo -e "user already exists"
fi

mkdir -p /app &>>LOG_FILE

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>LOG_FILE
VALIDATE $? "downloading shipping "

rm -rf /app/*
cd /app
unzip -o /tmp/shipping.zip &>>LOG_FILE
VALIDATE $? "unziping "

cd /app
mvn clean package &>>LOG_FILE
mv target/shipping-1.0.jar shipping.jar &>>LOG_FILE
VALIDATE $? "moving shipping.jar "

cp SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>LOG_FILE
VALIDATE $? "setup a new service in systemd so systemctl "

systemctl daemon-reload &>>LOG_FILE
VALIDATE $? "daemon reloading"

systemctl enable shipping &>>LOG_FILE
VALIDATE $? "enable is "

systemctl start shipping &>>LOG_FILE
VALIDATE $? "starting systemctl "

dnf install mysql -y &>>LOG_FILE
VALIDATE $? "installing mysql "

record_count=$(mysql -h mysql.nagendrablog.site -uroot -pRoboShop@1 -N -e "SELECT COUNT(*) FROM your_table_name WHERE your_condition;" your_database)

if [ "$record_count" -eq 0 ]; then
    echo "Data not found. Importing..."
    mysql -h mysql.nagendrablog.site -uroot -pRoboShop@1 </app/db/app-user.sql
    VALIDATE $? "Importing data ..."
else
    echo "Data already exists. Skipping import."
fi

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
