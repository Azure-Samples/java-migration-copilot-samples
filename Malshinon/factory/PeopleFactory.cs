using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Malshinon.Classes;
using Malshinon.DAL;

namespace Malshinon.factory
{
    static class PeopleFactory
    {
        public static List<Dictionary<string, object>> GetAllPeople()
        {
            List<Dictionary<string, object>> allPeople = PeopleDAL.GetAllPeoples();
            return allPeople;
        }

        public static People AddPeople(string secretCode, string fullName = null)
        {
            if (fullName is null)
            {
                Console.WriteLine($"Enter a fullName for '{secretCode}'.");
                fullName = Console.ReadLine();
            }
            People newPeople = new People(fullName, secretCode);
            return newPeople;
        }
    }
}
