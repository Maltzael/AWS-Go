import smtplib
from email.message import EmailMessage


class AlarmTool():
    def __init__(self):
        self.getAlarmEmailAccount()
        self.getClientContactData()

    def getClientContactData(self):
        # dodac kod pobierania danych skrzynki ze zmiennych srodowiskowych
        self.targetEmail = ['me@gmail.com', 'bill@gmail.com']
        pass

    def getAlarmEmailAccount(self):
        self.gmail_user = 'you@gmail.com'
        self.gmail_password = 'P@ssword!'
        self.sent_from = "gmail_user"
        # dodac kod pobierania danych skrzynki ze zmiennych srodowiskowych
        pass

    def sendAlarm(self, subject, body):
        self.subject = subject
        self.body = body

        msg = EmailMessage()
        msg.set_content(self.body)

        msg['Subject'] = self.subject
        msg['From'] = self.sent_from
        msg['To'] = self.targetEmail

        try:
            server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
            server.ehlo()
            server.login(self.gmail_user, self.gmail_password)
            server.sendmail(msg)
            server.close()

            print( 'Alarm email sukcessfuly send to ', self.targetEmail)
        except:
            print("There was problem with email connection. Abort")
            exit(1)