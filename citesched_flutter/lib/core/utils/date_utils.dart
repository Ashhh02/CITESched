import 'package:citesched_client/citesched_client.dart';

class CITESchedDateUtils {
  static String getDayName(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 'Monday';
      case DayOfWeek.tue:
        return 'Tuesday';
      case DayOfWeek.wed:
        return 'Wednesday';
      case DayOfWeek.thu:
        return 'Thursday';
      case DayOfWeek.fri:
        return 'Friday';
      case DayOfWeek.sat:
        return 'Saturday';
      case DayOfWeek.sun:
        return 'Sunday';
    }
  }

  static String getDayAbbr(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 'Mon';
      case DayOfWeek.tue:
        return 'Tue';
      case DayOfWeek.wed:
        return 'Wed';
      case DayOfWeek.thu:
        return 'Thu';
      case DayOfWeek.fri:
        return 'Fri';
      case DayOfWeek.sat:
        return 'Sat';
      case DayOfWeek.sun:
        return 'Sun';
    }
  }

  static String formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      var h = hour;
      if (hour > 12) {
        h = hour - 12;
      } else if (hour == 0) {
        h = 12;
      }
      return '$h:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  static String formatTimeslot(
    DayOfWeek day,
    String startTime,
    String endTime,
  ) {
    return '${getDayName(day)} ${formatTime(startTime)} - ${formatTime(endTime)}';
  }
}
