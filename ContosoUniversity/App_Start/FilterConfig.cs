using System.Web.Mvc;

namespace ContosoUniversity
{
    public class FilterConfig
    {
        public static void RegisterGlobalFilters(GlobalFilterCollection filters)
        {
            filters.Add(new HandleErrorAttribute());
            // Remove the global authorization filter since we're implementing role-based authorization
            // filters.Add(new AuthorizeAttribute()); // Require authentication for all controllers
        }
    }
}
