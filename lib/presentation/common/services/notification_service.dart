//
// import 'package:flutter/material.dart';
//
//
// import '../../app/app_pref.dart';
//
// import '../resources/strings_manager.dart';
//
// const Map<String, String> _prayerArabicNames = {
//   "fajr": "أذان الفجر",
//   "dhuhr": "أذان الظهر",
//   "asr": "أذان العصر",
//   "maghrib": "أذان المغرب",
//   "isha": "أذان العشاء",
//   "azkarSobh": "أذكار الصباح",
//   "azkarMassa": "أذكار المساء",
// };
//
// @pragma('vm:entry-point')
// class NotificationService {
//   static late Box box;
//   static late AppPreferences preferences;
//   static String fagrAzanSound = '';
//   static String salaahAzanSound = '';
//   static const String _channelA = 'channel_a';
//   static const String _channelB = 'channel_b';
//   static const String _channelC = 'channel_c';
//   static const String _fallbackChannel = 'critical_notifications';
//
//   static const int _fajrId = 101;
//   static const int _dhuhrId = 102;
//   static const int _asrId = 103;
//   static const int _maghribId = 104;
//   static const int _ishaId = 105;
//   static const int _azkarSobh = 106;
//   static const int _azkarMassa = 107;
//
//   static Future<void> initialize() async {
//     // debugPrint("[NotificationService][initialize] Initializing service...");
//     try {
//       await AwesomeNotifications().initialize(null, [
//         NotificationChannel(
//           channelKey: 'prayer_channel',
//           channelName: 'Prayer Notifications',
//           channelDescription: 'Notifications for daily prayer times',
//           defaultColor: const Color(0xFF9D50DD),
//           importance: NotificationImportance.High,
//           ledColor: Colors.white,
//         ),
//       ], debug: true);
//
//       FlutterForegroundTask.init(
//         androidNotificationOptions: AndroidNotificationOptions(
//           channelId: 'foreground_channel_id',
//           channelName: 'Foreground Service',
//           channelDescription: 'Keeps the app alive to reschedule alarms',
//           channelImportance: NotificationChannelImportance.LOW,
//           priority: NotificationPriority.LOW,
//         ),
//         iosNotificationOptions: const IOSNotificationOptions(),
//         foregroundTaskOptions: ForegroundTaskOptions(
//           eventAction: ForegroundTaskEventAction.repeat(12),
//         ),
//       );
//       // debugPrint("[DEBUG] Service initialization completed");
//     } catch (e) {
//       // debugPrint("[ERROR] Initialize failed: $e");
//     }
//   }
//
//   static Future<void> initializeHive() async {
//     try {
//       final appDocumentDir = await getApplicationDocumentsDirectory();
//       Hive.init(appDocumentDir.path);
//
//       if (!Hive.isAdapterRegistered(0)) {
//         Hive.registerAdapter(PrayerDataEntityAdapter());
//       }
//       if (!Hive.isAdapterRegistered(1)) {
//         Hive.registerAdapter(CalenderEntityAdapter());
//       }
//
//       box = await Hive.openBox(AppStrings.salahTimeBox);
//       // debugPrint("[DEBUG] Hive initialized with ${box.length} entries");
//     } catch (e) {
//       // debugPrint("[ERROR] Hive initialization failed: $e");
//     }
//   }
//
//   static Future<void> initializeApp() async {
//     // debugPrint(
//     //   "[NotificationService][initializeApp] Initializing app components",
//     // );
//     try {
//       await initializeHive();
//       preferences = AppPreferences();
//       await preferences.init();
//
//       fagrAzanSound = preferences.getKFajrAzanSound();
//       salaahAzanSound = preferences.getKSalahAzanSound();
//       // debugPrint(
//       //   "[DEBUG] Sound files loaded - Fajr: $fagrAzanSound, Salah: $salaahAzanSound",
//       // );
//
//       await _initializeNotificationChannels();
//       AwesomeNotifications().setListeners(
//         onActionReceivedMethod: onActionReceivedMethod,
//         onNotificationCreatedMethod: onNotificationCreatedMethod,
//         onNotificationDisplayedMethod: onNotificationDisplayedMethod,
//         onDismissActionReceivedMethod: onDismissActionReceivedMethod,
//       );
//
//       await AndroidAlarmManager.initialize();
//       await startDailyAlarm();
//       // debugPrint("[DEBUG] App initialization completed successfully");
//     } catch (e) {
//       // debugPrint("[ERROR] App initialization failed: $e");
//     }
//   }
//
//   @pragma('vm:entry-point')
//   static Future<void> dailyRescheduleCallback() async {
//     // debugPrint("[DAILY RESCHEDULE] Triggered at ${DateTime.now().toLocal()}");
//     try {
//       WidgetsFlutterBinding.ensureInitialized();
//       // debugPrint("[DEBUG] Widgets binding initialized");
//
//       await initializeHive();
//       preferences = AppPreferences();
//       await preferences.init();
//
//       // debugPrint("[DEBUG] Starting daily reschedule process");
//       await scheduleAllNotifications();
//       // debugPrint("[DEBUG] Daily reschedule completed successfully");
//     } catch (e) {
//       // debugPrint("[ERROR] Daily reschedule failed: $e");
//     }
//   }
//
//   static Future<void> startDailyAlarm() async {
//     // debugPrint("[ALARM] Setting up daily alarm");
//     try {
//       const alarmId = 999;
//       await AndroidAlarmManager.cancel(alarmId);
//
//       final now = DateTime.now().toLocal();
//       var scheduledTime = DateTime(now.year, now.month, now.day, 1);
//
//       // debugPrint("[DEBUG] Current time: ${DateFormat('HH:mm:ss').format(now)}");
//       // debugPrint(
//       //   "[DEBUG] Initial alarm time: ${DateFormat('HH:mm:ss').format(scheduledTime)}",
//       // );
//
//       if (scheduledTime.isBefore(now)) {
//         scheduledTime = scheduledTime.add(const Duration(days: 1));
//         // debugPrint(
//         //   "[DEBUG] Adjusted alarm time to next day: ${DateFormat('HH:mm:ss').format(scheduledTime)}",
//         // );
//       }
//
//       await AndroidAlarmManager.oneShotAt(
//         scheduledTime,
//         alarmId,
//         dailyRescheduleCallback,
//         exact: true,
//         wakeup: true,
//         rescheduleOnReboot: true,
//       );
//       // debugPrint(
//       //   "[ALARM] Scheduled successfully for ${DateFormat('yyyy-MM-dd HH:mm').format(scheduledTime)}",
//       // );
//     } catch (e) {
//       // debugPrint("[ERROR] Alarm setup failed: $e");
//     }
//   }
//
//   static Future<void> _initializeNotificationChannels() async {
//     try {
//       await AwesomeNotifications().initialize(null, [
//         NotificationChannel(
//           channelKey: _channelA,
//           channelName: 'Fajr',
//           channelDescription: 'Fajr alerts',
//           importance: NotificationImportance.High,
//           playSound: true,
//           soundSource: 'resource://raw/$fagrAzanSound',
//           defaultColor: Colors.teal,
//           ledColor: Colors.teal,
//         ),
//         NotificationChannel(
//           channelKey: _channelB,
//           channelName: 'Salah Notifications',
//           channelDescription: 'Salah prayer alerts',
//           importance: NotificationImportance.High,
//           playSound: true,
//           soundSource: 'resource://raw/$salaahAzanSound',
//           defaultColor: Colors.deepPurple,
//           ledColor: Colors.deepPurple,
//         ),
//         NotificationChannel(
//           channelKey: _channelC,
//           channelName: 'Azkar Notifications',
//           channelDescription: 'Azkar prayer alerts',
//           importance: NotificationImportance.High,
//           playSound: true,
//           soundSource: 'resource://raw/o',
//           defaultColor: Colors.orange,
//           ledColor: Colors.orange,
//         ),
//         NotificationChannel(
//           channelKey: _fallbackChannel,
//           channelName: 'Critical Alerts',
//           channelDescription: 'Important system notifications',
//           importance: NotificationImportance.High,
//           playSound: true,
//         ),
//       ], debug: true);
//       // debugPrint("[DEBUG] Notification channels initialized");
//     } catch (e) {
//       // debugPrint("[ERROR] Channel initialization failed: $e");
//     }
//   }
//
//   static Future<void> scheduleAllNotifications() async {
//     // debugPrint("[NOTIFICATIONS] Starting scheduling process");
//     try {
//       await cancelAllSchedules();
//       final now = DateTime.now().toLocal();
//       final currentMonthStr = now.month.toString();
//       final currentDayIndex = now.day - 1;
//
//       // debugPrint(
//       //   "[DEBUG] Loading data for month $currentMonthStr day ${now.day}",
//       // );
//       final salahList =
//           box.get(currentMonthStr, defaultValue: dummyPrayerData) as List;
//
//       if (salahList.isEmpty || currentDayIndex >= salahList.length) {
//         // debugPrint("[ERROR] No prayer data available for today");
//         return;
//       }
//
//       final prayerTimes = salahList[currentDayIndex] as PrayerDataEntity;
//       // debugPrint("[DEBUG] Retrieved prayer times: ${prayerTimes.toString()}");
//
//       await _schedulePrayer(
//         "fajr",
//         _fajrId,
//         _channelA,
//         prayerTimes.fajrTime,
//         preferences.getKFajrEnabled(),
//       );
//       await _schedulePrayer(
//         "dhuhr",
//         _dhuhrId,
//         _channelB,
//         prayerTimes.dhuhrTime,
//         preferences.getKDhuhrEnabled(),
//       );
//       await _schedulePrayer(
//         "asr",
//         _asrId,
//         _channelB,
//         prayerTimes.asrTime,
//         preferences.getKAsrEnabled(),
//       );
//       await _schedulePrayer(
//         "maghrib",
//         _maghribId,
//         _channelB,
//         prayerTimes.maghribTime,
//         preferences.getKMaghribEnabled(),
//       );
//       await _schedulePrayer(
//         "isha",
//         _ishaId,
//         _channelB,
//         prayerTimes.ishaTime,
//         preferences.getKIshaEnabled(),
//       );
//       await _schedulePrayer(
//         "azkarSobh",
//         _azkarSobh,
//         _channelC,
//         preferences.getKAzkarSobhTime(),
//         preferences.getKIsAzkarSophActive(),
//       );
//       await _schedulePrayer(
//         "azkarMassa",
//         _azkarMassa,
//         _channelC,
//         preferences.getKKAzkarMassaTime(),
//         preferences.getKIsAzkarMassaActive(),
//       );
//
//       // debugPrint("[NOTIFICATIONS] All notifications scheduled successfully");
//     } catch (e) {
//       // debugPrint("[ERROR] Scheduling failed: $e");
//     }
//   }
//
//   static Future<void> _schedulePrayer(
//     String prayerName,
//     int id,
//     String channelKey,
//     String timeStr,
//     bool isEnabled,
//   ) async {
//     if (!isEnabled) {
//       // debugPrint("[DEBUG] $prayerName notifications are disabled");
//       return;
//     }
//
//     try {
//       final now = DateTime.now().toLocal();
//       final parsedTime = DateFormat('HH:mm').parse(timeStr.split(' ')[0]);
//       var scheduledTime = DateTime(
//         now.year,
//         now.month,
//         now.day,
//         parsedTime.hour,
//         parsedTime.minute,
//       );
//
//       // debugPrint(
//       //   "[DEBUG] Parsing time: $timeStr → ${parsedTime.hour}:${parsedTime.minute}",
//       // );
//
//       if (scheduledTime.isBefore(now)) {
//         scheduledTime = scheduledTime.add(const Duration(days: 1));
//         // debugPrint("[DEBUG] Adjusted $scheduledTime to next day");
//       }
//
//       await AwesomeNotifications().createNotification(
//         content: NotificationContent(
//           id: id,
//           channelKey: channelKey,
//           title: 'موعد ${_prayerArabicNames[prayerName] ?? prayerName}',
//           body: (prayerName == 'azkarSobh' || prayerName == 'azkarMassa')
//               ? 'حان الآن موعد ${_prayerArabicNames[prayerName]}'
//               : 'حان الآن موعد ${_prayerArabicNames[prayerName]} في ${preferences.getKLocationName()}',
//           payload: {'prayer': prayerName},
//           notificationLayout: NotificationLayout.Default,
//         ),
//         schedule: NotificationCalendar(
//           year: scheduledTime.year,
//           month: scheduledTime.month,
//           day: scheduledTime.day,
//           hour: scheduledTime.hour,
//           minute: scheduledTime.minute,
//           allowWhileIdle: true,
//           preciseAlarm: true,
//           timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
//         ),
//       );
//       // debugPrint(
//       //   "[SCHEDULED] $prayerName at ${DateFormat('HH:mm').format(scheduledTime)}",
//       // );
//     } catch (e) {
//       // debugPrint("[ERROR] Failed to schedule $prayerName: $e");
//     }
//   }
//
//   static Future<void> cancelAllSchedules() async {
//     try {
//       await AwesomeNotifications().cancelAllSchedules();
//       // debugPrint("[NOTIFICATIONS] All previous schedules canceled");
//     } catch (e) {
//       // debugPrint("[ERROR] Failed to cancel schedules: $e");
//     }
//   }
//
//   // Listener methods (keep your existing implementations)
//   static Future<void> onNotificationDisplayedMethod(
//     ReceivedNotification notification,
//   ) async {}
//   static Future<void> onActionReceivedMethod(ReceivedAction action) async {}
//   static Future<void> onNotificationCreatedMethod(
//     ReceivedNotification notification,
//   ) async {}
//   static Future<void> onDismissActionReceivedMethod(
//     ReceivedAction action,
//   ) async {}
// }
//
// @pragma('vm:entry-point')
// void startCallback() {
//   FlutterForegroundTask.setTaskHandler(RescheduleHandler());
// }
//
// class RescheduleHandler extends TaskHandler {
//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
//     // debugPrint("[FOREGROUND] Service started");
//     try {
//       await NotificationService.initializeHive();
//       await NotificationService.scheduleAllNotifications();
//     } catch (e) {
//       // debugPrint("[FOREGROUND ERROR] $e");
//     }
//   }
//
//   @override
//   void onRepeatEvent(DateTime timestamp) {}
//   @override
//   Future<void> onDestroy(DateTime timestamp, bool isUnexpected) async {}
//   @override
//   void onNotificationButtonPressed(String id) {}
//   @override
//   void onNotificationPressed() {}
// }
