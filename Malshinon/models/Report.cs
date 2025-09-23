using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Malshinon.DAL;

namespace Malshinon.Classes
{
    internal class Report
    {
        private int ID;
        private int ReporterId;
        private int TargetId;
        private string Text;
        private DateTime? ReportTime;

        public int GetReportID() => this.ID;
        public int GetReporterId() => this.ReporterId;
        public int GetTergetId() => this.TargetId;
        public string GetText() => this.Text;
        public DateTime? GetReportTime() => this.ReportTime;

        public Report(int reporterId, int targetId, string text, DateTime? reportTime = null )
        {
            ReporterId = reporterId;
            TargetId = targetId;
            Text = text;
            ReportTime = reportTime;
            ReportDAL.InsertReport(this);
        }
    }
}
        