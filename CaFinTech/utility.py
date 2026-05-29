import secrets
import uuid

import pyodbc
from django.db import connection
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
            f"PWD={cjson['pwd']}", autocommit=True
        )
        return conn.cursor()
    except Exception as e:
        raise Exception("Database connection failed: " + str(e))
    
def getDbCursorByCid(cId):
    conn = None
    cjson = None
    cjson = Company.objects.filter(cid=cId).first().connection_string
    try:
        conn = pyodbc.connect(
            "DRIVER={ODBC Driver 17 for SQL Server};"
            f"SERVER={cjson['server']};"
            f"DATABASE={cjson['database']};"
            f"UID={cjson['uid']};"
            f"PWD={cjson['pwd']}", autocommit=True
        )
        return conn.cursor()
    except Exception as e:
        raise Exception("Database connection failed: " + str(e))
    
def _generate_strong_password(length: int = 16) -> str:
    """Return a password meeting SQL Server complexity rules:
    at least eight characters and characters from three of the four sets:
    uppercase, lowercase, digits and symbols.
    """
    import string

    if length < 8:
        length = 8

    # limit special characters to only these to satisfy SQL Server policy
    allowed_symbols = '@!#$'
    alphabet = string.ascii_letters + string.digits + allowed_symbols
    while True:
        pwd = ''.join(secrets.choice(alphabet) for _ in range(length))
        categories = [
            any(c.isupper() for c in pwd),
            any(c.islower() for c in pwd),
            any(c.isdigit() for c in pwd),
            any(c in allowed_symbols for c in pwd),
        ]
        if sum(categories) >= 3:
            return pwd

def migrateSqlScript(cid):
    cursor = connection.cursor()
    db_name = f"{cid}_{uuid.uuid4().hex[:6]}Db"
    login_name = f"{cid}usr{uuid.uuid4().hex[:6]}"
    password = _generate_strong_password(16)
    cursor.execute(f"CREATE LOGIN [{login_name}] WITH PASSWORD = '{password}', CHECK_POLICY = ON;")

    cursor.execute(f"CREATE USER [{login_name}] FOR LOGIN [{login_name}]; ALTER ROLE db_datareader ADD MEMBER [{login_name}]; ALTER ROLE db_datawriter ADD MEMBER [{login_name}];")
    cursor.execute(f"GRANT CONNECT TO [{login_name}];")
    cursor.execute(f"GRANT EXECUTE TO [{login_name}];")

    cursor.execute(f"USE [master]")
    cursor.execute(f"GRANT VIEW SERVER PERFORMANCE STATE TO [{login_name}];")
    cursor.execute(f"GRANT VIEW SERVER STATE TO [{login_name}];")

    cursor.execute(f"USE [UniDb]")
    cursor.execute(f"CREATE USER [{login_name}] FOR LOGIN [{login_name}]; ALTER ROLE db_datareader ADD MEMBER [{login_name}];")
    cursor.execute(f"GRANT EXECUTE TO [{login_name}];")

    cursor.execute(f"CREATE DATABASE [{db_name}]")
    cursor.execute(f"USE [{db_name}]")
    cursor.execute(f"CREATE USER [{login_name}] FOR LOGIN [{login_name}]; ALTER ROLE db_datareader ADD MEMBER [{login_name}]; ALTER ROLE db_datawriter ADD MEMBER [{login_name}];")
    cursor.execute(f"GRANT CONNECT TO [{login_name}];")
    cursor.execute(f"GRANT EXECUTE TO [{login_name}];")

    with open("main.sql", "r", encoding="utf-8-sig") as file:
        script = file.read()
 
    # Safe replacement
    # script = script.replace("{{DB_NAME}}", f"[{db_name}]")

    commands = [cmd.strip() for cmd in script.split("GO") if cmd.strip()]

    for cmd in commands:
        try:
            cursor.execute(cmd)
        except Exception as e:
            print(f"Error executing command: {cmd}")
            raise e
    
    cursor.execute(f"USE centralDB")  # Switch back to central database after migration
    cursor.close()
    return {"server": "192.168.231.9", "database": db_name, "uid": login_name, "pwd": password}