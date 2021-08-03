import time
myfile = "C:\\data\\cmm\\results from calypso\\chr.txt.txt"
myfilew = open(myfile, 'w')
for i in range(20):
    myfilew.write("TESTING ")
    time.sleep(1)
myfilew.close()