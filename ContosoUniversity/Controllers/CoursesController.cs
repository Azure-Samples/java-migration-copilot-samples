using System;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Net;
using System.Web.Mvc;
using System.IO;
using System.Web;
using ContosoUniversity.Data;
using ContosoUniversity.Models;

namespace ContosoUniversity.Controllers
{
    public class CoursesController : BaseController
    {
        // GET: Courses
        public ActionResult Index()
        {
            var courses = db.Courses.Include(c => c.Department);
            return View(courses.ToList());
        }

        // GET: Courses/Details/5
        public ActionResult Details(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            Course course = db.Courses.Include(c => c.Department).Where(c => c.CourseID == id).Single();
            if (course == null)
            {
                return HttpNotFound();
            }
            return View(course);
        }

        // GET: Courses/Create
        public ActionResult Create()
        {
            ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name");
            return View(new Course());
        }

        // POST: Courses/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create([Bind(Include = "CourseID,Title,Credits,DepartmentID,TeachingMaterialImagePath")] Course course, HttpPostedFileBase teachingMaterialImage)
        {
            if (ModelState.IsValid)
            {
                // Handle file upload if an image is provided
                if (teachingMaterialImage != null && teachingMaterialImage.ContentLength > 0)
                {
                    // Validate file type
                    var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".bmp" };
                    var fileExtension = Path.GetExtension(teachingMaterialImage.FileName).ToLower();
                    
                    if (!allowedExtensions.Contains(fileExtension))
                    {
                        ModelState.AddModelError("teachingMaterialImage", "Please upload a valid image file (jpg, jpeg, png, gif, bmp).");
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }

                    // Validate file size (max 5MB)
                    if (teachingMaterialImage.ContentLength > 5 * 1024 * 1024)
                    {
                        ModelState.AddModelError("teachingMaterialImage", "File size must be less than 5MB.");
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }

                    try
                    {
                        // Create uploads directory if it doesn't exist
                        var uploadsPath = Server.MapPath("~/Uploads/TeachingMaterials/");
                        if (!Directory.Exists(uploadsPath))
                        {
                            Directory.CreateDirectory(uploadsPath);
                        }

                        // Generate unique filename
                        var fileName = $"course_{course.CourseID}_{Guid.NewGuid()}{fileExtension}";
                        var filePath = Path.Combine(uploadsPath, fileName);

                        // Save file
                        teachingMaterialImage.SaveAs(filePath);
                        course.TeachingMaterialImagePath = $"~/Uploads/TeachingMaterials/{fileName}";
                    }
                    catch (Exception ex)
                    {
                        ModelState.AddModelError("teachingMaterialImage", "Error uploading file: " + ex.Message);
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }
                }

                db.Courses.Add(course);
                db.SaveChanges();
                
                // Send notification for course creation
                SendEntityNotification("Course", course.CourseID.ToString(), course.Title, EntityOperation.CREATE);
                
                return RedirectToAction("Index");
            }

            ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
            return View(course);
        }

        // GET: Courses/Edit/5
        public ActionResult Edit(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            Course course = db.Courses.Find(id);
            if (course == null)
            {
                return HttpNotFound();
            }
            ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
            return View(course);
        }

        // POST: Courses/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "CourseID,Title,Credits,DepartmentID,TeachingMaterialImagePath")] Course course, HttpPostedFileBase teachingMaterialImage)
        {
            if (ModelState.IsValid)
            {
                // Handle file upload if a new image is provided
                if (teachingMaterialImage != null && teachingMaterialImage.ContentLength > 0)
                {
                    // Validate file type
                    var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".bmp" };
                    var fileExtension = Path.GetExtension(teachingMaterialImage.FileName).ToLower();
                    
                    if (!allowedExtensions.Contains(fileExtension))
                    {
                        ModelState.AddModelError("teachingMaterialImage", "Please upload a valid image file (jpg, jpeg, png, gif, bmp).");
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }

                    // Validate file size (max 5MB)
                    if (teachingMaterialImage.ContentLength > 5 * 1024 * 1024)
                    {
                        ModelState.AddModelError("teachingMaterialImage", "File size must be less than 5MB.");
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }

                    try
                    {
                        // Create uploads directory if it doesn't exist
                        var uploadsPath = Server.MapPath("~/Uploads/TeachingMaterials/");
                        if (!Directory.Exists(uploadsPath))
                        {
                            Directory.CreateDirectory(uploadsPath);
                        }

                        // Generate unique filename
                        var fileName = $"course_{course.CourseID}_{Guid.NewGuid()}{fileExtension}";
                        var filePath = Path.Combine(uploadsPath, fileName);

                        // Delete old file if exists
                        if (!string.IsNullOrEmpty(course.TeachingMaterialImagePath))
                        {
                            var oldFilePath = Server.MapPath(course.TeachingMaterialImagePath);
                            if (System.IO.File.Exists(oldFilePath))
                            {
                                System.IO.File.Delete(oldFilePath);
                            }
                        }

                        // Save new file
                        teachingMaterialImage.SaveAs(filePath);
                        course.TeachingMaterialImagePath = $"~/Uploads/TeachingMaterials/{fileName}";
                    }
                    catch (Exception ex)
                    {
                        ModelState.AddModelError("teachingMaterialImage", "Error uploading file: " + ex.Message);
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }
                }

                db.Entry(course).State = EntityState.Modified;
                db.SaveChanges();
                
                // Send notification for course update
                SendEntityNotification("Course", course.CourseID.ToString(), course.Title, EntityOperation.UPDATE);
                
                return RedirectToAction("Index");
            }
            ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
            return View(course);
        }

        // GET: Courses/Delete/5
        public ActionResult Delete(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            Course course = db.Courses.Include(c => c.Department).Where(c => c.CourseID == id).Single();
            if (course == null)
            {
                return HttpNotFound();
            }
            return View(course);
        }

        // POST: Courses/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int id)
        {
            Course course = db.Courses.Find(id);
            var courseTitle = course.Title;
            
            // Delete associated image file if it exists
            if (!string.IsNullOrEmpty(course.TeachingMaterialImagePath))
            {
                var filePath = Server.MapPath(course.TeachingMaterialImagePath);
                if (System.IO.File.Exists(filePath))
                {
                    try
                    {
                        System.IO.File.Delete(filePath);
                    }
                    catch (Exception ex)
                    {
                        // Log the error but don't prevent deletion of the course
                        // In a production application, you would log this error properly
                        System.Diagnostics.Debug.WriteLine($"Error deleting file: {ex.Message}");
                    }
                }
            }
            
            db.Courses.Remove(course);
            db.SaveChanges();
            
            // Send notification for course deletion
            SendEntityNotification("Course", id.ToString(), courseTitle, EntityOperation.DELETE);
            
            return RedirectToAction("Index");
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                // Base class will dispose db and notificationService
            }
            base.Dispose(disposing);
        }
    }
}
