import pyodbc

class conn_setup:
    DSN = ' '
    UID = ' '
    PASSWD = ' '
    
    def setConnInfo(self, dsn, user, password):
        self.DSN = dsn
        self.UID = user
        self.PASSWD = password

    def connect2server(self):
        connectstring = 'DSN='+self.DSN+';UID=' + self.UID+';PWD=' + self.PASSWD
        conn = pyodbc.connect(connectstring)
        return conn


        



    
        
    
