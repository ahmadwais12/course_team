import 'package:json_annotation/json_annotation.dart';

part 'event_model.g.dart';

@JsonSerializable()
class Event {
  final String id;
  final String title;
  final String description;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  final String location;
  final String organizer;
  final String type;
  final String status;
  @JsonKey(name: 'max_participants')
  final int maxParticipants;
  @JsonKey(name: 'registered_count')
  final int registeredCount;
  final double budget;
  final String? notes;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.organizer,
    required this.type,
    required this.status,
    this.maxParticipants = 0,
    this.registeredCount = 0,
    this.budget = 0.0,
    this.notes,
  });

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  Map<String, dynamic> toJson() => _$EventToJson(this);
}

@JsonSerializable()
class EventRegistration {
  final String id;
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'participant_id')
  final String participantId;
  @JsonKey(name: 'participant_type')
  final String participantType;
  @JsonKey(name: 'registration_date')
  final DateTime registrationDate;
  final String status;
  final String? notes;

  EventRegistration({
    required this.id,
    required this.eventId,
    required this.participantId,
    required this.participantType,
    required this.registrationDate,
    required this.status,
    this.notes,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> json) =>
      _$EventRegistrationFromJson(json);
  Map<String, dynamic> toJson() => _$EventRegistrationToJson(this);
}
