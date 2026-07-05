import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LocalSchoolQaService {
  static final LocalSchoolQaService _instance =
      LocalSchoolQaService._internal();
  factory LocalSchoolQaService() => _instance;
  LocalSchoolQaService._internal();

  Map<String, dynamic>? _schoolData;
  Map<String, dynamic>? _examData;
  String? _aboutData;
  String? _aboutAppData;
  String? _appVersion;

  final Map<String, String> _answerCache = {};

  // Confidence threshold
  static const double _threshold = 0.35;

  static const Map<String, List<String>> _synonyms = {
    'vc': ['vice', 'chancellor', 'prof', 'mohammed', 'aliyu', 'paiko'],
    'dvc': ['deputy', 'vice', 'chancellor'],
    'hod': ['head', 'department'],
    'dept': ['department'],
    'prof': ['professor'],
    'csc': ['computer', 'science'],
    'geo': ['geography'],
    'mgt': ['management'],
    'uni': ['university', 'school', 'akum', 'institution'],
    'sch': ['school'],
    'fac': ['faculty'],
    'admin': ['administration'],
    'exam': ['examination'],
    'test': ['continuous', 'assessment', 'ca'],
    'rules': ['regulations', 'conduct', 'misconduct'],
    'gpa': ['cgpa', 'grade', 'point'],
    'loc': ['location', 'where'],
    'dev': ['developer', 'created', 'built', 'trained'],
  };

  /// Returns a formatted string of all school data for AI context
  Future<String> getFullContext() async {
    await loadData();
    StringBuffer sb = StringBuffer();

    sb.writeln("=== ABOUT THE SCHOOL ===");
    if (_aboutData != null) {
      sb.writeln(_aboutData);
    } else {
      sb.writeln("No history available.");
    }
    sb.writeln();

    sb.writeln("=== ACADEMIC STRUCTURE ===");
    if (_schoolData != null && _schoolData!['academic_structure'] != null) {
      final academic = _schoolData!['academic_structure'];
      if (academic['faculties'] != null) {
        for (var fac in academic['faculties']) {
          sb.writeln(
            "FACULTY: ${fac['faculty_name']} (${fac['abbreviation']})",
          );
          if (fac['departments'] != null) {
            for (var dept in fac['departments']) {
              sb.writeln(
                "  - DEPT: ${dept['department_name']} (${dept['abbreviation']})",
              );
              if (dept['programmes'] != null) {
                List<String> progs = [];
                for (var p in dept['programmes']) {
                  progs.add("${p['programme_name']} (${p['degree_type']})");
                }
                sb.writeln("    * COURSES: ${progs.join(', ')}");
              }
            }
          }
        }
      }
    }
    sb.writeln();

    sb.writeln("=== EXAMINATION RULES ===");
    if (_examData != null) {
      // Provide a summary instead of raw dump
      if (_examData!.containsKey('grade_point_computation_nigeria')) {
        final grading = _examData!['grade_point_computation_nigeria'];
        sb.writeln("GRADING SYSTEM: ${grading['grading_system']}");
        if (grading['grading_scale'] != null) {
          sb.writeln("SCALES:");
          for (var scale in grading['grading_scale']) {
            sb.writeln(
              "  ${scale['letter_grade']} = ${scale['percentage_range']} (${scale['classification']})",
            );
          }
        }
      }
    }
    sb.writeln();

    return sb.toString();
  }

  /// Loads all school data assets
  Future<void> loadData() async {
    if (_schoolData != null &&
        _examData != null &&
        _aboutData != null &&
        _aboutAppData != null) {
      return;
    }
    try {
      // 1. School Structure
      final String schoolJson = await rootBundle.loadString(
        'assets/school data/school_data.json',
      );
      _schoolData = json.decode(schoolJson);

      // 2. Examination Data
      final String examJson = await rootBundle.loadString(
        'assets/school data/examination.json',
      );
      _examData = json.decode(examJson);

      // 3. About Text
      _aboutData = await rootBundle.loadString('assets/school data/about.txt');

      // 4. About App Data
      try {
        _aboutAppData = await rootBundle.loadString(
          'assets/school data/about_app.txt',
        );
      } catch (e) {
        debugPrint("⚠️ LocalSchoolQaService: about_app.txt not found.");
        _aboutAppData = "";
      }

      // 5. App Version
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        _appVersion = packageInfo.version;
      } catch (e) {
        debugPrint("Warning: Could not load package info: $e");
        _appVersion = "Unknown";
      }

      debugPrint("✅ LocalSchoolQaService: All school data loaded and cached.");
    } catch (e) {
      debugPrint("❌ LocalSchoolQaService: Failed to load school data: $e");
    }
  }

  /// Tries to answer the question using local data.
  Future<String?> tryAnswer(String question) async {
    await loadData();
    if (_schoolData == null) return null;

    debugPrint("🧠 LocalEngine: Received question: '$question'");
    final normalizedQuestion = _normalize(question);

    // 1. Check for Strict Specific Intents first
    final intentAnswer = _handleSpecificIntents(normalizedQuestion, question);
    if (intentAnswer != null) {
      debugPrint("🎯 LocalEngine: Intent matched via Rule-Based Reasoning.");
      return intentAnswer;
    }

    // 2. Check cache
    if (_answerCache.containsKey(normalizedQuestion)) {
      debugPrint("🎯 LocalEngine: Answer found in cache.");
      return _answerCache[normalizedQuestion];
    }

    // 3. Standard Search across all datasets with Fuzzy Matching
    List<_Match> allMatches = [];
    final queryTerms = _expandQuery(normalizedQuestion);
    debugPrint("🔍 LocalEngine: Query terms: $queryTerms");

    // Search School Data (Faculties, Depts, Management, Buildings)
    allMatches.addAll(_searchSchoolData(queryTerms));

    // Search Exam Data
    allMatches.addAll(_searchExamData(queryTerms));

    // Search About Data
    allMatches.addAll(_searchAboutData(queryTerms));

    // Search About App Data
    allMatches.addAll(_searchAboutAppData(queryTerms));

    if (allMatches.isEmpty) {
      debugPrint("❌ LocalEngine: No matches found.");
      return null;
    }

    // Sort by score descending
    allMatches.sort((a, b) => b.score.compareTo(a.score));

    final bestMatch = allMatches.first;
    debugPrint(" LocalEngine: Best Match Score: ${bestMatch.score}");

    if (bestMatch.score >= _threshold) {
      debugPrint(
        "✅ LocalEngine: High confidence (${bestMatch.score}) -> Answering locally.",
      );
      _answerCache[normalizedQuestion] = bestMatch.answer;
      return bestMatch.answer;
    } else {
      debugPrint(
        "⚠️ LocalEngine: Low confidence (${bestMatch.score} < $_threshold) -> Fallback to AI.",
      );
    }

    return null;
  }

  // --- Specific Intent Handlers ---

  String? _handleSpecificIntents(String normalizedQ, String originalQ) {
    debugPrint("🔍 Analyzing intent for: $originalQ");

    // 1. Who trained you / Who are you?
    if (normalizedQ.contains('trained') ||
        (normalizedQ.contains('who') &&
            (normalizedQ.contains('you') ||
                normalizedQ.contains('created') ||
                normalizedQ.contains('built') ||
                normalizedQ.contains('developer')))) {
      debugPrint("🎯 Intent: Developer Info");
      if (_aboutAppData != null && _aboutAppData!.isNotEmpty) {
        // Try to find the specific section in about_app.txt
        if (_aboutAppData!.toLowerCase().contains("ibrahim")) {
          return _aboutAppData; // Return the whole text or relevant part? The file is small, return all.
        }
      }
      return "I was trained and customized by Ibrahim Adamu, a student of Abdulkadir Kure University. He is in the Faculty of Education, Department of Science Education, Programme: Computer Science Education. He is a professional in website designing and mobile application development.\nEmail: adamuibrahim858@gmail.com\nPhone: 07065106233, 09034410185";
    }

    // 2. Thank You (Politeness)
    if (normalizedQ.contains('thank') ||
        normalizedQ.contains('thx') ||
        normalizedQ == 'thanks') {
      debugPrint("🎯 Intent: Politeness (Thank You)");
      return "You're welcome! I'm here to help with any other school-related questions or academic topics.";
    }

    // 3. Bye Bye (Politeness)
    if (normalizedQ.contains('bye') ||
        normalizedQ.contains('goodbye') ||
        normalizedQ.contains('later')) {
      debugPrint("🎯 Intent: Politeness (Farewell)");
      return "Goodbye! Study hard and have a great day at AKUM.";
    }

    // 4. CGPA Calculation
    if (normalizedQ.contains('calculate') &&
        (normalizedQ.contains('cgpa') || normalizedQ.contains('gpa'))) {
      debugPrint("🎯 Intent: CGPA Calculation");
      return _getCGPAExplanation();
    }

    // 5. Degree Classification
    if (normalizedQ.contains('class') &&
        (normalizedQ.contains('degree') ||
            normalizedQ.contains('first') ||
            normalizedQ.contains('second') ||
            normalizedQ.contains('third'))) {
      debugPrint("🎯 Intent: Degree Classification");
      return _getDegreeClassification();
    }

    // 6. App Version
    if (normalizedQ.contains('version') &&
        (normalizedQ.contains('app') || normalizedQ.contains('application'))) {
      debugPrint("🎯 Intent: App Version");
      return _appVersion != null
          ? "This app is currently running version $_appVersion."
          : "App version information is not available at the moment.";
    }

    // 7. Exam Success Guidance
    if ((normalizedQ.contains('how') || normalizedQ.contains('tips')) &&
        (normalizedQ.contains('pass') || normalizedQ.contains('exam'))) {
      debugPrint("🎯 Intent: Exam Guidance");
      return _getExamGuidance();
    }

    // 8. School History
    if (normalizedQ.contains('history') &&
        (normalizedQ.contains('school') ||
            normalizedQ.contains('biography') ||
            normalizedQ.contains('background'))) {
      debugPrint("🎯 Intent: School History");
      return _getSchoolHistory();
    }

    // 9. About AKUM
    if ((normalizedQ.contains('about') || normalizedQ.contains('what is')) &&
        (normalizedQ.contains('akum') ||
            normalizedQ.contains('school') ||
            normalizedQ.contains('university'))) {
      debugPrint("🎯 Intent: About AKUM");
      return _getAboutSummary();
    }

    // 10. Programme -> Dept -> Faculty Mapping (High precision check)
    // CRITICAL: Ignore "What is [Course]" questions (Definitions).
    // Only map if:
    // - User asks "Where is...", "Department of...", "Faculty of..."
    // - OR if the question DOES NOT start with "what is" (unless asking specifically for location/dept).

    bool looksLikeDefinition =
        normalizedQ.startsWith('what is') ||
        normalizedQ.startsWith('define') ||
        normalizedQ.startsWith('explain');
    bool askingForLocation =
        normalizedQ.contains('department') ||
        normalizedQ.contains('faculty') ||
        normalizedQ.contains('where') ||
        normalizedQ.contains('located');

    if (originalQ.toLowerCase().contains('department') ||
        originalQ.toLowerCase().contains('faculty') ||
        (!looksLikeDefinition || askingForLocation)) {
      // Try to find a programme name in the question
      final mapping = _findProgrammeMapping(originalQ);
      if (mapping != null) {
        debugPrint("🎯 Intent: Programme Mapping");
        return mapping;
      }
    }

    return null;
  }

  String _getCGPAExplanation() {
    if (_examData == null) {
      return "To calculate your CGPA, divide the Total Quality Points by the Total Credit Units.";
    }

    final cgpaData =
        _examData!['grade_point_computation_nigeria']['cgpa_calculation'];
    if (cgpaData != null) {
      StringBuffer sb = StringBuffer();
      sb.writeln("Here is how to calculate your CGPA:");
      sb.writeln();

      final steps = cgpaData['steps'] as List;
      for (var s in steps) {
        sb.writeln(s);
      }

      sb.writeln("\nFormula: ${cgpaData['formula']}");
      return sb.toString();
    }
    return "CGPA = Total Quality Points / Total Credit Units.";
  }

  String _getDegreeClassification() {
    if (_examData == null) {
      return "Degree classifications are usually First Class, Second Class Upper, Second Class Lower, and Third Class.";
    }

    final classes =
        _examData!['grade_point_computation_nigeria']['degree_classifications']
            as List;
    StringBuffer sb = StringBuffer();
    sb.writeln("Degree Classifications:");
    sb.writeln();

    for (var c in classes) {
      sb.writeln("${c['classification']}: ${c['cgpa_range']}");
    }
    return sb.toString();
  }

  String _getExamGuidance() {
    if (_examData == null) {
      return "Study hard, attend lectures, and review past questions.";
    }

    final prep =
        _examData!['examination_guide_nigerian_universities']['pre_examination_preparation']
            as List;
    StringBuffer sb = StringBuffer();
    sb.writeln("Here are some guides for exam success:");
    sb.writeln();

    for (var phase in prep) {
      sb.writeln("• ${phase['period']}:");
      for (var guide in phase['guidelines']) {
        sb.writeln("  - $guide");
      }
    }
    return sb.toString();
  }

  String _getSchoolHistory() {
    if (_aboutData == null) {
      return "Abdulkadir Kure University, Minna was established in 2023.";
    }
    // Return the first few paragraphs which usually contain history
    final paras = _aboutData!.split('\n\n');
    return paras.take(3).join('\n\n');
  }

  String _getAboutSummary() {
    if (_aboutData == null) {
      return "Abdulkadir Kure University, Minna (AKUM) is a state-owned university in Niger State.";
    }
    final paras = _aboutData!.split('\n\n');
    return paras.take(4).join('\n\n');
  }

  String? _findProgrammeMapping(String question) {
    if (_schoolData == null) return null;
    final query = question.toLowerCase();

    final academic =
        _schoolData!['academic_structure'] as Map<String, dynamic>?;
    if (academic != null && academic['faculties'] != null) {
      for (var faculty in academic['faculties']) {
        if (faculty['departments'] != null) {
          for (var dept in faculty['departments']) {
            if (dept['programmes'] != null) {
              for (var prog in dept['programmes']) {
                final pName = (prog['programme_name'] as String).toLowerCase();
                // Check if the programme name appears in the question (ignoring small words if possible, but exact match is safer for strict mapping)
                if (query.contains(pName) ||
                    (pName.contains('education') &&
                        query.contains(
                          pName.replaceAll('education', '').trim(),
                        ))) {
                  // Found a potential match
                  return "${prog['programme_name']} is a programme under the Department of ${dept['department_name']} in the ${faculty['faculty_name']}.";
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  // --- Standard Search & Helpers ---

  String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  List<String> _expandQuery(String query) {
    List<String> words = query.split(' ');
    List<String> expanded = [];
    final stopWords = {
      'what',
      'who',
      'where',
      'when',
      'how',
      'is',
      'are',
      'the',
      'a',
      'an',
      'of',
      'in',
      'at',
      'on',
      'tell',
      'me',
      'about',
      'please',
      'does',
      'do',
    };

    for (var w in words) {
      if (w.length <= 2 && !_synonyms.containsKey(w)) continue;
      if (stopWords.contains(w)) continue;
      expanded.add(w);
      if (_synonyms.containsKey(w)) {
        expanded.addAll(_synonyms[w]!);
      }
    }
    return expanded;
  }

  double _calculateScore(List<String> queryTerms, String content) {
    if (queryTerms.isEmpty) return 0.0;
    final normalizedContent = _normalize(content);
    final contentWords = normalizedContent.split(' ');

    int matches = 0;

    for (var term in queryTerms) {
      bool termMatched = false;

      // 1. Exact Match
      if (normalizedContent.contains(term)) {
        matches++;
        termMatched = true;
      }

      // 2. Fuzzy Match (Levenshtein) if not exact
      if (!termMatched) {
        for (var word in contentWords) {
          if (word.length > 3 && term.length > 3) {
            // Only fuzzy match significant words
            int distance = _levenshtein(term, word);
            // Allow 1 substitution for words 4-5 chars, 2 for longer
            int maxDist = word.length > 5 ? 2 : 1;
            if (distance <= maxDist) {
              matches++;
              termMatched = true;
              break;
            }
          }
        }
      }
    }

    // Score is fraction of terms matched
    double score = (matches / queryTerms.length).clamp(0.0, 1.0);

    return score;
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < t.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((min, elem) => elem < min ? elem : min);
      }

      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }

  List<_Match> _searchSchoolData(List<String> queryTerms) {
    List<_Match> matches = [];

    // Management
    final management = _schoolData!['management'] as Map<String, dynamic>?;
    if (management != null) {
      management.forEach((role, name) {
        double score = _calculateScore(queryTerms, "$role $name");
        if (score > 0) {
          matches.add(
            _Match(score: score + 0.1, answer: "$role: $name"),
          ); // Boost management
        }
      });
    }

    // Faculties & Depts
    final academic =
        _schoolData!['academic_structure'] as Map<String, dynamic>?;
    if (academic != null && academic['faculties'] != null) {
      for (var faculty in academic['faculties']) {
        String fName = faculty['faculty_name'] ?? "";
        String fAbbr = faculty['abbreviation'] ?? "";

        // Faculty Match
        double fScore = _calculateScore(queryTerms, "$fName $fAbbr faculty");
        if (fScore > 0) {
          matches.add(
            _Match(
              score: fScore,
              answer: "The $fName ($fAbbr) is available at AKUM.",
            ),
          );
        }

        if (faculty['departments'] != null) {
          for (var dept in faculty['departments']) {
            String dName = dept['department_name'] ?? "";
            String dAbbr = dept['abbreviation'] ?? "";

            double dScore = _calculateScore(
              queryTerms,
              "department of $dName $dAbbr",
            );
            if (dScore > 0) {
              matches.add(
                _Match(
                  score: dScore,
                  answer:
                      "The Department of $dName ($dAbbr) is under the $fName.",
                ),
              );
            }

            if (dept['programmes'] != null) {
              for (var prog in dept['programmes']) {
                String pName = prog['programme_name'] ?? "";
                double pScore = _calculateScore(
                  queryTerms,
                  "$pName programme course degree",
                );
                if (pScore > 0) {
                  matches.add(
                    _Match(
                      score: pScore,
                      answer:
                          "$pName is a ${prog['duration']}-year ${prog['degree_type']} programme in the Department of $dName.",
                    ),
                  );
                }
              }
            }
          }
        }
      }
    }

    // Definition of Terms
    if (_schoolData!['Definition of Terms'] != null) {
      final defs = _schoolData!['Definition of Terms'] as Map<String, dynamic>;
      defs.forEach((term, def) {
        double dScore = _calculateScore(queryTerms, "$term definition meaning");
        if (dScore > 0) {
          matches.add(_Match(score: dScore, answer: "$term: $def"));
        }
      });
    }

    // Documentation
    if (_schoolData!['Documentation'] != null) {
      final docs = _schoolData!['Documentation'] as List<dynamic>;
      String docList = docs.join(", ");
      double docScore = _calculateScore(
        queryTerms,
        "documentation requirements admission documents",
      );
      if (docScore > 0) {
        matches.add(
          _Match(score: docScore, answer: "Required documents: $docList"),
        );
      }
    }

    // Buildings
    final buildings = _schoolData!['buildings'] as List<dynamic>?;
    if (buildings != null) {
      for (var b in buildings) {
        double bScore = _calculateScore(queryTerms, "$b building location");
        if (bScore > 0) {
          matches.add(
            _Match(score: bScore, answer: "$b is a key building at AKUM."),
          );
        }
      }
    }

    return matches;
  }

  List<_Match> _searchExamData(List<String> queryTerms) {
    List<_Match> matches = [];
    if (_examData == null) return matches;

    _traverseJson(_examData!, (path, value) {
      if (value is String) {
        double score = _calculateScore(queryTerms, value);
        if (score > 0) {
          String key = path.split('.').last.replaceAll('_', ' ');
          matches.add(
            _Match(
              score: score,
              answer: "Regarding ${key.toUpperCase()}: $value",
            ),
          );
        }
      } else if (value is List) {
        // Check if it's a simple string list
        bool isStringList = value.isNotEmpty && value.first is String;
        if (isStringList) {
          String combined = value.join(" ");
          double score = _calculateScore(queryTerms, combined);
          if (score > 0) {
            String key = path.split('.').last.replaceAll('_', ' ');
            matches.add(
              _Match(
                score: score,
                answer:
                    "Regarding ${key.toUpperCase()}:\n- ${value.join("\n- ")}",
              ),
            );
          }
        }
      }
    }, "");

    return matches;
  }

  void _traverseJson(
    dynamic data,
    Function(String path, dynamic value) onVisit,
    String currentPath,
  ) {
    if (data is Map) {
      data.forEach((k, v) {
        _traverseJson(v, onVisit, currentPath.isEmpty ? k : "$currentPath.$k");
      });
    } else if (data is List) {
      // If it's a list of strings, visit it as a unit. If list of objects, recurse.
      bool isStringList = data.isNotEmpty && data.first is String;
      if (isStringList || data.isEmpty) {
        onVisit(currentPath, data);
      } else {
        for (var item in data) {
          _traverseJson(item, onVisit, currentPath);
        }
      }
    } else {
      onVisit(currentPath, data);
    }
  }

  List<_Match> _searchAboutData(List<String> queryTerms) {
    if (_aboutData == null) return [];
    List<_Match> matches = [];

    final paragraphs = _aboutData!.split('\n\n');
    for (var p in paragraphs) {
      if (p.trim().isEmpty) continue;
      double score = _calculateScore(queryTerms, p);
      if (score > 0) {
        matches.add(_Match(score: score, answer: p.trim()));
      }
    }
    return matches;
  }

  List<_Match> _searchAboutAppData(List<String> queryTerms) {
    if (_aboutAppData == null) return [];
    List<_Match> matches = [];

    final paragraphs = _aboutAppData!.split('\n\n');
    for (var p in paragraphs) {
      if (p.trim().isEmpty) continue;
      double score = _calculateScore(queryTerms, p);
      // Boost score for app-related questions if this file matches
      if (p.toLowerCase().contains("app") ||
          p.toLowerCase().contains("application")) {
        score += 0.2;
      }
      if (score > 0) {
        matches.add(_Match(score: score, answer: p.trim()));
      }
    }
    return matches;
  }
}

class _Match {
  final double score;
  final String answer;
  _Match({required this.score, required this.answer});
}
