class NLPConstants {
  // Supported query categories
  static const List<String> conflictKeywords = [
    'conflict',
    'issue',
    'problem',
    'double booking',
    'overlap',
  ];

  static const List<String> overloadKeywords = [
    'overload',
    'load',
    'units',
    'teaching hours',
    'too much',
  ];

  static const List<String> scheduleKeywords = [
    'schedule',
    'timetable',
    'class',
    'my schedule',
    'my timetable',
  ];

  static const List<String> availabilityKeywords = [
    'available',
    'free',
    'room',
    'lab',
    'lecture hall',
    'can i book',
  ];

  static const List<String> sectionKeywords = [
    'section',
    'batch',
    'group',
    'class',
  ];

  // Error messages
  static const String unsupportedQueryMessage =
      'This query is not supported by the system.';

  static const String restrictedAccessMessage =
      'This information is restricted to administrators.';

  static const String unauthorizedMessage =
      'You are not authorized to perform this action.';

  static const String emptyQueryMessage = 'Please enter a query to proceed.';

  static const String defaultHelpMessage =
      "Hello! I'm your CITESched Assistant. I can help you with:\n\n"
      "• Check schedule conflicts\n"
      "• Monitor faculty workload\n"
      "• View room availability\n"
      "• Find section schedules\n\n"
      "Try asking 'Show conflicts' or 'Is Room 301 available?'";
}
