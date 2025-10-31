using System;
using System.Collections.Generic;
using System.IO;
using System.Globalization;
using Malshinon.DAL;
using Malshinon.factory;

namespace Malshinon
{
    internal class CSV
    {
        public static void ImportCsv()
        {
            Console.Write("Enter CSV file path: ");
            string path = Console.ReadLine()?.Trim();

            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
            {
                Console.WriteLine("❌ File not found.\n");
                return;
            }

            int count = 0;

            var reader = new StreamReader(path);
            string header = reader.ReadLine();
            if (header == null)
            {
                Console.WriteLine("❌ CSV is empty.\n");
                return;
            }

            while (!reader.EndOfStream)
            {
                var line = reader.ReadLine();
                if (string.IsNullOrWhiteSpace(line)) continue;

                var parts = line.Split(',');

                if (parts.Length < 6) continue;

                string reporterSecret = parts[0].Trim().ToLower();
                string reporterName = parts[1].Trim();
                string targetSecret = parts[2].Trim().ToLower();
                string targetName = parts[3].Trim();
                string reportText = parts[4].Trim();
                string reportTimeStr = parts[5].Trim();

                if (string.IsNullOrWhiteSpace(reporterSecret) || string.IsNullOrWhiteSpace(reporterName) ||
                    string.IsNullOrWhiteSpace(targetSecret) || string.IsNullOrWhiteSpace(targetName) ||
                    string.IsNullOrWhiteSpace(reportText) || string.IsNullOrWhiteSpace(reportTimeStr))
                    continue;

                if (!DateTime.TryParse(reportTimeStr, CultureInfo.InvariantCulture, DateTimeStyles.AssumeLocal, out DateTime reportTime))
                    continue;

                int? reporterId = PeopleDAL.GetIdBySecretCode(reporterSecret);
                if (reporterId == null)
                {
                    PeopleFactory.AddPeople(reporterSecret, reporterName);
                    reporterId = PeopleDAL.GetIdBySecretCode(reporterSecret);
                }

                int? targetId = PeopleDAL.GetIdBySecretCode(targetSecret);
                if (targetId == null)
                {
                    PeopleFactory.AddPeople(targetSecret, targetName);
                    targetId = PeopleDAL.GetIdBySecretCode(targetSecret);
                }

                if (reporterId != null && targetId != null)
                {
                    ReportFacrory.AddReoport(reporterId.Value, targetId.Value, reportText, reportTime);
                    count++;
                }
            }

            Logger.Log($"CSVImport: Imported {count} reports from {path}");
            Console.WriteLine($"✅ Successfully imported {count} reports from: {path}");
        }
    }
}
