
import pysftp


def lambdaEvent(event, content):
    with open("var.tf") 
    Hostname = "46.41.149.102"
    Username = "test"
    Password = "950119h"
    with pysftp.Connection(host=Hostname, username=Username, password=Password) as sftp:
        print("Connection successfully established ... ")
        # Switch to a remote directory
        localFilePath = '/home/mateusz/Pulpit/test.json'
        remoteFilePath = '/home/test/test.json'
        sftp.get(remoteFilePath, localFilePath)
        directory_structure = sftp.listdir_attr()

        # Print data
        for attr in directory_structure:
            print(attr.filename, attr)
        
dfdf = lambdaEvent('1', '2')
