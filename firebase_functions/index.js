const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Tự động gửi thông báo khi Admin thêm dữ liệu vào collection 'notifications'
 */
exports.sendAdminNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();
        const title = data.title;
        const body = data.body;
        const targetGroup = data.targetGroup; // 'all' hoặc 'inactive'

        // Xác định Topic tương ứng
        const topic = targetGroup === 'all' ? 'all_users' : 'inactive_users';

        const message = {
            notification: {
                title: title,
                body: body,
            },
            topic: topic,
            // Thêm các cấu hình phụ cho Android/iOS nếu cần
            android: {
                notification: {
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                    sound: 'default',
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                    },
                },
            },
        };

        try {
            // Thực hiện gửi qua FCM
            const response = await admin.messaging().send(message);
            console.log('Successfully sent message to topic:', topic, response);

            // Cập nhật trạng thái thành công vào Firestore
            return snapshot.ref.update({
                status: 'sent',
                messageId: response,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        } catch (error) {
            console.error('Error sending message:', error);
            return snapshot.ref.update({
                status: 'error',
                error: error.message,
            });
        }
    });
