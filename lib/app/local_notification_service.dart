// import 'dart:async';
// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:flutter/material.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';
//
// class NotificationService {
//   static final StreamController<ReceivedAction> _actionStreamController =
//   StreamController<ReceivedAction>.broadcast();
//
//   // Initialize timezones
//   static Future<void> initializeTimeZones() async {
//     tz.initializeTimeZones();
//     final String timeZoneName = await FlutterTimezone.getLocalTimezone();
//     tz.setLocalLocation(tz.getLocation(timeZoneName));
//   }
//
//   static Future<void> initialize() async {
//     try {
//       await AwesomeNotifications().initialize(
//         null, // default icon
//         [
//           NotificationChannel(
//             channelKey: 'prayer_channel',
//             channelName: 'Prayer Times',
//             channelDescription: 'Notifications for prayer times',
//             importance: NotificationImportance.High,
//             defaultColor: Colors.green,
//             ledColor: Colors.green,
//             soundSource: 'resource://raw/res_sound',
//           )
//         ],
//       );
//
//       // Set up action listener
//       AwesomeNotifications().setListeners(
//         onActionReceivedMethod: _onActionReceived,
//       );
//
//       // Request notification permissions
//       final isAllowed = await AwesomeNotifications().isNotificationAllowed();
//       if (!isAllowed) {
//         await AwesomeNotifications().requestPermissionToSendNotifications();
//       }
//     } catch (e) {
//       debugPrint('Notification initialization error: $e');
//     }
//   }
//
//   // Handle received actions
//   static Future<void> _onActionReceived(ReceivedAction receivedAction) async {
//     _actionStreamController.add(receivedAction);
//   }
//
//   static Future<void> schedulePrayerNotifications(
//       Map<String, TimeOfDay> prayerTimes) async {
//     await AwesomeNotifications().cancelAll();
//
//     for (final entry in prayerTimes.entries) {
//       await _scheduleSingleNotification(
//         prayerName: entry.key,
//         time: entry.value,
//       );
//     }
//   }
//
//   static Future<void> _scheduleSingleNotification({
//     required String prayerName,
//     required TimeOfDay time,
//   }) async {
//     try {
//       final now = tz.TZDateTime.now(tz.local);
//       var scheduledTime = tz.TZDateTime(
//         tz.local,
//         now.year,
//         now.month,
//         now.day,
//         time.hour,
//         time.minute,
//       );
//
//       if (scheduledTime.isBefore(now)) {
//         scheduledTime = scheduledTime.add(const Duration(days: 1));
//       }
//
//       await AwesomeNotifications().createNotification(
//         content: NotificationContent(
//           id: _generateId(prayerName),
//           channelKey: 'prayer_channel',
//           title: 'Prayer Time',
//           body: 'Time for $prayerName',
//           payload: {'prayer': prayerName},
//         ),
//         schedule: NotificationCalendar(
//           hour: scheduledTime.hour,
//           minute: scheduledTime.minute,
//           second: 0,
//           millisecond: 0,
//           repeats: true,
//           allowWhileIdle: true,
//           preciseAlarm: true,
//         ),
//       );
//     } catch (e) {
//       debugPrint('Error scheduling $prayerName notification: $e');
//     }
//   }
//
//   static int _generateId(String prayerName) {
//     return prayerName.hashCode.abs() % 100000;
//   }
//
//   static Stream<ReceivedAction> get notificationStream =>
//       _actionStreamController.stream;
//
//   static void listenForActions(BuildContext context) {
//     notificationStream.listen((ReceivedAction action) {
//       final payload = action.payload;
//       if (payload != null && payload.containsKey('prayer')) {
//         final prayerName = payload['prayer'];
//         // Handle notification tap
//         debugPrint('Notification tapped for $prayerName');
//       }
//     });
//   }
//
//   static void dispose() {
//     _actionStreamController.close();
//   }
// }
// // class LocalNotificationService {
// //   static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
// //   FlutterLocalNotificationsPlugin();
// //
// //   static final StreamController<NotificationResponse> streamController =
// //   StreamController<NotificationResponse>.broadcast();
// //
// //   static Future<void> init() async {
// //     const AndroidInitializationSettings initializationSettingsAndroid =
// //     AndroidInitializationSettings('@mipmap/ic_launcher');
// //
// //     const InitializationSettings initializationSettings =
// //     InitializationSettings(
// //       android: initializationSettingsAndroid,
// //       iOS: DarwinInitializationSettings(),
// //     );
// //
// //     await flutterLocalNotificationsPlugin.initialize(
// //       initializationSettings,
// //       onDidReceiveNotificationResponse: onTap,
// //       onDidReceiveBackgroundNotificationResponse: onTap,
// //     );
// //   }
// //
// //   static void onTap(NotificationResponse notificationResponse) {
// //     streamController.add(notificationResponse);
// //   }
// //
// // // ... keep your other notification methods the same ...
// //
// //   //basic Notification
// //   static void showBasicNotification() async {
// //     AndroidNotificationDetails android = AndroidNotificationDetails(
// //         'id 1', 'basic notification',
// //         importance: Importance.max,
// //         priority: Priority.high,
// //         sound:
// //         RawResourceAndroidNotificationSound('sound.wav'.split('.').first));
// //     NotificationDetails details = NotificationDetails(
// //       android: android,
// //     );
// //     await flutterLocalNotificationsPlugin.show(
// //       0,
// //       'Baisc Notification',
// //       'body',
// //       details,
// //       payload: "Payload Data",
// //     );
// //   }
// //
// //   //basic Notification2
// //   static void showBasicNotification2() async {
// //     AndroidNotificationDetails android = AndroidNotificationDetails(
// //         'id 3', 'basic notification1',
// //         importance: Importance.max,
// //         priority: Priority.high,
// //         sound:
// //         RawResourceAndroidNotificationSound('sound.wav'.split('.').first));
// //     NotificationDetails details = NotificationDetails(
// //       android: android,
// //     );
// //     await flutterLocalNotificationsPlugin.show(
// //       4,
// //       'Basic Notification',
// //       'body',
// //       details,
// //       payload: "Payload Data",
// //     );
// //   }
// //
// //   //showRepeatedNotification
// //   static void showRepeatedNotification() async {
// //     const AndroidNotificationDetails android = AndroidNotificationDetails(
// //       'id 2',
// //       'repeated notification',
// //       importance: Importance.max,
// //       priority: Priority.high,
// //     );
// //     NotificationDetails details = const NotificationDetails(
// //       android: android,
// //     );
// //     await flutterLocalNotificationsPlugin.periodicallyShow(
// //       1,
// //       'Reapated Notification',
// //       'body',
// //       RepeatInterval.daily,
// //       details,
// //       payload: "Payload Data",
// //     );
// //   }
// //
// //   //showSchduledNotification
// //   static void showSchduledNotification(
// //       {required DateTime curretDate,
// //         required TimeOfDay schduledTime,
// //         required TaskModel taskModel}) async {
// //     const AndroidNotificationDetails android = AndroidNotificationDetails(
// //       'schduled notification',
// //       'id 3',
// //       importance: Importance.max,
// //       priority: Priority.high,
// //     );
// //     NotificationDetails details = const NotificationDetails(
// //       android: android,
// //     );
// //     tz.initializeTimeZones();
// //     log(tz.local.name);
// //     log("Before ${tz.TZDateTime.now(tz.local).hour}");
// //     final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
// //     log(currentTimeZone);
// //     tz.setLocalLocation(tz.getLocation(currentTimeZone));
// //     log(tz.local.name);
// //     log("After ${tz.TZDateTime.now(tz.local).hour}");
// //     await flutterLocalNotificationsPlugin.zonedSchedule(
// //       2,
// //       taskModel.title,
// //       taskModel.note,
// //       // tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
// //       tz.TZDateTime(
// //         tz.local,
// //         curretDate.year,
// //         curretDate.month,
// //         curretDate.day,
// //         schduledTime.hour,
// //         schduledTime.minute,
// //       ).subtract(const Duration(minutes: 1)),
// //       details,
// //       payload: 'Title: ${taskModel.title}  , Note: "${taskModel.note}',
// //       uiLocalNotificationDateInterpretation:
// //       UILocalNotificationDateInterpretation.absoluteTime,
// //     );
// //   }
// //
// //   static Future<void> showDailyScheduledNotification() async {
// //     try {
// //       // 1. Initialize timezones properly
// //       tz.initializeTimeZones();
// //       log(tz.local.name);
// //       log("Before ${tz.TZDateTime.now(tz.local).hour}");
// //       final String timeZoneName = await FlutterTimezone.getLocalTimezone();
// //       log(timeZoneName);
// //       log(tz.local.name);
// //       log("After ${tz.TZDateTime.now(tz.local).hour}");
// //       tz.setLocalLocation(tz.getLocation(timeZoneName));
// //
// //       // 2. Get current time in local timezone
// //       final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
// //
// //       // 3. Set notification time (9 PM today)
// //       tz.TZDateTime scheduledTime = tz.TZDateTime(
// //         tz.local,
// //         now.year,
// //         now.month,
// //         now.day,
// //         now.minute+10, // 9 PM
// //        // 0 minutes
// //       );
// //
// //       // 4. If time already passed today, schedule for tomorrow
// //       if (scheduledTime.isBefore(now)) {
// //         scheduledTime = scheduledTime.add(const Duration(minutes: 5));
// //       }
// //
// //       // 5. Create notification channel details
// //        AndroidNotificationDetails androidPlatformChannelSpecifics =
// //       AndroidNotificationDetails(
// //         'daily_scheduled_channel',
// //         'Daily Notifications',
// //         channelDescription: 'Channel for daily scheduled notifications',
// //         importance: Importance.max,
// //         priority: Priority.high,
// //         showWhen: true,
// //           sound:
// //           RawResourceAndroidNotificationSound('a.mp3'.split('.').first)
// //       );
// //
// //       // 6. Schedule the notification
// //       await flutterLocalNotificationsPlugin.zonedSchedule(
// //         3, // Notification ID
// //         'Write your tasks for tomorrow',
// //         'Have a productive day1222222222',
// //         scheduledTime,
// //          NotificationDetails(android: androidPlatformChannelSpecifics),
// //         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
// //         uiLocalNotificationDateInterpretation:
// //         UILocalNotificationDateInterpretation.absoluteTime,
// //         matchDateTimeComponents: DateTimeComponents.time,
// //       );
// //
// //       debugPrint('Notification scheduled for ${scheduledTime.toString()}');
// //     } catch (e, stackTrace) {
// //       debugPrint('Error scheduling notification: $e');
// //       debugPrint(stackTrace.toString());
// //     }
// //   }
// //
// //   static void cancelNotification(int id) async {
// //     await flutterLocalNotificationsPlugin.cancel(id);
// //   }
// // }
// //
// // //1.setup. [Done]
// // //2.Basic Notification. [Done]
// // //3.Repeated Notification. [Done]
// // //4.Scheduled Notification. [Done]
// // //5.Custom Sound. [Done]
// // //6.on Tab. [Done]
// // //7.Daily Notifications at specific time. [Done]
// // //8.Real Example in To Do App.
// //
// //
// // class TaskModel {
// //   final int? id;
// //   final String title;
// //   final String note;
// //   final String startTime;
// //   final String endTime;
// //   final String date;
// //   final int isCompleted;
// //   final int color;
// //
// //   TaskModel({
// //     this.id,
// //     required this.date,
// //     required this.title,
// //     required this.note,
// //     required this.startTime,
// //     required this.endTime,
// //     required this.isCompleted,
// //     required this.color,
// //   });
// //   factory TaskModel.fromJson(Map<String, dynamic> jsonData) {
// //     return TaskModel(
// //       id:jsonData['id'],
// //       date: jsonData['date'],
// //       title: jsonData['title'],
// //       note: jsonData['note'],
// //       startTime: jsonData['startTime'],
// //       endTime: jsonData['endTime'],
// //       isCompleted: jsonData['isCompleted'],
// //       color: jsonData['color'],
// //     );
// //   }
// // }