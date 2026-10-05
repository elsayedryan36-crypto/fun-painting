// import 'dart:developer';
//
// import 'package:noor_qloop/core/local_notification_service.dart';
// import 'package:workmanager/workmanager.dart';
//
// class WorkManagerService {
//   Future<void> registerMyTask() async {
//     await Workmanager().registerPeriodicTask(
//       'id1',
//       'show_simple_notification',
//       frequency: const Duration(minutes: 15),
//       constraints: Constraints(
//         networkType: NetworkType.connected,
//       ),
//     );
//   }
//
//   Future<void> init() async {
//     await Workmanager().initialize(
//       callbackDispatcher,
//       isInDebugMode: true,
//     );
//     await registerMyTask();
//   }
//
//   Future<void> cancelTask(String id) async {
//     await Workmanager().cancelByUniqueName(id);
//     // OR if you want to cancel all:
//     // await Workmanager().cancelAll();
//   }
// }
//
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((taskName, inputData) async {
//     if (taskName == 'show_simple_notification') {
//       await LocalNotificationService.showDailyScheduledNotification();
//     }
//     return Future.value(true);
//   });
// }
// //1.schedule notification at 9 pm.
// //2.execute for this notification.
