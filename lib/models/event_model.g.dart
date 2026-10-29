// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      location: json['location'] as String,
      organizer: json['organizer'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 0,
      registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'location': instance.location,
      'organizer': instance.organizer,
      'type': instance.type,
      'status': instance.status,
      'max_participants': instance.maxParticipants,
      'registered_count': instance.registeredCount,
      'budget': instance.budget,
      'notes': instance.notes,
    };

EventRegistration _$EventRegistrationFromJson(Map<String, dynamic> json) =>
    EventRegistration(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      participantId: json['participant_id'] as String,
      participantType: json['participant_type'] as String,
      registrationDate: DateTime.parse(json['registration_date'] as String),
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$EventRegistrationToJson(EventRegistration instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'participant_id': instance.participantId,
      'participant_type': instance.participantType,
      'registration_date': instance.registrationDate.toIso8601String(),
      'status': instance.status,
      'notes': instance.notes,
    };
