using System;
using System.Data.SqlClient;
using System.Configuration;

namespace ConnectDemo1
{
    class DataConnect
    {
        public void ConnectionStringDemo()
        {
            // Simple demonstration of the connection string and some of the options.

            string connectString = BuildConnectionString("server", "defaultDB", "SQLuser", "SQLpwd");   
            SqlConnection connection;
            try
            {
                connection = new SqlConnection(connectString);
            }
            catch (ArgumentException ax)  // there was something wrong in the connection string.
            {
                Console.WriteLine("Error creating the connection: {0}", ax.Message);
                return;
            }

            try
            {
                connection.Open();
            }
            catch (SqlException ex)  // Catch errors specific to the Open method
            {
                Console.WriteLine("Error opening the connection: {0}", ex.Message);
                return;
            }
            catch (InvalidOperationException ix)
            {
                Console.WriteLine("Invalid Operation error: {0}", ix.Message);
                return;
            }
            catch (ConfigurationErrorsException cx)
            {
                Console.WriteLine("Configuration error: {0}", cx.Message);
                return;
            }


            if (connection.State != System.Data.ConnectionState.Open)
            {
                Console.WriteLine("Connection did not open properly.");
                Console.WriteLine("The connection status is: {0}", connection.State.ToString());
                connection.Close();
                return;
            }

            Console.WriteLine("Connection Status is {0}", connection.State);
            Console.WriteLine("Server Version is {0}", connection.ServerVersion);

            SqlTransaction trans = connection.BeginTransaction(System.Data.IsolationLevel.Snapshot, "myTransaction");

            // ... do stuff here with your connection
            // For example you can use a command object to run a simple query:

            SqlCommand cmd = new SqlCommand("SELECT @@SERVERNAME", connection, trans);  // (Need to include the transaction in the command object if there is one)
            try
            {
                string srvr = cmd.ExecuteScalar().ToString();   // ExecuteScalar returns the first column of the first row returned.

                Console.WriteLine("Server Name: {0}", srvr);
                trans.Commit();
            }
            catch (SqlException ex)  // if there were problems roll back everything
            {
                trans.Rollback();
                Console.WriteLine("Problem with the data operation: {0}", ex.Message);
            }

            connection.Close();

            Console.Write("Press Enter to Continue:");
            Console.ReadLine();


        }


        public string BuildConnectionString(string server, string defaultDB, string sqlUser, string sqlPwd)
        {
            // Modify the basic connection string to allow the user to specify a different server and default database
            //  or use SQL login instead of Windows integrated security if values are supplied supplied.

            ConnectionStringsSection connectionStringsSection = (ConnectionStringsSection)ConfigurationManager.GetSection("connectionStrings");
            string connectString = connectionStringsSection.ConnectionStrings["simpleConnection"].ConnectionString;

            SqlConnectionStringBuilder bldr = new SqlConnectionStringBuilder(connectString);  // Start with the basic string as a default.

            if (server != "")
                bldr.DataSource = server;

            if (defaultDB != "")
                bldr.InitialCatalog = defaultDB;

            if (sqlUser != "")
            {
                bldr.IntegratedSecurity = false;
                bldr.UserID = sqlUser;
                bldr.Password = sqlPwd;
            }

            return bldr.ConnectionString;
        }


    }
}
