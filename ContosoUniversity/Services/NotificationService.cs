using System;
using System.Messaging;
using System.Configuration;
using ContosoUniversity.Models;
using Newtonsoft.Json;

namespace ContosoUniversity.Services
{
    public class NotificationService
    {
        private readonly string _queuePath;
        private readonly MessageQueue _queue;

        public NotificationService()
        {
            // Get queue path from configuration or use default
            _queuePath = ConfigurationManager.AppSettings["NotificationQueuePath"] ?? @".\Private$\ContosoUniversityNotifications";
            
            // Ensure the queue exists
            if (!MessageQueue.Exists(_queuePath))
            {
                _queue = MessageQueue.Create(_queuePath);
                _queue.SetPermissions("Everyone", MessageQueueAccessRights.FullControl);
            }
            else
            {
                _queue = new MessageQueue(_queuePath);
            }
            
            // Configure queue formatter
            _queue.Formatter = new XmlMessageFormatter(new Type[] { typeof(string) });
        }

        public void SendNotification(string entityType, string entityId, EntityOperation operation, string userName = null)
        {
            SendNotification(entityType, entityId, null, operation, userName);
        }

        public void SendNotification(string entityType, string entityId, string entityDisplayName, EntityOperation operation, string userName = null)
        {
            try
            {
                var notification = new Notification
                {
                    EntityType = entityType,
                    EntityId = entityId,
                    Operation = operation.ToString(),
                    Message = GenerateMessage(entityType, entityId, entityDisplayName, operation),
                    CreatedAt = DateTime.Now,
                    CreatedBy = userName ?? "System",
                    IsRead = false
                };

                var jsonMessage = JsonConvert.SerializeObject(notification);
                var message = new Message(jsonMessage)
                {
                    Label = $"{entityType} {operation}",
                    Priority = MessagePriority.Normal
                };

                _queue.Send(message);
            }
            catch (Exception ex)
            {
                // Log error but don't break the main operation
                System.Diagnostics.Debug.WriteLine($"Failed to send notification: {ex.Message}");
            }
        }

        public Notification ReceiveNotification()
        {
            try
            {
                var message = _queue.Receive(TimeSpan.FromSeconds(1));
                var jsonContent = message.Body.ToString();
                return JsonConvert.DeserializeObject<Notification>(jsonContent);
            }
            catch (MessageQueueException ex) when (ex.MessageQueueErrorCode == MessageQueueErrorCode.IOTimeout)
            {
                // No messages available
                return null;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to receive notification: {ex.Message}");
                return null;
            }
        }

        public void MarkAsRead(int notificationId)
        {
            // In a real implementation, you might want to store notifications in database as well
            // for persistence and tracking read status
        }

        private string GenerateMessage(string entityType, string entityId, string entityDisplayName, EntityOperation operation)
        {
            var displayText = !string.IsNullOrWhiteSpace(entityDisplayName) 
                ? $"{entityType} '{entityDisplayName}'" 
                : $"{entityType} (ID: {entityId})";

            switch (operation)
            {
                case EntityOperation.CREATE:
                    return $"New {displayText} has been created";
                case EntityOperation.UPDATE:
                    return $"{displayText} has been updated";
                case EntityOperation.DELETE:
                    return $"{displayText} has been deleted";
                default:
                    return $"{displayText} operation: {operation}";
            }
        }

        public void Dispose()
        {
            _queue?.Dispose();
        }
    }
}
