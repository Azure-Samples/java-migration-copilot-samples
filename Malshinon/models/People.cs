using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Malshinon.DAL;

namespace Malshinon.Classes
{
    internal class People
    {
        private int ID;
        private string FullName;
        private string SecretCode;
        private bool IsAgent;
        private bool IsDangerous;

        public int GetPeopleID() => this.ID;
        public string GetFullName() => this.FullName;
        public string GetSecretCode() => this.SecretCode;
        public bool IsPeopleAgent() => this.IsAgent;
        public bool IsPeopleDangerous() => this.IsDangerous;

        public People(string fullName, string secretCode)
        {
            FullName = fullName;
            SecretCode = secretCode;
            IsAgent = false;
            IsDangerous = false;
            PeopleDAL.InsertNewPeople(this);
        }
    }
}
