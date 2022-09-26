import os
import pysftp
from projectslaby.utilities.emailAllarms import AlarmTool

class ReciveSFTPevent ():
    def __init__(self, recivedEvent):
        if recivedEvent.id == os.getenv("SWALLOW_EVENTS"):
            print("skipping even ID:", recivedEvent.id, " - swallow event feature")
            exit(0)

        self.alarmInstance = AlarmTool()
        # pobieranie wartosci SFTP z env vars i ustawianie ich tak by reszta lambdy byla juz 100% skoncentrowana na algorytmie

    def checkSFTPforNewFiles(self):
        # swallow event

        with open("var.tf"):
            Hostname = "46.41.149.102" #do wyjebania
            Username = "test" #do wyjebania
            Password = "950119h" #do wyjebania
            with pysftp.Connection(host=Hostname, username=Username, password=Password) as sftp:    # obsluga bledu - co jezeli connection sie nie uda ( wyslac jakis alarm)
                print("Connection successfully established ... ") #zastapic jakims rozsadnym logiem
                # Switch to a remote directory
                localFilePath = '/home/mateusz/Pulpit/test.json' # do wyjebania - tu nie moze byc ustawiania zadnych wartosci
                remoteFilePath = '/home/test/test.json' # do wyjebania - tu nie moze byc ustawiania zadnych wartosci
                sftp.get(remoteFilePath, localFilePath)
                directory_structure = sftp.listdir_attr()

                # Print data
                for attr in directory_structure:
                    print(attr.filename, attr)
                    #odczytywania plików JSON
                    #Odczytywanie plików XML
                    #Odczytrywania plików CSV

                    # po odczytaniu plik musi byc przeniesiony do /archive
                    # plik o tej samej nazwie nie moze byc odczytyany 2 razy ( co oznacza ze trzeba napisac coś co
                    # będzie zapisywało w bazie danych pliki któ®e zostały przeprocesowane, a potem sprawdzać czy plik
                    # o tej nazwie przypadkiem już się nie pojawił) - na co jest już gotowe miejsce w project/utilities

                    #Przygotowac kod do wysylania tej informacji do target kinesis, patrz nawet zrobilem Ci miejsce

    def sendToKinesisStream(self):
        pass