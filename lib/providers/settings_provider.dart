import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  bool _notificationReminders = true;
  bool _emailUpdates = true;

  bool get notificationReminders => _notificationReminders;
  bool get emailUpdates => _emailUpdates;

  void toggleNotificationReminders() {
    _notificationReminders = !_notificationReminders;
    notifyListeners();
  }

  void toggleEmailUpdates() {
    _emailUpdates = !_emailUpdates;
    notifyListeners();
  }
}
