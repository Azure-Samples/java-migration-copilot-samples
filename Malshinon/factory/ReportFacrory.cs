using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Malshinon.Classes;
using Malshinon.DAL;

namespace Malshinon.factory
{
    internal class ReportFacrory
    {
        public static List<Dictionary<string, object>> GetAllReports()
        {
            List<Dictionary<string, object>> allReports = ReportDAL.GetAllReports();
            return allReports;
        }

        public static Report AddReoport(int reporterId, int targetId, string text, DateTime? reportTime = null)
        {
            Report newReport = new Report(reporterId, targetId, text, reportTime);
            return newReport;
        }
    }
}
