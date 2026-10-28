import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class ScheduleWindow {
  final DateTime start;
  final DateTime end;

  const ScheduleWindow({required this.start, required this.end});

  String get startIso => start.toUtc().toIso8601String();
  String get endIso => end.toUtc().toIso8601String();
}

class ScheduleTime {
  ScheduleTime._();

  static const String timeZoneName = 'Asia/Beirut';
  static bool _initialized = false;

  static timezone.Location get _location {
    if (!_initialized) {
      timezone_data.initializeTimeZones();
      _initialized = true;
    }
    return timezone.getLocation(timeZoneName);
  }

  static timezone.TZDateTime local(DateTime instant) =>
      timezone.TZDateTime.from(instant.toUtc(), _location);

  static DateTime get businessNow => local(DateTime.now());

  static DateTime parseInstant(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static ScheduleWindow fromLocal({
    required DateTime date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) {
    final overnight = endHour * 60 + endMinute < startHour * 60 + startMinute;
    if (endHour * 60 + endMinute == startHour * 60 + startMinute) {
      throw const FormatException(
          'Delivery window end must be after its start.');
    }
    final endDate =
        DateTime.utc(date.year, date.month, date.day + (overnight ? 1 : 0));
    final start =
        _wallTimeToUtc(date.year, date.month, date.day, startHour, startMinute);
    final end = _wallTimeToUtc(
        endDate.year, endDate.month, endDate.day, endHour, endMinute);
    if (!end.isAfter(start)) {
      throw const FormatException(
          'Delivery window end must be after its start.');
    }
    return ScheduleWindow(start: start, end: end);
  }

  static DateTime _wallTimeToUtc(
      int year, int month, int day, int hour, int minute) {
    final requested = DateTime.utc(year, month, day, hour, minute);
    if (requested.year != year ||
        requested.month != month ||
        requested.day != day ||
        requested.hour != hour ||
        requested.minute != minute) {
      throw const FormatException('Choose a valid date and time.');
    }
    final pseudoUtc = requested.millisecondsSinceEpoch;
    final offsets = <int>{};
    for (var shift = -36; shift <= 36; shift += 3) {
      offsets.add(_location
          .timeZone(pseudoUtc + shift * 60 * 60 * 1000)
          .offset
          .inMilliseconds);
    }
    final candidates = offsets
        .map((offset) => DateTime.fromMillisecondsSinceEpoch(pseudoUtc - offset,
            isUtc: true))
        .where((candidate) {
      final localValue = timezone.TZDateTime.from(candidate, _location);
      return localValue.year == year &&
          localValue.month == month &&
          localValue.day == day &&
          localValue.hour == hour &&
          localValue.minute == minute;
    }).toList()
      ..sort((a, b) => a.compareTo(b));
    if (candidates.isEmpty) {
      throw const FormatException(
          'That local time does not exist because of a daylight-saving clock change.');
    }
    // On a repeated wall-clock minute choose the earliest real instant.
    return candidates.first;
  }

  static String formatWindow(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'No scheduled delivery';
    final localStart = local(start);
    final localEnd = local(end);
    final startDate = DateFormat('EEEE, d MMMM yyyy').format(localStart);
    final endDate = DateFormat('EEEE, d MMMM yyyy').format(localEnd);
    final startTime = DateFormat('h:mm a').format(localStart);
    final endTime = DateFormat('h:mm a').format(localEnd);
    return startDate == endDate
        ? '$startDate · $startTime–$endTime'
        : '$startDate $startTime – $endDate $endTime';
  }

  static String formatCompactWindow(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'No scheduled delivery';
    final localStart = local(start);
    final localEnd = local(end);
    final date = DateFormat('MMM d').format(localStart);
    final startTime = DateFormat('h:mm a').format(localStart);
    final endTime = DateFormat('h:mm a').format(localEnd);
    if (localStart.year == localEnd.year &&
        localStart.month == localEnd.month &&
        localStart.day == localEnd.day) {
      return '$date · $startTime–$endTime';
    }
    return '$date $startTime – ${DateFormat('MMM d').format(localEnd)} $endTime';
  }

  static String stateLabel(String? state) => switch (state) {
        'UNSCHEDULED' => 'Unscheduled',
        'UPCOMING' => 'Upcoming',
        'DUE_SOON' => 'Due soon',
        'IN_WINDOW' => 'In delivery window',
        'OVERDUE' => 'Overdue',
        'COMPLETED' => 'Completed',
        'CANCELLED' => 'Cancelled',
        _ => 'Scheduled',
      };
}
