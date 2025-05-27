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
dnf install maven -y
VALIDATE $? "installing maveen "

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "roboshop user is creating "
else
    echo -e "user already exists"
fi

mkdir -p /app

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip
VALIDATE $? "downloading shipping "

rm -rf /app/*
cd /app
unzip -o /tmp/shipping.zip
VALIDATE $? "unziping "

cd /app
mvn clean package
mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "moving shipping.jar "

cp SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "setup a new service in systemd so systemctl "

systemctl daemon-reload
VALIDATE $? "daemon reloading"

systemctl enable shipping
VALIDATE $? "enable is "

systemctl start shipping
VALIDATE $? "starting systemctl "

dnf install mysql -y
VALIDATE $? "installing mysql "

record_count=$(mysql -h mysql.nagendrablog.site -uroot -pRoboShop@1 -N -e "SELECT COUNT(*) FROM your_table_name WHERE your_condition;" your_database)

if [ "$record_count" -eq 0 ]; then
    echo "Data not found. Importing..."
    mysql -h mysql.nagendrablog.site -uroot -pRoboShop@1 </app/db/app-user.sql
    VALIDATE $? "Importing data ..."
else
    echo "Data already exists. Skipping import."
fi
