import pyodbc
import sys

'''
----------
References
----------
1. https://stackoverflow.com/questions/63942974/executing-sql-server-query-in-python
2. https://youtu.be/Vm2fHhP4SVE?si=1Ja8BqmED77_tMzY
'''

# List of valid server aliases
SERVERS = \
{
        "A": "ServerA",
        "B": "ServerB",
        "C": "ServerC",
        "D": "ServerD"
}
for k, v in SERVERS.items():
    print(k, v)
print()


def build_sql_conn():
    # User Inputs
    server_alias = input("Server Alias: ").upper()
    database_name = input("Database Name: ")

    # Get Server Name
    server_name = SERVERS.get(server_alias)

    # Build the Connection String
    conn_str = pyodbc.connect(
        'DRIVER={SQL Server};'
        'SERVER=' + server_name + ';'
        'DATABASE=' + database_name + ';'
        'TRUSTED_CONNECTION=yes;'
        )
    return conn_str


def exec_sql():
    try:
        conn = build_sql_conn()
        # print("Connected successfully")

        sql_query = input("Enter SQL Query:\n\n")

        # Create the connection cursor
        cursor = conn.cursor()
        cursor.execute(sql_query)

        # Access the data as a TUPLE
        for row in cursor:
            print(f'{row}')

        # Close the connection
        cursor.close()
        conn.close()
    except:
        print(f"{sys.exc_info()[1]} occurred.")


def main():
    exec_sql()


if __name__ == "__main__":
    main()

# Pause the terminal
input("\nPress Enter to exit!")