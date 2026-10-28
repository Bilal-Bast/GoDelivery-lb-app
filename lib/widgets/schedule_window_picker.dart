import 'package:flutter/material.dart';

import '../core/time/schedule_time.dart';

class ScheduleWindowPicker extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final bool enabledInitially;
  final bool enabled;
  final ValueChanged<ScheduleWindow?> onChanged;

  const ScheduleWindowPicker({
    super.key,
    this.initialStart,
    this.initialEnd,
    this.enabledInitially = false,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  State<ScheduleWindowPicker> createState() => ScheduleWindowPickerState();
}

class ScheduleWindowPickerState extends State<ScheduleWindowPicker> {
  late bool _enabled;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  String? _error;

  bool get isEnabled => _enabled;
  String? get error => _error;

  ScheduleWindow? get value {
    if (!_enabled || _date == null || _start == null || _end == null) {
      return null;
    }
    try {
      return ScheduleTime.fromLocal(
        date: _date!,
        startHour: _start!.hour,
        startMinute: _start!.minute,
        endHour: _end!.hour,
        endMinute: _end!.minute,
      );
    } on FormatException {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabledInitially &&
        widget.initialStart != null &&
        widget.initialEnd != null;
    if (_enabled) {
      final start = ScheduleTime.local(widget.initialStart!);
      final end = ScheduleTime.local(widget.initialEnd!);
      _date = DateTime(start.year, start.month, start.day);
      _start = TimeOfDay(hour: start.hour, minute: start.minute);
      _end = TimeOfDay(hour: end.hour, minute: end.minute);
    }
  }

  String? validate({bool rejectPast = true}) {
    if (!_enabled) return null;
    if (_date == null || _start == null || _end == null) {
      setState(() => _error = 'Choose a date, start time and end time.');
      return _error;
    }
    try {
      final window = ScheduleTime.fromLocal(
        date: _date!,
        startHour: _start!.hour,
        startMinute: _start!.minute,
        endHour: _end!.hour,
        endMinute: _end!.minute,
      );
      if (rejectPast && !window.end.isAfter(DateTime.now().toUtc())) {
        setState(() => _error = 'Choose a delivery window that has not ended.');
        return _error;
      }
      setState(() => _error = null);
      return null;
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return _error;
    }
  }

  void _emit() {
    ScheduleWindow? window;
    if (_enabled && _date != null && _start != null && _end != null) {
      try {
        window = ScheduleTime.fromLocal(
          date: _date!,
          startHour: _start!.hour,
          startMinute: _start!.minute,
          endHour: _end!.hour,
          endMinute: _end!.minute,
        );
        _error = null;
      } on FormatException catch (error) {
        _error = error.message;
      }
    }
    widget.onChanged(window);
  }

  Future<void> _chooseDate() async {
    final now = ScheduleTime.businessNow;
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Choose delivery date · Lebanon time',
    );
    if (selected == null) return;
    setState(() {
      _date = DateTime(selected.year, selected.month, selected.day);
      _error = null;
    });
    _emit();
  }

  Future<void> _chooseTime({required bool start}) async {
    final current = start ? _start : _end;
    final selected = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
      helpText:
          start ? 'Choose delivery window start' : 'Choose delivery window end',
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _start = selected;
      } else {
        _end = selected;
      }
      _error = null;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          key: const Key('schedule_delivery_toggle'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Schedule delivery'),
          subtitle: const Text('Times use Asia/Beirut.'),
          value: _enabled,
          onChanged: widget.enabled
              ? (value) {
                  setState(() {
                    _enabled = value;
                    _error = null;
                    if (value && _date == null) {
                      final now = ScheduleTime.businessNow;
                      _date = DateTime(now.year, now.month, now.day);
                    }
                  });
                  widget.onChanged(this.value);
                }
              : null,
        ),
        if (_enabled) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('schedule_choose_date'),
                onPressed: widget.enabled ? _chooseDate : null,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_date == null
                    ? 'Choose date'
                    : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'),
              ),
              OutlinedButton.icon(
                key: const Key('schedule_choose_start'),
                onPressed:
                    widget.enabled ? () => _chooseTime(start: true) : null,
                icon: const Icon(Icons.schedule_outlined),
                label: Text(_start?.format(context) ?? 'Start time'),
              ),
              OutlinedButton.icon(
                key: const Key('schedule_choose_end'),
                onPressed:
                    widget.enabled ? () => _chooseTime(start: false) : null,
                icon: const Icon(Icons.schedule_outlined),
                label: Text(_end?.format(context) ?? 'End time'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('An earlier end time means the following day.',
              style: theme.textTheme.bodySmall),
          if (value != null) ...[
            const SizedBox(height: 4),
            Text(ScheduleTime.formatWindow(value!.start, value!.end),
                style: theme.textTheme.labelLarge),
          ],
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error)),
          ],
        ],
      ],
    );
  }
}
