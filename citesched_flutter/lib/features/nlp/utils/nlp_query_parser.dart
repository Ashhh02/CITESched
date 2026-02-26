class NLPQueryParser {
  /// Validates that query is not empty
  static bool isValidQuery(String query) {
    return query.trim().isNotEmpty;
  }

  /// Sanitizes user input
  static String sanitizeQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Detects query type from keywords
  static String? detectQueryType(String query) {
    final lowerQuery = query.toLowerCase();

    // Conflict detection
    if (containsKeywords(lowerQuery, [
      'conflict',
      'issue',
      'problem',
      'double booking',
      'overlap',
    ])) {
      return 'conflict';
    }

    // Overload detection
    if (containsKeywords(lowerQuery, [
      'overload',
      'load',
      'units',
      'teaching hours',
      'too much',
    ])) {
      return 'overload';
    }

    // Schedule detection
    if (containsKeywords(lowerQuery, [
      'my schedule',
      'my timetable',
      'my classes',
    ])) {
      return 'my_schedule';
    }

    // Section schedule detection
    if (containsKeywords(lowerQuery, ['schedule', 'timetable', 'class']) ||
        _containsSectionPattern(lowerQuery)) {
      return 'section_schedule';
    }

    // Availability detection
    if (containsKeywords(lowerQuery, [
          'available',
          'free',
          'available',
          'can i use',
        ]) ||
        _isRoomAvailabilityQuery(lowerQuery)) {
      return 'availability';
    }

    return null;
  }

  /// Helper to check if query contains any of the keywords
  static bool containsKeywords(String query, List<String> keywords) {
    return keywords.any((keyword) => query.contains(keyword));
  }

  /// Checks if query follows room availability pattern
  static bool _isRoomAvailabilityQuery(String query) {
    // Patterns like "Room 301", "Lab A", "Lecture Hall 1"
    return RegExp(
      r'(room|lab|lecture hall|classroom)\s+\d+[a-zA-Z]?',
    ).hasMatch(query);
  }

  /// Extracts section from query (e.g., IT 3A, BSIT 2B)
  static bool _containsSectionPattern(String query) {
    // Pattern for section like IT 1A, BSIT 2B, 3-C
    return RegExp(
      r'\b([a-zA-Z]{1,4})?\s?(\d[a-zA-Z])\b',
    ).hasMatch(query.toUpperCase());
  }

  /// Extracts room name/number from query
  static String? extractRoom(String query) {
    final match = RegExp(
      r'(room|lab|lecture hall|classroom)\s+([0-9a-zA-Z]+)',
      caseSensitive: false,
    ).firstMatch(query);
    return match?.group(2);
  }

  /// Extracts faculty name (assumes first name after keywords)
  static String? extractFacultyName(String query) {
    final lowerQuery = query.toLowerCase();
    final keywords = ['professor', 'prof', 'prof.', 'dr.', 'of'];

    for (final keyword in keywords) {
      final index = lowerQuery.indexOf(keyword);
      if (index != -1) {
        final remaining = query.substring(index + keyword.length).trim();
        final parts = remaining.split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          return parts[0];
        }
      }
    }
    return null;
  }

  /// Extracts section pattern (e.g., IT 3A, BSIT 2B)
  static String? extractSection(String query) {
    final match = RegExp(
      r'\b([a-zA-Z]{1,4})?\s?(\d[a-zA-Z])\b',
    ).firstMatch(query);
    return match?.group(0);
  }
}
