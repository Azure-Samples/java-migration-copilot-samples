using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace Malshinon
{
    public static class Logger
    {
        public static void Log(string message)
        {
            string logEntry = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}";
            Console.WriteLine(logEntry);
            File.AppendAllText("C:\\Users\\Studies\\kodcode\\kodCodeIdf\\Malshinon\\log.txt", logEntry + Environment.NewLine);
        }
        public static string Read()
        {
            if (!File.Exists("C:\\Users\\Studies\\kodcode\\kodCodeIdf\\Malshinon\\log.txt"))
            {
                return string.Empty;
            }
            return File.ReadAllText("C:\\Users\\Studies\\kodcode\\kodCodeIdf\\Malshinon\\log.txt");
        }
    }
}
