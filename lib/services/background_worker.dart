import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'package:finance/services/local_push_service.dart';
import 'package:finance/services/notification_scheduler.dart';

/// نام تسک‌های پس‌زمینه
const String taskCheckBudget = 'check_budget';
const String taskDailyReminder = 'daily_reminder';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    await LocalPushService.instance.init();

    switch (task) {
      case taskCheckBudget:
        await NotificationScheduler.instance.checkBudgetAlert();
        break;
      case taskDailyReminder:
        await NotificationScheduler.instance.fireDailyReminder();
        break;
    }

    return true;
  });
}
