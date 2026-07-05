import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SchoolKnowledgeService {
  static final SchoolKnowledgeService _instance =
      SchoolKnowledgeService._internal();
  factory SchoolKnowledgeService() => _instance;
  SchoolKnowledgeService._internal();

  Map<String, dynamic>? _schoolData;
  Map<String, dynamic>? _examData;
  String? _aboutData;
  String? _appVersion;
  String? _aboutAppData;
  String? _formattedContext;

  /// Loads school_data.json, about.txt, and examination.json.
  Future<void> loadData() async {
    if (_schoolData != null && _examData != null) return;
    try {
      // Load School Data
      final String schoolResponse = await rootBundle.loadString(
        'assets/school data/school_data.json',
      );
      _schoolData = json.decode(schoolResponse);

      // Load Examination Data
      final String examResponse = await rootBundle.loadString(
        'assets/school data/examination.json',
      );
      _examData = json.decode(examResponse);

      // Load About Data
      try {
        _aboutData = await rootBundle.loadString(
          'assets/school data/about.txt',
        );
      } catch (e) {
        debugPrint("⚠️ SchoolKnowledgeService: about.txt not found, skipping.");
        _aboutData = "";
      }

      // Load About App Data
      try {
        _aboutAppData = await rootBundle.loadString(
          'assets/school data/about_app.txt',
        );
      } catch (e) {
        debugPrint(
          "⚠️ SchoolKnowledgeService: about_app.txt not found, skipping.",
        );
        _aboutAppData = "";
      }

      // Load App Version
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        _appVersion = packageInfo.version;
      } catch (e) {
        debugPrint("⚠️ SchoolKnowledgeService: Could not load app version: $e");
        _appVersion = "Unknown";
      }

      _formattedContext = _generateContextString();
      debugPrint(
        "✅ SchoolKnowledgeService: All data loaded and context prepared.",
      );
    } catch (e) {
      debugPrint("❌ SchoolKnowledgeService: Failed to load data: $e");
      _formattedContext = "Error: School data could not be loaded.";
    }
  }

  String get context => _formattedContext ?? "";
  Map<String, dynamic>? get schoolData => _schoolData;
  Map<String, dynamic>? get examData => _examData;

  /// Returns the complete data as a single JSON-encodable map.
  Map<String, dynamic> getFullDataAsJson() {
    return {
      "school_data": _schoolData ?? {},
      "examination_data": _examData ?? {},
      "about_text": _aboutData ?? "",
      "app_version": _appVersion ?? "Unknown",
      "about_app_text": _aboutAppData ?? "",
    };
  }

  // --- Local Fallback & Reasoning ---

  /// Main entry point for local fallback.
  /// Returns a string response based on the query.
  String searchLocal(String query) {
    final lowerQuery = query.toLowerCase().trim();

    // 1. Basic Conversational & Identity
    if (lowerQuery.contains("who trained you") ||
        lowerQuery.contains("created you")) {
      return "I was trained by Ibrahim Adamu.";
    }
    if (lowerQuery == "who are you" || lowerQuery.contains("your name")) {
      return "I am the AI assistant for Abdulkadir Kure University.";
    }
    if (lowerQuery.contains("thank you") || lowerQuery.contains("thanks")) {
      return "You're welcome! Let me know if you need anything else.";
    }
    if (lowerQuery.contains("bye") || lowerQuery.contains("goodbye")) {
      return "Goodbye! Have a great day.";
    }

    // 2. CGPA Calculation
    if (lowerQuery.contains("calculate cgpa") ||
        lowerQuery.contains("calculate my cgpa")) {
      return "To calculate your CGPA, please provide your grades and credit units. "
          "The formula is: Total Quality Points (Grade Point × Units) / Total Credit Units.\n\n"
          "For example: If you have an A (5.0) in a 3-unit course, that's 15 points. "
          "Do this for all courses and divide the sum by total units.";
    }

    // 3. Degree Classification
    if (lowerQuery.contains("first class") ||
        lowerQuery.contains("second class") ||
        lowerQuery.contains("third class") ||
        lowerQuery.contains("degree class")) {
      return _getDegreeClassificationInfo();
    }

    // 4. Keyword / Fuzzy Search in Data
    // We search school_data, then examination_data, then about_data.

    final schoolResult = _searchJsonMap(_schoolData, lowerQuery);
    if (schoolResult != null) return schoolResult;

    final examResult = _searchJsonMap(_examData, lowerQuery);
    if (examResult != null) return examResult;

    if (_aboutData != null && _aboutData!.toLowerCase().contains(lowerQuery)) {
      if (_aboutData!.length < 500) {
        return _aboutData!;
      }
      return "I found information related to your query in the school's About section: \n\n$_aboutData";
    }

    // 5. No Match
    return "You have used your AI quota. I can currently only answer questions related to the school, and your question does not match information in the school database.";
  }

  String _getDegreeClassificationInfo() {
    if (_examData != null &&
        _examData!.containsKey('grade_point_computation_nigeria')) {
      final classes =
          _examData!['grade_point_computation_nigeria']['degree_classifications'];
      if (classes is List) {
        StringBuffer sb = StringBuffer();
        sb.writeln("Degree Classifications:");
        for (var item in classes) {
          sb.writeln("- ${item['classification']}: ${item['cgpa_range']}");
        }
        return sb.toString();
      }
    }
    // Fallback if json not structured as expected
    return "First Class: 4.50 - 5.00\nSecond Class Upper: 3.50 - 4.49\nSecond Class Lower: 2.40 - 3.49\nThird Class: 1.50 - 2.39\nPass: 1.00 - 1.49\nFail: Below 1.00";
  }

  String? _searchJsonMap(Map<String, dynamic>? data, String query) {
    if (data == null) return null;

    // Example: "faculties"
    if (query.contains("faculty") || query.contains("faculties")) {
      return _extractFaculties();
    }

    if (query.contains("exam") || query.contains("examination")) {
      if (_examData != null &&
          _examData!.containsKey('examination_guide_nigerian_universities')) {
        return "I have found extensive guidelines on examinations. "
            "They cover preparation, registration, conduct, and misconduct. "
            "Please be more specific, for example: 'exam rules', 'exam preparation', or 'exam types'.";
      }
    }

    if (query.contains("misconduct") || query.contains("malpractice")) {
      return "Examination malpractice includes bringing unauthorized materials, cheating, or impersonation. "
          "Penalties range from warning letters to expulsion depending on the severity.";
    }

    return null;
  }

  String _extractFaculties() {
    if (_schoolData != null &&
        _schoolData!['academic_structure'] != null &&
        _schoolData!['academic_structure']['faculties'] != null) {
      StringBuffer sb = StringBuffer();
      sb.writeln("Faculties at the university:");
      for (var fac in _schoolData!['academic_structure']['faculties']) {
        sb.writeln("- ${fac['faculty_name']}");
      }
      return sb.toString();
    }
    return "Information about faculties is not available.";
  }

  String _generateContextString() {
    StringBuffer sb = StringBuffer();

    // 1. School Data Summary
    if (_schoolData != null) {
      final data = _schoolData!;
      sb.writeln("SCHOOL: ${data['school'] ?? 'Abdulkadir Kure University'}");
      sb.writeln("LOCATION: ${data['location']}");
      if (data['management'] != null) {
        sb.writeln("VC/MANAGEMENT:");
        final Map<String, dynamic> mgmt = data['management'];
        mgmt.forEach((role, name) {
          sb.writeln("- $role: $name");
        });
      }
      if (data['academic_structure'] != null &&
          data['academic_structure']['faculties'] != null) {
        sb.write("FACULTIES: ");
        for (var fac in data['academic_structure']['faculties']) {
          sb.write("${fac['faculty_name']}, ");
        }
        sb.writeln("");
      }
    }

    // 2. Examination Summary
    if (_examData != null) {
      sb.writeln(
        "\nEXAM RULES AVAILABLE: Attendance, Conduct, Grading System, Malpractice Penalties.",
      );
    }

    // 3. About Text
    if (_aboutData != null && _aboutData!.isNotEmpty) {
      sb.writeln("\nABOUT SCHOOL:\n$_aboutData");
    }

    // 4. About App
    if (_aboutAppData != null && _aboutAppData!.isNotEmpty) {
      sb.writeln("\nABOUT APP:\n$_aboutAppData");
    }

    return sb.toString();
  }
}
