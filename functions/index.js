const functions = require("firebase-functions/v1");
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendadminnotification = functions.region('asia-east2').firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();
        if (!data) return null;

        const topic = data.targetGroup === 'all' ? 'all_users' : 'inactive_users';

        const message = {
            notification: {
                title: data.title || 'Thông báo từ TOEIC Tracker',
                body: data.body || '',
            },
            topic: topic,
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
            const response = await admin.messaging().send(message);
            console.log('Successfully sent message to topic:', topic, response);

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
