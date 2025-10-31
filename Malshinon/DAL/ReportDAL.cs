using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Malshinon.Classes;

namespace Malshinon.DAL
{
    static class ReportDAL
    {
        static public void ShowAllReports()
        {
            string SQLQuery = $"SELECT * FROM reports";
            var result = DBConnection.Execute(SQLQuery);
            DBConnection.PrintResult(result);
        }

        static public List<Dictionary<string, object>> GetAllReports()
        {
            string SQLQuery = $"SELECT * FROM reports";
            var result = DBConnection.Execute(SQLQuery);
            return result;
        }
        public static object InsertReport(Report newReport)
        {
            bool hasTime = newReport.GetReportTime() != null;
            int reporterId = newReport.GetReporterId();
            int targetId = newReport.GetTergetId();

            List<Dictionary<string, object>> allPeoples = PeopleDAL.GetAllPeoples();

            bool reporterExists = allPeoples.Any(p => Convert.ToInt32(p["id"]) == reporterId);
            if (!reporterExists)
            {
                Logger.Log($"Reporter ID {reporterId} does not exist.");
                Console.WriteLine($"Reporter ID {reporterId} does not exist.");
                return null;
            }
            bool targetExists = allPeoples.Any(p => Convert.ToInt32(p["id"]) == targetId);
            if (!targetExists)
            {
                Logger.Log($"Target ID {targetId} does not exist.");
                return null;
            }

            string columns = "reporterId, targetId, reportText";
            string values = $"'{reporterId}', '{targetId}', '{newReport.GetText()}'";

            if (hasTime)
            {
                columns += ", submittedAt";
                values += $", '{newReport.GetReportTime():yyyy-MM-dd HH:mm:ss}'";
            }

            string SQLQuery = $"INSERT INTO reports ({columns}) VALUES ({values})";
            var result = DBConnection.Execute(SQLQuery);

            if (PeopleDAL.IsDangerous(targetId))
            {
                Logger.Log($"People with id {targetId} is dangerous!");
                PeopleDAL.MakePeopleDangerous(targetId);
            }

            if (PeopleDAL.IsAgent(reporterId))
            {
                Logger.Log($"People with id {reporterId} is agent!");
                PeopleDAL.MakePeopleAgent(reporterId);
            }
            Logger.Log($"Report {newReport.GetReporterId()} -> {newReport.GetTergetId()} added succusfully.");
            return result;
        }

    }
}
