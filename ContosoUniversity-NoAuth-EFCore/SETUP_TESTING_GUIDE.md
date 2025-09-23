# Setup and Testing Guide for Notification System

## Prerequisites

1. **Enable MSMQ on Windows**:
   - Open "Turn Windows features on or off" (search for "Windows Features")
   - Navigate to "Microsoft Message Queue (MSMQ) Server"
   - Expand "Microsoft Message Queue (MSMQ) Server"
   - Check the following components:
     - ✅ **Microsoft Message Queue (MSMQ) Server Core** (required)
     - ❌ **MSMQ Active Directory Domain Services Integration** (not needed for private queues)
     - ❌ **MSMQ HTTP Support** (not needed for local queues)
   - Click OK and restart if prompted

2. **Verify MSMQ Installation**:
   - Open Computer Management (compmgmt.msc)
   - Navigate to "Services and Applications" → "Message Queuing"
   - You should see "Private Queues" folder

## Building the Project

1. Open the solution in Visual Studio
2. Restore NuGet packages if prompted
3. Build the solution (Ctrl+Shift+B)

## Testing the Notification System

### Step 1: Run the Application
1. Press F5 to start debugging
2. The application will launch in your default browser

### Step 2: Login as Administrator
1. The application uses Windows Authentication
2. Ensure your Windows user is in the administrator role
3. You should see "Administrator" label next to your username

### Step 3: Access Notification Dashboard
1. Click "Notifications" in the main navigation menu
2. This page explains the notification system and provides test links

### Step 4: Test Notifications
1. **Create a Student**:
   - Click "Students" → "Create New"
   - Fill in the form and submit
   - Watch for a green notification in the top-right corner

2. **Edit a Student**:
   - Go to Students list, click "Edit" on any student
   - Make changes and save
   - Watch for a blue notification

3. **Delete a Student**:
   - Go to Students list, click "Delete" on any student
   - Confirm deletion
   - Watch for an orange notification

4. **Test Other Entities**:
   - Repeat the same process for Courses, Instructors, and Departments
   - Each operation should trigger appropriate notifications

### Step 5: Verify MSMQ Queue
1. Open Computer Management (compmgmt.msc)
2. Navigate to "Message Queuing" → "Private Queues"
3. You should see "contosouniversitynotifications" queue
4. Check queue properties to see message statistics

## Troubleshooting

### No Notifications Appearing
1. **Check Browser Console**: Press F12 and look for JavaScript errors
2. **Check Network Tab**: Verify calls to `/Notifications/GetNotifications` are happening
3. **Check MSMQ**: Verify the queue exists and has messages

### MSMQ Errors
1. **Queue Access Denied**: 
   - Right-click the queue → Properties → Security
   - Add your user with Full Control permissions

2. **Queue Not Created**:
   - Ensure MSMQ is properly installed with the correct components
   - Check application pool identity has permissions
   - Verify only **MSMQ Server Core** is needed (not Active Directory or HTTP support)

3. **MSMQ Installation Issues**:
   - **Windows 10/11 Home**: MSMQ is not available on Home editions - upgrade to Pro/Enterprise
   - **Missing MSMQ Service**: After installation, verify "Message Queuing" service is running
   - **Permission Errors**: Run Visual Studio as Administrator during development
   - **Queue Path Issues**: The system uses private queues (.\Private$\) which don't require domain integration

### JavaScript Not Loading
1. **Admin Role Check**: Ensure you're logged in as administrator
2. **File Paths**: Verify `notifications.js` and `notifications.css` files exist
3. **Browser Cache**: Clear cache and refresh

## Configuration Notes

- **Queue Path**: Configured in Web.config as `.\Private$\ContosoUniversityNotifications`
- **Polling Interval**: JavaScript checks for new notifications every 5 seconds
- **Auto-dismiss**: Notifications automatically disappear after 1 minute (60 seconds)
- **Max Notifications**: Maximum of 5 notifications shown simultaneously

## Production Considerations

For production deployment:

1. **MSMQ Setup**: Ensure MSMQ is installed on production servers
2. **Permissions**: Configure appropriate queue permissions for the application pool identity
3. **Monitoring**: Monitor queue length and message processing
4. **Backup**: Consider MSMQ backup strategies for message persistence
5. **Load Balancing**: For multiple servers, consider centralized MSMQ server

## Development Tips

- Notifications are designed to be non-blocking - MSMQ failures won't break main operations
- Debug output shows notification send/receive operations
- Use notification dashboard to understand system behavior
- Test with multiple admin users to verify isolation
