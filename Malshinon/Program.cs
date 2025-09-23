using System;
using Malshinon.Classes;
using Malshinon.DAL;
using Malshinon.factory;

namespace Malshinon
{
    internal class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("\t==== Welcome to Malshinon system! ====");

            while (true)
            {
                ShowMenu();
                string choice = ReadInput("Choose an option:");

                switch (choice)
                {
                    case "1":
                        AddNewPerson();
                        break;
                    case "2":
                        InsertNewReport();
                        break;
                    case "3":
                        ImportCsv();
                        break;
                    case "4":
                        ShowAllLogs();
                        break;
                    case "5":
                        ShowAllPeople();
                        break;
                    case "6":
                        ShowAllReports();
                        break;
                    case "7":
                        ShowAllPeopleInformation();
                        break;
                    case "0":
                        Console.WriteLine("Exiting... Goodbye!");
                        return;
                    default:
                        PrintError("Invalid choice, please try again.");
                        break;
                }
            }
        }

        static void ShowMenu()
        {
            Console.WriteLine("==== Malshinon Menu ====");
            Console.WriteLine("1 - Add new person");
            Console.WriteLine("2 - Insert new report");
            Console.WriteLine("3 - Import CSV");
            Console.WriteLine("4 - Show all logs");
            Console.WriteLine("5 - Show all people");
            Console.WriteLine("6 - Show all reports");
            Console.WriteLine("7 - Show dashboard");
            Console.WriteLine("0 - Exit");
        }

        static void AddNewPerson()
        {
            string fullName = ReadInput("Enter a full name for the new person:");
            string secretCode = ReadInput("Enter a secret code for the new person (must be unique):", true);

            PeopleFactory.AddPeople(secretCode, fullName);
        }

        static void InsertNewReport()
        {
            string reporterSecretCode = ReadInput("Please enter the secret code of the reporter:", true);
            int? reporterId = GetOrCreatePersonId(reporterSecretCode);
            if (reporterId is null)
            {
                PrintError("Cannot proceed without valid reporter.");
                return;
            }

            string targetSecretCode = ReadInput("Please enter the secret code of the target:", true);
            int? targetId = GetOrCreatePersonId(targetSecretCode);
            if (targetId is null)
            {
                PrintError("Cannot proceed without valid target.");
                return;
            }

            string text = ReadInput("Enter the content of the report:");
            string choice = ReadInput("Do you want to enter the time of the report? (Y)\n\tPress any key to choose current time: ", true);

            if (choice == "y")
            {
                SendingWithAddTime(reporterId.Value, targetId.Value, text);
            }
            else
            {
                ReportFacrory.AddReoport(reporterId.Value, targetId.Value, text);
                Console.WriteLine("Report with current time was successfully added.");
            }
        }

        static void ImportCsv()
        {
            CSV.ImportCsv();
        }

        static void ShowAllLogs()
        {
            Console.WriteLine(Logger.Read());
        }

        static void ShowAllPeople()
        {
            PeopleDAL.ShowAllPeoples();
        }

        static void ShowAllReports()
        {
            ReportDAL.ShowAllReports();
        }

        static void ShowAllPeopleInformation()
        {
            PeopleDAL.ShowAllPeoplesInformation();
        }

        static void SendingWithAddTime(int reporterId, int targetId, string text)
        {
            while (true)
            {
                string input = ReadInput("Enter the time in format 'YEAR/MONTH/DAY/HOUR/MINUTE/SECOND':");

                if (DateTime.TryParseExact(input, "yyyy/M/d/H/m/s", null, System.Globalization.DateTimeStyles.None, out DateTime reportTime))
                {
                    ReportFacrory.AddReoport(reporterId, targetId, text, reportTime);
                    Console.WriteLine("Report with original time was successfully added.");
                    return;
                }

                PrintError("Invalid time format. Try again.");
            }
        }

        static int? GetOrCreatePersonId(string secretCode)
        {
            int? personId = PeopleDAL.GetIdBySecretCode(secretCode);
            if (personId is null)
            {
                Console.WriteLine("Secret code not found.");
                string createChoice = ReadInput("Do you want to create a new person with this secret code? (Y)", true);

                if (createChoice == "y")
                {
                    PeopleFactory.AddPeople(secretCode);
                    personId = PeopleDAL.GetIdBySecretCode(secretCode);
                }
            }
            return personId;
        }

        static string ReadInput(string prompt, bool toLower = false)
        {
            Console.WriteLine(prompt);
            string input = Console.ReadLine().Trim();
            return toLower ? input.ToLower() : input;
        }

        static void PrintError(string message)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine(message);
            Console.ResetColor();
        }
    }
}
