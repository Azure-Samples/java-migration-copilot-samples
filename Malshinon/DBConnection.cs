using System;
using System.Collections.Generic;
using System.Linq;
using MySql.Data.MySqlClient;

namespace Malshinon
{
    class DBConnection
    {
        public static MySqlConnection Connect(string cs = null)
        {
            var connStr = string.IsNullOrWhiteSpace(cs)
                ? "server=127.0.0.1;uid=root;password=;database=malshinon"
            : cs;

            MySqlConnection conn = new MySqlConnection(connStr);
            conn.Open();
            return conn;
        }

        public static void Disconnect(MySqlConnection conn) => conn.Close();

        public static MySqlCommand Command(string sql)
        {
            var cmd = new MySqlCommand { CommandText = sql };
            return cmd;
        }

        private static MySqlDataReader Send(MySqlConnection conn, MySqlCommand cmd)
        {
            cmd.Connection = conn;
            return cmd.ExecuteReader(System.Data.CommandBehavior.CloseConnection);
        }

        private static List<Dictionary<string, object>> Parse(MySqlDataReader rdr)
        {
            var rows = new List<Dictionary<string, object>>();

            using (rdr)
            {
                while (rdr.Read())
                {
                    var row = new Dictionary<string, object>(rdr.FieldCount);
                    for (int i = 0; i < rdr.FieldCount; i++)
                        row[rdr.GetName(i)] = rdr.IsDBNull(i) ? null : rdr.GetValue(i);

                    rows.Add(row);
                }
            }
            return rows;
        }

        public static List<Dictionary<string, object>> Execute(
            string sql,
            string connectionString = null)
        {
            var conn = Connect(connectionString);
            var cmd = Command(sql);
            var rdr = Send(conn, cmd);
            return Parse(rdr);
        }

        public static void PrintResult(List<Dictionary<string, object>> keyValuePairs)
        {
            if (keyValuePairs.Count == 0)
            {
                Console.WriteLine("No results found.");
                return;
            }

            var headers = keyValuePairs[0].Keys.ToList();

            // חישוב רוחב כל עמודה
            var columnWidths = new Dictionary<string, int>();
            foreach (var header in headers)
            {
                int maxWidth = header.Length;
                foreach (var row in keyValuePairs)
                {
                    string valueStr = row[header]?.ToString() ?? "";
                    if (valueStr.Length > maxWidth)
                        maxWidth = valueStr.Length;
                }
                columnWidths[header] = maxWidth + 2;
            }

            // הדפסת שורת כותרת
            string separatorLine = "+";
            foreach (var header in headers)
                separatorLine += new string('-', columnWidths[header]) + "+";

            string headerLine = "|";
            foreach (var header in headers)
                headerLine += " " + header.PadRight(columnWidths[header] - 1) + "|";

            Console.WriteLine(separatorLine);
            Console.WriteLine(headerLine);
            Console.WriteLine(separatorLine);

            // הדפסת תוכן
            foreach (var row in keyValuePairs)
            {
                Console.Write("|");
                foreach (var header in headers)
                {
                    object valueObj = row[header];
                    string valueStr = valueObj?.ToString() ?? "";

                    // בדיקה אם בוליאני
                    if (valueObj is bool boolVal)
                    {
                        Console.ForegroundColor = boolVal ? ConsoleColor.Green : ConsoleColor.Red;
                        Console.Write(" " + valueStr.PadRight(columnWidths[header] - 1));
                        Console.ResetColor();
                    }
                    else
                    {
                        Console.Write(" " + valueStr.PadRight(columnWidths[header] - 1));
                    }

                    Console.Write("|");
                }
                Console.WriteLine();
            }

            Console.WriteLine(separatorLine);
        }

    }
}
