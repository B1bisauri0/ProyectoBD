import pyodbc

def get_db_conn():
    connection_string = (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=secret-bd.database.windows.net,1433;"
        "DATABASE=DB_STORE;"
        "UID=secret;"
        "PWD=secret;"
    )
    try:
        connection = pyodbc.connect(connection_string)
        connection.autocommit = True
        print("Se conecto con exito")
        return connection
    except Exception as e:
        print(f"Error al conectarse a la base de datos: {e}")
        return None

''' 
def getErrorMessage(errorCode: int):

    con = get_db_conn()
    cursor = con.cursor()

    try:
        cursor.execute(
            """
            DECLARE @errorMessage VARCHAR(255);

            EXECUTE [dbo].[recoverErrorMessage]
                @inErrorCode = ?,
                @outErrorMessage = @errorMessage OUTPUT

            SELECT @errorMessage

            """,
            errorCode
        )

        resultMessage = cursor.fetchone()[0]

        return resultMessage

    except Exception as e:
        return (f"Error al obtener mensaje de error: {e}")
    finally:
        cursor.close()
        con.close()
'''
