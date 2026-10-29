class Schedule {
  final String id;
  final String classId;
  final String teacherId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String room;
  final DateTime createdAt;

  Schedule({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'classId': classId,
    'teacherId': teacherId,
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'room': room,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id: json['id'] as String,
    classId: json['classId'] as String,
    teacherId: json['teacherId'] as String,
    dayOfWeek: json['dayOfWeek'] as String,
    startTime: json['startTime'] as String,
    endTime: json['endTime'] as String,
    room: json['room'] as String,
    createdAt: DateTime.parse(json['createdAt']),
  );
}
