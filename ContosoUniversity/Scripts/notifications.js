// Notification System for Admin Users
(function() {
    'use strict';

    var NotificationSystem = {
        container: null,
        notificationCount: 0,
        checkInterval: 5000, // Check every 5 seconds
        maxNotifications: 5,

        init: function() {
            this.createContainer();
            this.startPolling();
        },

        createContainer: function() {
            this.container = document.createElement('div');
            this.container.className = 'notification-container';
            document.body.appendChild(this.container);
        },

        startPolling: function() {
            var self = this;
            // Check immediately
            this.checkForNotifications();
            
            // Then check every interval
            setInterval(function() {
                self.checkForNotifications();
            }, this.checkInterval);
        },

        checkForNotifications: function() {
            var self = this;
            
            fetch('/Notifications/GetNotifications', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
                credentials: 'same-origin'
            })
            .then(function(response) {
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.json();
            })
            .then(function(data) {
                if (data.success && data.notifications && data.notifications.length > 0) {
                    data.notifications.forEach(function(notification) {
                        self.showNotification(notification);
                    });
                }
            })
            .catch(function(error) {
                console.log('Error fetching notifications:', error);
            });
        },

        showNotification: function(notification) {
            var self = this;
            
            // Create notification element
            var notificationEl = document.createElement('div');
            notificationEl.className = 'notification notification-info';
            
            // Determine notification type based on operation
            var type = 'info';
            if (notification.Operation === 'CREATE') {
                type = 'success';
            } else if (notification.Operation === 'DELETE') {
                type = 'warning';
            }
            
            notificationEl.className = 'notification notification-' + type;
            
            var timeAgo = this.getTimeAgo(new Date(notification.CreatedAt));
            
            notificationEl.innerHTML = 
                '<button class="notification-close" onclick="NotificationSystem.closeNotification(this)">&times;</button>' +
                '<div class="notification-title">' + notification.Operation + ' - ' + notification.EntityType + '</div>' +
                '<div class="notification-message">' + notification.Message + '</div>' +
                '<div class="notification-time">By ' + notification.CreatedBy + ' • ' + timeAgo + '</div>';
            
            // Add to container
            this.container.appendChild(notificationEl);
            
            // Animate in
            setTimeout(function() {
                notificationEl.classList.add('show');
            }, 100);
            
            // Auto remove after 1 minute (60 seconds)
            setTimeout(function() {
                self.closeNotification(notificationEl.querySelector('.notification-close'));
            }, 60000);
            
            // Limit number of notifications
            this.limitNotifications();
        },

        closeNotification: function(closeButton) {
            var notification = closeButton.parentElement;
            notification.classList.remove('show');
            
            setTimeout(function() {
                if (notification.parentElement) {
                    notification.parentElement.removeChild(notification);
                }
            }, 300);
        },

        limitNotifications: function() {
            var notifications = this.container.querySelectorAll('.notification');
            while (notifications.length > this.maxNotifications) {
                var oldest = notifications[0];
                this.closeNotification(oldest.querySelector('.notification-close'));
                notifications = this.container.querySelectorAll('.notification');
            }
        },

        getTimeAgo: function(date) {
            var now = new Date();
            var diffInSeconds = Math.floor((now - date) / 1000);
            
            if (diffInSeconds < 60) {
                return 'just now';
            } else if (diffInSeconds < 3600) {
                var minutes = Math.floor(diffInSeconds / 60);
                return minutes + ' minute' + (minutes > 1 ? 's' : '') + ' ago';
            } else if (diffInSeconds < 86400) {
                var hours = Math.floor(diffInSeconds / 3600);
                return hours + ' hour' + (hours > 1 ? 's' : '') + ' ago';
            } else {
                var days = Math.floor(diffInSeconds / 86400);
                return days + ' day' + (days > 1 ? 's' : '') + ' ago';
            }
        }
    };

    // Auto-initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            NotificationSystem.init();
        });
    } else {
        NotificationSystem.init();
    }

    // Make NotificationSystem globally available for close button
    window.NotificationSystem = NotificationSystem;
})();
