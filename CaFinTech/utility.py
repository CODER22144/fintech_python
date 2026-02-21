import pyodbc

from user.models import Company

def generate_error_message(exception):
    # TODO: GENERATE ERROR MESSAGE PROEPERLY
    return {
            "status" : False,
            "errorCode" : exception.args[0] if exception.args else 9000,
            "message" : str(exception)
        }

def getDbCursor(user):
    conn = None
    cjson = None
    if user.cid in user.cgId.associated_companies:
        cjson = Company.objects.filter(cid=user.cid).first().connection_string
    else:
        raise Exception("User does not have access to the specified company")
    try:
        conn = pyodbc.connect(
            "DRIVER={ODBC Driver 17 for SQL Server};"
            f"SERVER={cjson['server']};"
            f"DATABASE={cjson['database']};"
            f"UID={cjson['uid']};"
            f"PWD={cjson['pwd']}"
        )
        return conn.cursor()
    except Exception as e:
        raise Exception("Database connection failed: " + str(e))