import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String formatDateTime({required String formate}) =>
      DateFormat(formate).format(this);
}
