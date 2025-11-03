class TimeSlotModel {
  final String startTime;
  final String endTime;
  final int totalDays;
  final int totalHours;
  final DateTime selectedDate;

  TimeSlotModel({
    required this.startTime,
    required this.endTime,
    required this.totalDays,
    required this.totalHours,
    required this.selectedDate,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      totalDays: json['total_days'] as int,
      totalHours: json['total_hours'] as int,
      selectedDate: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime,
      'end_time': endTime,
      'total_days': totalDays,
      'total_hours': totalHours,
      'date': selectedDate.toIso8601String(),
    };
  }

  TimeSlotModel copyWith({
    String? startTime,
    String? endTime,
    int? totalDays,
    int? totalHours,
    DateTime? selectedDate,
  }) {
    return TimeSlotModel(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDays: totalDays ?? this.totalDays,
      totalHours: totalHours ?? this.totalHours,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}
