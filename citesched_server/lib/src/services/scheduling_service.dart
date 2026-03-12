import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'conflict_service.dart';

/// Service class for handling scheduling logic.
/// Uses [ConflictService] to validate schedule entries and generates schedules.
/// Respects faculty availability preferences from the FacultyAvailability table.
class SchedulingService {
  final ConflictService _conflictService = ConflictService();
  static const Set<String> _labRoomNames = {'IT LAB', 'EMC LAB'};
  static const String _lectureRoomName = 'ROOM 1';
  static const double _lectureHours = 2.0;
  static const double _labHours = 3.0;
  static const int _labEarliestStartMinutes = 9 * 60;

  /// Generate schedules using a greedy algorithm.
  /// Attempts to assign each subject to available timeslots while respecting
  /// all constraints including faculty day/time availability.
  Future<GenerateScheduleResponse> generateSchedule(
    Session session,
    GenerateScheduleRequest request,
  ) async {
    final generatedSchedules = <Schedule>[];
    final conflicts = <ScheduleConflict>[];

    if (request.subjectIds.isEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message: 'No subjects provided for schedule generation',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: 0,
      );
    }

    if (request.facultyIds.isEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message: 'No faculty provided for schedule generation',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: request.subjectIds.length,
      );
    }

    if (request.sections.isEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message: 'No sections provided for schedule generation',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: 0,
      );
    }

    final subjects = await Future.wait(
      request.subjectIds.map((id) => Subject.db.findById(session, id)),
    );
    final faculties = await Future.wait(
      request.facultyIds.map((id) => Faculty.db.findById(session, id)),
    );
    final rooms = await Future.wait(
      request.roomIds.map((id) => Room.db.findById(session, id)),
    );
    final timeslots = await Future.wait(
      request.timeslotIds.map((id) => Timeslot.db.findById(session, id)),
    );
    final existingSchedules = await Schedule.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );

    final validSubjects = subjects
        .whereType<Subject>()
        .where((s) => s.isActive)
        .toList();
    final validFaculties = faculties
        .whereType<Faculty>()
        .where((f) => f.isActive)
        .toList();
    final validRooms = rooms.whereType<Room>().where((r) => r.isActive).toList();
    final validTimeslots = timeslots.whereType<Timeslot>().toList();
    final timeslotCache = <String, Timeslot>{
      for (final t in validTimeslots) _timeslotKey(t.day, t.startTime, t.endTime): t,
    };

    final requestedSections = request.sections
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final candidateSections = await _buildSectionCandidates(
      session: session,
      requestedSections: requestedSections,
    );

    final facultyAvailMap = <int, List<FacultyAvailability>>{};
    for (final faculty in validFaculties) {
      final avails = await FacultyAvailability.db.find(
        session,
        where: (t) => t.facultyId.equals(faculty.id!),
      );
      facultyAvailMap[faculty.id!] = avails;
    }

    final facultyAssignments = <int, double>{};
    final facultyTimeslotUsage = <int, Map<int, int>>{};
    for (final faculty in validFaculties) {
      facultyAssignments[faculty.id!] = 0;
      facultyTimeslotUsage[faculty.id!] = {};
    }

    for (final existing in existingSchedules) {
      final current = facultyAssignments[existing.facultyId];
      if (current == null) continue;
      facultyAssignments[existing.facultyId] = current + (existing.units ?? 0);
      if (existing.timeslotId != null) {
        final usage = facultyTimeslotUsage[existing.facultyId]!;
        usage[existing.timeslotId!] = (usage[existing.timeslotId!] ?? 0) + 1;
      }
    }

    final assignedSubjectSectionKeys = <String>{
      for (final s in existingSchedules)
        _componentKey(
          s.subjectId,
          s.sectionId,
          s.section,
          _componentTagFromLoadTypes(s.loadTypes),
        ),
    };

    for (final subject in validSubjects) {
      final matchingSections = candidateSections.where((section) {
        if (section.program != subject.program) return false;
        if (subject.yearLevel != null && section.yearLevel != subject.yearLevel) {
          return false;
        }
        return true;
      }).toList();

      if (matchingSections.isEmpty) {
        conflicts.add(
          ScheduleConflict(
            type: 'generation_failed',
            message:
                'No matching section found for ${subject.name} (${subject.code})',
            details:
                'Subject program/year does not match any available active section.',
          ),
        );
        continue;
      }

      for (final section in matchingSections) {
        final components = _componentsForSubject(subject);
        double maxComponentHours = 0;
        for (final component in components) {
          if (component.hours > maxComponentHours) {
            maxComponentHours = component.hours;
          }
        }
        final insertedForPair = <Schedule>[];
        var allAssigned = true;

        _LoadComponent? lectureComponent;
        _LoadComponent? labComponent;
        for (final component in components) {
          if (component.tag == 'lecture') {
            lectureComponent = component;
          } else if (component.tag == 'laboratory') {
            labComponent = component;
          }
        }

        if (lectureComponent != null && labComponent != null) {
          final assigned = await _assignBlendedPair(
            session: session,
            subject: subject,
            section: section,
            lectureComponent: lectureComponent,
            labComponent: labComponent,
            validFaculties: validFaculties,
            validRooms: validRooms,
            validTimeslots: validTimeslots,
            facultyAvailMap: facultyAvailMap,
            facultyAssignments: facultyAssignments,
            facultyTimeslotUsage: facultyTimeslotUsage,
            timeslotCache: timeslotCache,
            assignedSubjectSectionKeys: assignedSubjectSectionKeys,
            generatedSchedules: generatedSchedules,
            insertedForPair: insertedForPair,
          );

          if (!assigned) {
            allAssigned = false;
          }
        } else {
          for (final component in components) {
            final pairKey = _componentKey(
              subject.id!,
              section.id,
              section.sectionCode,
              component.tag,
            );
            if (assignedSubjectSectionKeys.contains(pairKey)) {
              continue;
            }

            var assigned = false;
            final requiredHours = component.hours;
            final eligibleRooms = _eligibleRoomsForComponent(
              rooms: validRooms,
              subject: subject,
              componentTypes: component.types,
            );
            if (eligibleRooms.isEmpty) {
              conflicts.add(
                ScheduleConflict(
                  type: 'generation_failed',
                  message:
                      'No eligible room for ${subject.name} (${subject.code})',
                  details: 'No room matches subject type/program constraints.',
                ),
              );
              allAssigned = false;
              break;
            }

            final rankedFaculties = [...validFaculties]..sort((a, b) {
              final aLoad = facultyAssignments[a.id!] ?? 0;
              final bLoad = facultyAssignments[b.id!] ?? 0;
              final aMax = (a.maxLoad ?? 1).toDouble();
              final bMax = (b.maxLoad ?? 1).toDouble();
              final aRatio = aMax <= 0 ? 1.0 : aLoad / aMax;
              final bRatio = bMax <= 0 ? 1.0 : bLoad / bMax;
              return aRatio.compareTo(bRatio);
            });

            for (final faculty in rankedFaculties) {
              if (assigned) break;

              // If a subject is explicitly assigned to an instructor, enforce it.
              if (subject.facultyId != null && faculty.id != subject.facultyId) {
                continue;
              }

              if (!_canTeachProgram(faculty, subject)) {
                continue;
              }

              final currentLoad = facultyAssignments[faculty.id!] ?? 0;
              final subjectUnits = component.units;
              if ((currentLoad + subjectUnits) > (faculty.maxLoad ?? 0)) continue;

              final candidateTimeslots = await _candidateTimeslotsForFaculty(
                session: session,
                allTimeslots: validTimeslots,
                availability: facultyAvailMap[faculty.id!] ?? const [],
                requiredHours: requiredHours,
                cache: timeslotCache,
                requireLabStartAfterNine:
                    component.types.contains(SubjectType.laboratory),
              );
              final rankedTimeslots = _rankTimeslotsForFaculty(
                timeslots: candidateTimeslots,
                timeslotUsage: facultyTimeslotUsage[faculty.id!] ?? const {},
              );
              if (rankedTimeslots.isEmpty) {
                continue;
              }

              for (final timeslot in rankedTimeslots) {
                if (assigned) break;

                for (final room in eligibleRooms) {
                  if (assigned) break;

                  final candidate = Schedule(
                    subjectId: subject.id!,
                    facultyId: faculty.id!,
                    roomId: room.id!,
                    timeslotId: timeslot.id!,
                    section: section.sectionCode,
                    sectionId: section.id,
                    loadTypes: component.types,
                    units: component.units,
                    hours: component.hours,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  final validationConflicts =
                      await _conflictService.validateSchedule(
                    session,
                    candidate,
                  );

                  if (validationConflicts.isEmpty) {
                    final inserted = await _tryInsertSchedule(
                      session,
                      candidate,
                    );
                    if (inserted == null) {
                      continue;
                    }
                    generatedSchedules.add(inserted);
                    insertedForPair.add(inserted);
                    facultyAssignments[faculty.id!] =
                        (facultyAssignments[faculty.id!] ?? 0) + subjectUnits;
                    final usage = facultyTimeslotUsage[faculty.id!]!;
                    usage[timeslot.id!] = (usage[timeslot.id!] ?? 0) + 1;
                    assignedSubjectSectionKeys.add(pairKey);
                    assigned = true;
                  }
                }
              }
            }

            if (!assigned) {
              allAssigned = false;
              break;
            }
          }
        }

        if (!allAssigned && insertedForPair.isNotEmpty) {
          for (final inserted in insertedForPair) {
            await Schedule.db.deleteRow(session, inserted);
          }
        }

        if (!allAssigned) {
          var details =
              'No valid faculty/room/timeslot combination satisfies all constraints.';

          if (subject.facultyId != null) {
            final lockedFaculty = await Faculty.db.findById(session, subject.facultyId!);
            final lockedName = lockedFaculty?.name ?? 'Faculty ID ${subject.facultyId}';

            if (lockedFaculty == null || !lockedFaculty.isActive) {
              details =
                  'Subject ${subject.code} is locked to $lockedName, but that faculty member is missing or inactive.';
            } else if (!request.facultyIds.contains(lockedFaculty.id)) {
              details =
                  'Subject ${subject.code} is locked to $lockedName, but that faculty member is not included in the selected faculty filter.';
            } else if (lockedFaculty.program != null &&
                lockedFaculty.program != subject.program) {
              details =
                  'Subject ${subject.code} is locked to $lockedName, but program does not match (${lockedFaculty.program} vs ${subject.program}).';
            } else {
              final lockedId = lockedFaculty.id!;
              final lockedCurrentLoad = facultyAssignments[lockedId] ??
                  existingSchedules
                      .where((s) => s.facultyId == lockedId)
                      .fold<double>(0, (sum, s) => sum + (s.units ?? 0));
              final subjectUnits = subject.units.toDouble();

              if ((lockedCurrentLoad + subjectUnits) >
                  (lockedFaculty.maxLoad ?? 0).toDouble()) {
                details =
                    'Subject ${subject.code} is locked to $lockedName, but assigning it would exceed max load (${lockedCurrentLoad.toStringAsFixed(1)} + ${subjectUnits.toStringAsFixed(1)} > ${(lockedFaculty.maxLoad ?? 0).toDouble().toStringAsFixed(1)}).';
              } else {
                final lockedAvailability = facultyAvailMap[lockedId] ??
                    await FacultyAvailability.db.find(
                      session,
                      where: (t) => t.facultyId.equals(lockedId),
                    );
                final lockedUsage = facultyTimeslotUsage[lockedId] ??
                    <int, int>{
                      for (final s in existingSchedules.where(
                        (s) => s.facultyId == lockedId && s.timeslotId != null,
                      ))
                        s.timeslotId!: 1,
                    };
                final lockedCandidates = await _candidateTimeslotsForFaculty(
                  session: session,
                  allTimeslots: validTimeslots,
                  availability: lockedAvailability,
                  requiredHours: maxComponentHours > 0
                      ? maxComponentHours
                      : _requiredHours(subject),
                  cache: timeslotCache,
                );
                final lockedTimeslots = _rankTimeslotsForFaculty(
                  timeslots: lockedCandidates,
                  timeslotUsage: lockedUsage,
                );

                if (lockedTimeslots.isEmpty) {
                  details =
                      'Subject ${subject.code} is locked to $lockedName, but no timeslot fits preferred availability and required hours.';
                } else {
                  details =
                      'Subject ${subject.code} is locked to $lockedName, but no room/timeslot combination is conflict-free for section ${section.sectionCode}.';
                }
              }
            }
          }

          conflicts.add(
            ScheduleConflict(
              type: 'generation_failed',
              message:
                  'Could not assign ${subject.name} (${subject.code}) - Section ${section.sectionCode}',
              details: details,
            ),
          );
        }
      }
    }

    return GenerateScheduleResponse(
      success: conflicts.isEmpty,
      schedules: generatedSchedules,
      conflicts: conflicts.isEmpty ? null : conflicts,
      totalAssigned: generatedSchedules.length,
      conflictsDetected: conflicts.length,
      unassignedSubjects: conflicts.length,
      message: conflicts.isEmpty
          ? 'Successfully generated ${generatedSchedules.length} schedule entries'
          : '${generatedSchedules.length} assigned, ${conflicts.length} unassigned',
    );
  }

  int _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).clamp(0, 23).toString().padLeft(2, '0');
    final m = (minutes % 60).clamp(0, 59).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _timeslotKey(DayOfWeek day, String startTime, String endTime) {
    return '${day.name}|${startTime.trim()}|${endTime.trim()}';
  }

  Future<Timeslot> _getOrCreateTimeslot({
    required Session session,
    required DayOfWeek day,
    required String startTime,
    required String endTime,
    required Map<String, Timeslot> cache,
  }) async {
    final key = _timeslotKey(day, startTime, endTime);
    final existing = cache[key];
    if (existing != null) return existing;

    final label = '${day.name.toUpperCase()} $startTime-$endTime';
    final created = await Timeslot.db.insertRow(
      session,
      Timeslot(
        day: day,
        startTime: startTime,
        endTime: endTime,
        label: label,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    cache[key] = created;
    return created;
  }

  bool _timeslotFitsAvailability(
    Timeslot timeslot,
    FacultyAvailability availability,
  ) {
    if (timeslot.day != availability.dayOfWeek) return false;
    final tsStart = _parseTimeToMinutes(timeslot.startTime);
    final tsEnd = _parseTimeToMinutes(timeslot.endTime);
    final avStart = _parseTimeToMinutes(availability.startTime);
    final avEnd = _parseTimeToMinutes(availability.endTime);
    return tsStart >= avStart && tsEnd <= avEnd;
  }

  bool _timeslotExactAvailabilityMatch(
    Timeslot timeslot,
    FacultyAvailability availability,
  ) {
    if (timeslot.day != availability.dayOfWeek) return false;
    final tsStart = _parseTimeToMinutes(timeslot.startTime);
    final tsEnd = _parseTimeToMinutes(timeslot.endTime);
    final avStart = _parseTimeToMinutes(availability.startTime);
    final avEnd = _parseTimeToMinutes(availability.endTime);
    return tsStart == avStart && tsEnd == avEnd;
  }

  double _requiredHours(Subject subject) {
    final value = subject.hours ?? subject.units.toDouble();
    return value <= 0 ? subject.units.toDouble() : value;
  }

  List<_LoadComponent> _componentsForSubject(Subject subject) {
    final types = subject.types;
    final hasLecture = types.contains(SubjectType.lecture);
    final hasLab = types.contains(SubjectType.laboratory);
    final hasBlended = types.contains(SubjectType.blended);

    if (hasBlended || (hasLecture && hasLab)) {
      final totalHours = _lectureHours + _labHours;
      final totalUnits = subject.units.toDouble();
      final lectureUnits =
          totalUnits * (_lectureHours / totalHours);
      final labUnits = (totalUnits - lectureUnits);
      return [
        _LoadComponent(
          tag: 'lecture',
          types: const [SubjectType.lecture],
          hours: _lectureHours,
          units: lectureUnits,
        ),
        _LoadComponent(
          tag: 'laboratory',
          types: const [SubjectType.laboratory],
          hours: _labHours,
          units: labUnits,
        ),
      ];
    }

    if (hasLab && !hasLecture) {
      return [
        _LoadComponent(
          tag: 'laboratory',
          types: const [SubjectType.laboratory],
          hours: subject.hours ?? _labHours,
          units: subject.units.toDouble(),
        ),
      ];
    }

    return [
      _LoadComponent(
        tag: 'lecture',
        types: const [SubjectType.lecture],
        hours: subject.hours ?? _lectureHours,
        units: subject.units.toDouble(),
      ),
    ];
  }

  double _timeslotHours(Timeslot timeslot) {
    final durationMinutes =
        _parseTimeToMinutes(timeslot.endTime) - _parseTimeToMinutes(timeslot.startTime);
    return durationMinutes / 60.0;
  }

  String _componentKey(
    int subjectId,
    int? sectionId,
    String sectionCode,
    String tag,
  ) {
    final base = sectionId != null
        ? '$subjectId|$sectionId'
        : '$subjectId|${sectionCode.trim().toLowerCase()}';
    return '$base|$tag';
  }

  int _dayRank(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 1;
      case DayOfWeek.tue:
        return 2;
      case DayOfWeek.wed:
        return 3;
      case DayOfWeek.thu:
        return 4;
      case DayOfWeek.fri:
        return 5;
      case DayOfWeek.sat:
        return 6;
      case DayOfWeek.sun:
        return 7;
    }
  }

  List<Timeslot> _rankTimeslotsForFaculty({
    required List<Timeslot> timeslots,
    required Map<int, int> timeslotUsage,
  }) {
    if (timeslots.isEmpty) return const [];

    final candidates = [...timeslots];
    candidates.sort((a, b) {
      final dayCompare = _dayRank(a.day).compareTo(_dayRank(b.day));
      if (dayCompare != 0) return dayCompare;
      final timeCompare = _parseTimeToMinutes(a.startTime)
          .compareTo(_parseTimeToMinutes(b.startTime));
      if (timeCompare != 0) return timeCompare;
      final aUse = timeslotUsage[a.id!] ?? 0;
      final bUse = timeslotUsage[b.id!] ?? 0;
      return aUse.compareTo(bUse);
    });

    return candidates;
  }

  Future<List<Timeslot>> _candidateTimeslotsForFaculty({
    required Session session,
    required List<Timeslot> allTimeslots,
    required List<FacultyAvailability> availability,
    required double requiredHours,
    required Map<String, Timeslot> cache,
    bool requireLabStartAfterNine = false,
  }) async {
    final requiredMinutes = (requiredHours * 60).round();
    if (requiredMinutes <= 0) return const [];

    // If no availability set, fall back to existing timeslots that fit.
    if (availability.isEmpty) {
      return allTimeslots
          .where((t) {
            if (((_timeslotHours(t) * 60).round() - requiredMinutes).abs() > 1) {
              return false;
            }
            if (requireLabStartAfterNine) {
              return _parseTimeToMinutes(t.startTime) >=
                  _labEarliestStartMinutes;
            }
            return true;
          })
          .toList();
    }

    final stepMinutes = requiredMinutes % 60 == 0 ? 60 : 30;
    final candidates = <Timeslot>[];
    final seen = <String>{};

    for (final avail in availability) {
      final start = _parseTimeToMinutes(avail.startTime);
      final end = _parseTimeToMinutes(avail.endTime);
      if (end - start < requiredMinutes) continue;

      for (var s = start; s + requiredMinutes <= end; s += stepMinutes) {
        if (requireLabStartAfterNine && s < _labEarliestStartMinutes) {
          continue;
        }
        final e = s + requiredMinutes;
        final startTime = _formatMinutes(s);
        final endTime = _formatMinutes(e);
        final key = _timeslotKey(avail.dayOfWeek, startTime, endTime);
        if (!seen.add(key)) {
          continue;
        }
        final slot = await _getOrCreateTimeslot(
          session: session,
          day: avail.dayOfWeek,
          startTime: startTime,
          endTime: endTime,
          cache: cache,
        );
        candidates.add(slot);
      }
    }

    return candidates;
  }

  bool _isExclusionViolation(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('exclusion') ||
        message.contains('schedule_instructor_no_overlap') ||
        message.contains('schedule_room_no_overlap') ||
        message.contains('schedule_section_no_overlap');
  }

  Future<Schedule?> _tryInsertSchedule(
    Session session,
    Schedule schedule,
  ) async {
    try {
      final inserted = await Schedule.db.insertRow(session, schedule);
      return inserted;
    } catch (e) {
      if (_isExclusionViolation(e)) {
        return null;
      }
      rethrow;
    }
  }

  List<Room> _eligibleRoomsForSubject({
    required List<Room> rooms,
    required Subject subject,
  }) {
    final requiresLabRoom = subject.types.contains(SubjectType.laboratory) ||
        subject.types.contains(SubjectType.blended);

    return rooms.where((room) {
      final normalized = room.name.trim().toUpperCase();
      if (requiresLabRoom) {
        return _labRoomNames.contains(normalized);
      }
      // Lecture room is always ROOM 1 regardless of program.
      return normalized == _lectureRoomName;
    }).toList();
  }

  List<Room> _eligibleRoomsForComponent({
    required List<Room> rooms,
    required Subject subject,
    required List<SubjectType> componentTypes,
  }) {
    final requiresLab = componentTypes.contains(SubjectType.laboratory);
    return rooms.where((room) {
      final normalized = room.name.trim().toUpperCase();
      if (requiresLab) {
        return _labRoomNames.contains(normalized);
      }
      // Lecture room is always ROOM 1 regardless of program.
      return normalized == _lectureRoomName;
    }).toList();
  }

  bool _canTeachProgram(Faculty faculty, Subject subject) {
    if (faculty.program == null) return true;
    if (faculty.program == subject.program) return true;
    // EMC faculty can teach BSIT subjects, but IT faculty cannot teach EMC.
    if (faculty.program == Program.emc && subject.program == Program.it) {
      return true;
    }
    return false;
  }

  Program _programFromStudentCourse(String? course) {
    final normalized = course?.trim().toUpperCase() ?? '';
    if (normalized == 'BSEMC' || normalized == 'EMC') {
      return Program.emc;
    }
    return Program.it;
  }

  int _yearLevelFromSectionCode(String? sectionCode, {int fallback = 1}) {
    final match = RegExp(r'\\d+').firstMatch(sectionCode ?? '');
    if (match == null) return fallback;
    return int.tryParse(match.group(0)!) ?? fallback;
  }

  Future<List<_SectionCandidate>> _buildSectionCandidates({
    required Session session,
    required Set<String> requestedSections,
  }) async {
    final normalize = (String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final requestedNormalized = requestedSections
        .map((s) => normalize(s))
        .where((s) => s.isNotEmpty)
        .toSet();

    final sectionRows = await Section.db.find(session);
    final candidateByKey = <String, _SectionCandidate>{};

    bool _shouldInclude(String code) {
      if (requestedNormalized.isEmpty) return true;
      return requestedNormalized.contains(normalize(code));
    }

    for (final section in sectionRows) {
      if (!section.isActive) continue;
      if (!_shouldInclude(section.sectionCode)) continue;
      final key =
          '${section.program.name}|${section.yearLevel}|${normalize(section.sectionCode)}';
      candidateByKey[key] = _SectionCandidate(
        id: section.id,
        sectionCode: section.sectionCode.trim(),
        program: section.program,
        yearLevel: section.yearLevel,
      );
    }

    final students = await Student.db.find(
      session,
      where: (t) => t.isActive.equals(true) & t.section.notEquals(null),
    );
    for (final student in students) {
      final code = student.section?.trim();
      if (code == null || code.isEmpty) continue;
      if (!_shouldInclude(code)) continue;
      final program = _programFromStudentCourse(student.course);
      final yearLevel = student.yearLevel > 0
          ? student.yearLevel
          : _yearLevelFromSectionCode(code, fallback: 1);
      final key = '${program.name}|$yearLevel|${normalize(code)}';
      candidateByKey.putIfAbsent(
        key,
        () => _SectionCandidate(
          id: student.sectionId,
          sectionCode: code,
          program: program,
          yearLevel: yearLevel,
        ),
      );
    }

    return candidateByKey.values.toList();
  }

  String _componentTagFromLoadTypes(List<SubjectType>? types) {
    if (types == null || types.isEmpty) return 'lecture';
    final hasLecture = types.contains(SubjectType.lecture);
    final hasLab = types.contains(SubjectType.laboratory);
    if (hasLab && !hasLecture) return 'laboratory';
    if (hasLecture && !hasLab) return 'lecture';
    return 'blended';
  }

  Future<bool> _assignBlendedPair({
    required Session session,
    required Subject subject,
    required _SectionCandidate section,
    required _LoadComponent lectureComponent,
    required _LoadComponent labComponent,
    required List<Faculty> validFaculties,
    required List<Room> validRooms,
    required List<Timeslot> validTimeslots,
    required Map<int, List<FacultyAvailability>> facultyAvailMap,
    required Map<int, double> facultyAssignments,
    required Map<int, Map<int, int>> facultyTimeslotUsage,
    required Map<String, Timeslot> timeslotCache,
    required Set<String> assignedSubjectSectionKeys,
    required List<Schedule> generatedSchedules,
    required List<Schedule> insertedForPair,
  }) async {
    final lectureRooms = _eligibleRoomsForComponent(
      rooms: validRooms,
      subject: subject,
      componentTypes: lectureComponent.types,
    );
    final labRooms = _eligibleRoomsForComponent(
      rooms: validRooms,
      subject: subject,
      componentTypes: labComponent.types,
    );
    if (lectureRooms.isEmpty || labRooms.isEmpty) {
      return false;
    }

    final rankedFaculties = [...validFaculties]..sort((a, b) {
      final aLoad = facultyAssignments[a.id!] ?? 0;
      final bLoad = facultyAssignments[b.id!] ?? 0;
      final aMax = (a.maxLoad ?? 1).toDouble();
      final bMax = (b.maxLoad ?? 1).toDouble();
      final aRatio = aMax <= 0 ? 1.0 : aLoad / aMax;
      final bRatio = bMax <= 0 ? 1.0 : bLoad / bMax;
      return aRatio.compareTo(bRatio);
    });

    final lectureKey = _componentKey(
      subject.id!,
      section.id,
      section.sectionCode,
      lectureComponent.tag,
    );
    final labKey = _componentKey(
      subject.id!,
      section.id,
      section.sectionCode,
      labComponent.tag,
    );
    if (assignedSubjectSectionKeys.contains(lectureKey) &&
        assignedSubjectSectionKeys.contains(labKey)) {
      return true;
    }

    for (final faculty in rankedFaculties) {
      // If a subject is explicitly assigned to an instructor, enforce it.
      if (subject.facultyId != null && faculty.id != subject.facultyId) {
        continue;
      }
      if (!_canTeachProgram(faculty, subject)) {
        continue;
      }

      final currentLoad = facultyAssignments[faculty.id!] ?? 0;
      final totalUnits = lectureComponent.units + labComponent.units;
      if ((currentLoad + totalUnits) > (faculty.maxLoad ?? 0)) continue;

      final availability = facultyAvailMap[faculty.id!] ?? const [];
      final pairTimeslots = await _candidatePairedTimeslotsForFaculty(
        session: session,
        availability: availability,
        lectureHours: lectureComponent.hours,
        labHours: labComponent.hours,
        cache: timeslotCache,
      );
      final rankedPairs = _rankPairedTimeslots(
        pairs: pairTimeslots,
        timeslotUsage: facultyTimeslotUsage[faculty.id!] ?? const {},
      );
      if (rankedPairs.isEmpty) continue;

      for (final pair in rankedPairs) {
        for (final lectureRoom in lectureRooms) {
          for (final labRoom in labRooms) {
            final lectureSchedule = Schedule(
              subjectId: subject.id!,
              facultyId: faculty.id!,
              roomId: lectureRoom.id!,
              timeslotId: pair.lecture.id!,
              section: section.sectionCode,
              sectionId: section.id,
              loadTypes: lectureComponent.types,
              units: lectureComponent.units,
              hours: lectureComponent.hours,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            final labSchedule = Schedule(
              subjectId: subject.id!,
              facultyId: faculty.id!,
              roomId: labRoom.id!,
              timeslotId: pair.laboratory.id!,
              section: section.sectionCode,
              sectionId: section.id,
              loadTypes: labComponent.types,
              units: labComponent.units,
              hours: labComponent.hours,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            final lectureConflicts =
                await _conflictService.validateSchedule(session, lectureSchedule);
            if (lectureConflicts.isNotEmpty) {
              continue;
            }
            final labConflicts =
                await _conflictService.validateSchedule(session, labSchedule);
            if (labConflicts.isNotEmpty) {
              continue;
            }

            final lectureInserted = await _tryInsertSchedule(
              session,
              lectureSchedule,
            );
            if (lectureInserted == null) {
              continue;
            }

            final labInserted = await _tryInsertSchedule(
              session,
              labSchedule,
            );
            if (labInserted == null) {
              await Schedule.db.deleteRow(session, lectureInserted);
              continue;
            }

            generatedSchedules.add(lectureInserted);
            generatedSchedules.add(labInserted);
            insertedForPair.add(lectureInserted);
            insertedForPair.add(labInserted);
            facultyAssignments[faculty.id!] =
                (facultyAssignments[faculty.id!] ?? 0) + totalUnits;
            final usage = facultyTimeslotUsage[faculty.id!]!;
            usage[pair.lecture.id!] = (usage[pair.lecture.id!] ?? 0) + 1;
            usage[pair.laboratory.id!] = (usage[pair.laboratory.id!] ?? 0) + 1;
            assignedSubjectSectionKeys.add(lectureKey);
            assignedSubjectSectionKeys.add(labKey);
            return true;
          }
        }
      }
    }

    return false;
  }

  Future<List<_TimeslotPair>> _candidatePairedTimeslotsForFaculty({
    required Session session,
    required List<FacultyAvailability> availability,
    required double lectureHours,
    required double labHours,
    required Map<String, Timeslot> cache,
  }) async {
    final lectureMinutes = (lectureHours * 60).round();
    final labMinutes = (labHours * 60).round();
    final totalMinutes = lectureMinutes + labMinutes;
    if (totalMinutes <= 0) return const [];

    if (availability.isEmpty) {
      return const [];
    }

    const stepMinutes = 60;
    final pairs = <_TimeslotPair>[];
    final seen = <String>{};

    for (final avail in availability) {
      final start = _parseTimeToMinutes(avail.startTime);
      final end = _parseTimeToMinutes(avail.endTime);
      if (end - start < totalMinutes) continue;

      for (var s = start; s + totalMinutes <= end; s += stepMinutes) {
        // Lecture then lab
        final lectureStart = s;
        final lectureEnd = s + lectureMinutes;
        final labStart = lectureEnd;
        final labEnd = labStart + labMinutes;

        if (labStart >= _labEarliestStartMinutes) {
          final lectureStartTime = _formatMinutes(lectureStart);
          final lectureEndTime = _formatMinutes(lectureEnd);
          final labStartTime = _formatMinutes(labStart);
          final labEndTime = _formatMinutes(labEnd);

          final key =
              '${avail.dayOfWeek.name}|$lectureStartTime-$lectureEndTime|$labStartTime-$labEndTime';
          if (seen.add(key)) {
            final lectureSlot = await _getOrCreateTimeslot(
              session: session,
              day: avail.dayOfWeek,
              startTime: lectureStartTime,
              endTime: lectureEndTime,
              cache: cache,
            );
            final labSlot = await _getOrCreateTimeslot(
              session: session,
              day: avail.dayOfWeek,
              startTime: labStartTime,
              endTime: labEndTime,
              cache: cache,
            );
            pairs.add(_TimeslotPair(lecture: lectureSlot, laboratory: labSlot));
          }
        }

        // Lab then lecture
        final altLabStart = s;
        final altLabEnd = s + labMinutes;
        final altLectureStart = altLabEnd;
        final altLectureEnd = altLectureStart + lectureMinutes;

        if (altLabStart >= _labEarliestStartMinutes) {
          final altLabStartTime = _formatMinutes(altLabStart);
          final altLabEndTime = _formatMinutes(altLabEnd);
          final altLectureStartTime = _formatMinutes(altLectureStart);
          final altLectureEndTime = _formatMinutes(altLectureEnd);

          final altKey =
              '${avail.dayOfWeek.name}|$altLectureStartTime-$altLectureEndTime|$altLabStartTime-$altLabEndTime';
          if (seen.add(altKey)) {
            final lectureSlot = await _getOrCreateTimeslot(
              session: session,
              day: avail.dayOfWeek,
              startTime: altLectureStartTime,
              endTime: altLectureEndTime,
              cache: cache,
            );
            final labSlot = await _getOrCreateTimeslot(
              session: session,
              day: avail.dayOfWeek,
              startTime: altLabStartTime,
              endTime: altLabEndTime,
              cache: cache,
            );
            pairs.add(_TimeslotPair(lecture: lectureSlot, laboratory: labSlot));
          }
        }
      }
    }

    return pairs;
  }

  List<_TimeslotPair> _rankPairedTimeslots({
    required List<_TimeslotPair> pairs,
    required Map<int, int> timeslotUsage,
  }) {
    if (pairs.isEmpty) return const [];
    final candidates = [...pairs];
    candidates.sort((a, b) {
      final dayCompare = _dayRank(a.lecture.day).compareTo(_dayRank(b.lecture.day));
      if (dayCompare != 0) return dayCompare;
      final timeCompare = _parseTimeToMinutes(a.lecture.startTime)
          .compareTo(_parseTimeToMinutes(b.lecture.startTime));
      if (timeCompare != 0) return timeCompare;
      final aUse =
          (timeslotUsage[a.lecture.id!] ?? 0) + (timeslotUsage[a.laboratory.id!] ?? 0);
      final bUse =
          (timeslotUsage[b.lecture.id!] ?? 0) + (timeslotUsage[b.laboratory.id!] ?? 0);
      return aUse.compareTo(bUse);
    });
    return candidates;
  }
}

class _LoadComponent {
  final String tag;
  final List<SubjectType> types;
  final double hours;
  final double units;

  const _LoadComponent({
    required this.tag,
    required this.types,
    required this.hours,
    required this.units,
  });
}

class _TimeslotPair {
  final Timeslot lecture;
  final Timeslot laboratory;

  const _TimeslotPair({required this.lecture, required this.laboratory});
}

class _SectionCandidate {
  final int? id;
  final String sectionCode;
  final Program program;
  final int yearLevel;

  const _SectionCandidate({
    required this.id,
    required this.sectionCode,
    required this.program,
    required this.yearLevel,
  });
}
