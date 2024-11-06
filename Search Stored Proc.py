import os
import pyodbc
import re

'''
----------
References
----------
1. https://stackoverflow.com/questions/63942974/executing-sql-server-query-in-python
2. https://youtu.be/Vm2fHhP4SVE?si=1Ja8BqmED77_tMzY
3. https://github.com/mkleehammer/pyodbc/wiki/Exceptions
'''

# List of valid server aliases
SERVERS = \
    {
        "A": "ServerA",
        "B": "ServerB",
        "C": "ServerC",
        "D": "ServerD"
    }


def cls():
    t = os.system("cls" if os.name == "nt" else "clear")


def print_items(dc, comment):
    com_len = len(comment)
    print(com_len*"=", comment, com_len*"=", sep = "\n")
    for k, v in dc.items():
        print(k, v, sep = ": ")
    print("\n")


def get_valid_key(dc, prompt):
    while True:
        key = input(prompt).strip().upper()
        value = dc.get(key)
        if value:
            return value
        else:
            print(f"{key} is an invalid entry.")
            continue


def build_sql_conn():
    # User Inputs
    server_name = get_valid_key(SERVERS, "Server Alias: ")
    database_name = input("Database Name: " or "master")

    # Build the Connection String
    conn_str = pyodbc.connect(
        "DRIVER={SQL Server};"
        "SERVER=" + server_name + ";"
        "DATABASE=" + database_name + ";"
        "TRUSTED_CONNECTION=yes;"
    )
    return conn_str


def find_string(lookup, text):
    line_number = {}
    for idx, row in enumerate(text):
        #  The fetchall method returns data in tuples because its columnar data. Since in our case, we only have a single
        #  column that we want to look at; so we can just pull the first element from the tuple by indexing it row[0].
        if re.findall(fr"\W{lookup}\b", row[0], re.IGNORECASE):
            # if row[0].strip()[:2] not in ("--", "* "):
            line_number[idx + 1] = re.sub(r"[\n\r\t]", "", row[0])
    lines = [f"{key} {value}" for key, value in line_number.items()]
    print("\n".join(lines))


def exec_sql():
    try:
        print()  # Need a line break
        print_items(SERVERS, "Valid Server Names")
        conn = build_sql_conn()
        print("Authentication succeeded!!\n\n")

        # sql_query = input("Enter SQL Query:\n\n")
        sql_query = "exec somedb.sys.sp_helptext 'TwoPartProcName';"
        search_string = input("Enter Search String: ").strip()
        cls()

        # Create the connection cursor
        cursor = conn.cursor()
        cursor.execute(sql_query)

        # Returns a list containing tuple-like Row objects
        all_rows = cursor.fetchall()

        find_string(search_string, all_rows)

        # Close the connection
        cursor.close()
        conn.close()
    except pyodbc.DatabaseError as err:
        print(err)


def main():
    exec_sql()


if __name__ == "__main__":
    main()
    input("\nPress Enter key to exit!")
