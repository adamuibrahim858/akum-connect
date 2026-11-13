import '../models/news_model.dart';

class NewsService {
  // Singleton pattern for smooth in-memory caching and persistence
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;

  NewsService._internal() {
    _initDefaultNews();
  }

  final List<News> _newsList = [];

  void _initDefaultNews() {
    if (_newsList.isNotEmpty) return;

    _newsList.addAll([
      News(
        id: 1,
        title: 'University Senate Approves Revised Academic Calendar for 2026/2027 Session',
        category: 'Senate Notice',
        author: 'Office of the Registrar',
        readTimeMinutes: 4,
        isFeatured: true,
        imageUrl:
            'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=900&q=80',
        createdAt: '2026-11-08T09:30:00Z',
        content: '''The Senate of Abdulkadir Kure University has officially deliberated and approved the revised comprehensive academic calendar for the 2026/2027 Academic Session at its 48th Regular Meeting held at the University Senate Chamber.

Key resolutions and schedule highlights:

1. Resumption & Portal Reopening:
   The university portal will reopen on Monday, November 17, 2026, for normal course registration for all returning and fresh undergraduate students across all faculties.

2. Lecture Commencement:
   First semester lectures for both fresh and returning students will formally commence on Monday, November 24, 2026. Faculty Deans and Heads of Departments are requested to ensure lecture timetables are published immediately.

3. Mid-Semester Assessment & Tests:
   Continuous assessment (C.A.) tests will take place between weeks 7 and 8 of the semester. Students must maintain a minimum of 75% attendance to qualify for semester examinations.

4. Examination Period:
   First semester examinations will run from Monday, March 15 to Saturday, April 3, 2027.

The Vice-Chancellor enjoins all students and faculty staff to adhere strictly to the schedule to guarantee seamless academic progress.''',
      ),
      News(
        id: 2,
        title: 'AKUM Tech Hub Launches Innovation Center & 24/7 AI Research Laboratory',
        category: 'Academics',
        author: 'Directorate of ICT & Innovation',
        readTimeMinutes: 3,
        isFeatured: true,
        imageUrl:
            'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=900&q=80',
        createdAt: '2026-11-06T14:15:00Z',
        content: '''In line with the university management's vision to position Abdulkadir Kure University as a premier technology hub in Northern Nigeria, the Vice-Chancellor today commissioned the newly constructed AKUM Tech & Innovation Hub.

The state-of-the-art facility features:
• A high-performance Artificial Intelligence and Data Science research laboratory equipped with dedicated GPU computing clusters.
• Uninterrupted 24/7 solar power backup and high-speed dedicated 1Gbps fiber internet connection.
• An open-space student startup incubation center offering mentorship, cloud credits, and pre-seed pitch opportunities.
• Collaborative robotics, IoT prototyping benches, and 3D printing equipment.

The Director of ICT announced that free registration is now open for students across all disciplines to join software engineering, UI/UX design, cybersecurity, and applied machine learning fellowship tracks starting next month.''',
      ),
      News(
        id: 3,
        title: 'Student Affairs Opens Portal for On-Campus Hostel Accommodation Balloting',
        category: 'Campus Life',
        author: 'Student Affairs Division',
        readTimeMinutes: 3,
        isFeatured: false,
        imageUrl:
            'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=900&q=80',
        createdAt: '2026-11-04T11:00:00Z',
        content: '''The Dean of Student Affairs wishes to inform the student community that online applications and balloting for on-campus hostel accommodation for the forthcoming semester are now live.

Application Process & Priority Guidelines:
• 100-Level Fresh Students and Final Year (Graduating) Students will receive priority consideration in accordance with university housing policies.
• Students with special medical considerations or certified physical challenges should submit their requests directly to the Health Services Board for dedicated ground-floor allocations.
• All payments must be made strictly via the official university Remita billing portal after securing a valid allocation slip. Beware of unauthorized third parties claiming to sell bed spaces.

The portal will remain open for initial balloting until Friday, November 21, 2026. Successful applicants will be required to complete hall clearance with their respective Hall Wardens before check-in.''',
      ),
      News(
        id: 4,
        title: "Vice Chancellor's Inter-Faculty Cup 2026 Kicks Off this Friday at Main Stadium",
        category: 'Sports',
        author: 'University Sports Council',
        readTimeMinutes: 2,
        isFeatured: false,
        imageUrl:
            'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=900&q=80',
        createdAt: '2026-11-02T16:45:00Z',
        content: '''The 2026 edition of the prestigious Vice Chancellor's Inter-Faculty Games will officially kick off this Friday at 3:30 PM at the University Sports Complex Main Bowl.

Defending champions Faculty of Engineering will lock horns with the Faculty of Management Sciences in the opening football fixture following an exhibition match between Staff and Student Union executives.

This year's sports festival features over 800 student athletes competing across:
• Men's and Women's Football
• Basketball (Outdoor Courts)
• Track & Field (100m, 200m, 4x100m relay, Long Jump)
• Volleyball, Badminton, and Table Tennis
• Chess and Scrabble championships

All lectures will be suspended on Friday by 2:00 PM to enable students and staff cheer their faculty teams. Free refreshments will be provided for early spectators.''',
      ),
      News(
        id: 5,
        title: 'State Government Announces ₦50 Million Undergraduate Research Grants for AKUM Scholars',
        category: 'Academics',
        author: 'Directorate of Research & Linkages',
        readTimeMinutes: 4,
        isFeatured: true,
        imageUrl:
            'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=900&q=80',
        createdAt: '2026-10-28T10:00:00Z',
        content: '''The State Ministry of Tertiary Education and Innovation has instituted a special ₦50 Million Competitive Research and Innovation Grant specifically earmarked for undergraduate and postgraduate scholars of Abdulkadir Kure University.

Target Focus Areas:
1. Smart Agricultural Technologies & Irrigation Systems for dryland farming.
2. Renewable Solar & Wind microgrid energy solutions tailored for rural communities.
3. Digital health monitoring systems and maternal healthcare delivery models.
4. Civic tech and educational access software.

Grants will range from ₦500,000 to ₦2,500,000 per project team. Multidisciplinary student teams comprising students from Computing, Engineering, Agriculture, and Health Sciences are strongly encouraged to collaborate. Full application templates and submission guidelines can be downloaded via the student research portal.''',
      ),
      News(
        id: 6,
        title: 'Distinguished Public Lecture: Future of Renewable Green Energy in Northern Nigeria',
        category: 'Events',
        author: 'Faculty of Science & Engineering',
        readTimeMinutes: 3,
        isFeatured: false,
        imageUrl:
            'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=900&q=80',
        createdAt: '2026-10-22T13:20:00Z',
        content: '''The Faculty of Science and Engineering invites members of the university community, researchers, and energy enthusiasts to a high-level public lecture titled "Transitioning to Clean Energy: Tapping Solar & Biomass Potential for Sustainable Industrialization in Northern Nigeria".

Keynote Speaker:
Prof. Aminu Garba (Fellow of the Nigerian Academy of Engineering and Senior Energy Consultant).

Event Details:
• Date: Thursday, November 19, 2026
• Venue: University Main Auditorium, West Campus
• Time: 10:00 AM Prompt (Guests seated by 9:30 AM)

The lecture will examine real-world decentralised solar microgrid architectures, student opportunities in the burgeoning green economy, and policy incentives for renewable energy adoption. Certificates of attendance will be awarded to participating students.''',
      ),
      News(
        id: 7,
        title: 'University Central Library Grants Free Digital Access to IEEE Xplore, ScienceDirect & JSTOR',
        category: 'Academics',
        author: 'University Library System',
        readTimeMinutes: 3,
        isFeatured: false,
        imageUrl:
            'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?w=900&q=80',
        createdAt: '2026-10-15T08:45:00Z',
        content: '''The University Central Library has successfully renewed institutional subscriptions to global academic research repositories including IEEE Xplore, ScienceDirect, JSTOR, SpringerLink, and HeinOnline for the 2026/2027 academic session.

How to Access off-campus:
Students and faculty researchers can now browse and download millions of peer-reviewed journal papers, conference proceedings, dissertations, and high-impact textbooks both on the campus Wi-Fi network and remotely from their personal devices using their official AKUM institutional email logins.

Training workshops on reference management tools (Mendeley, Zotero) and literature search techniques will be conducted weekly at the e-Library hall starting next Tuesday.''',
      ),
      News(
        id: 8,
        title: 'University Health Services Commences Annual Free Health & Eye Screening Exercise',
        category: 'Campus Life',
        author: 'University Medical Center',
        readTimeMinutes: 2,
        isFeatured: false,
        imageUrl:
            'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=900&q=80',
        createdAt: '2026-10-10T11:30:00Z',
        content: '''The University Health Services Department announces the rollout of its Annual Comprehensive Health and Wellness Screening for all matriculated students.

Screening services provided free of charge include:
• Full Optometry Eye Exams & Reading Glass Consultations
• Blood Pressure, BMI, and Cardiovascular Health Profiling
• Blood Sugar (Glucose) & Hepatitis B Screening
• Dental Health Checkups and Dietary Counseling

Venue: University Health Center Clinics (Opposite Faculty of Arts)
Schedule: Monday to Friday, 8:30 AM – 3:30 PM throughout the month of November.
Students are advised to bring along their valid University ID Cards.''',
      ),
    ]);
  }

  Future<List<News>> getNews({int page = 1, bool forceRefresh = false}) async {
    // Return cloned list to ensure data integrity
    return List<News>.from(_newsList);
  }

  Future<News> getNewsDetail(int id) async {
    return _newsList.firstWhere(
      (item) => item.id == id,
      orElse: () => _newsList.first,
    );
  }

  List<String> getCategories() {
    final Set<String> categories = {'All'};
    for (final news in _newsList) {
      if (news.category.isNotEmpty) {
        categories.add(news.category);
      }
    }
    return categories.toList();
  }
}
