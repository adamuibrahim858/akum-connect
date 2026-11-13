import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../portal_webview_page.dart';

class NelfundPage extends StatefulWidget {
  const NelfundPage({super.key});

  @override
  State<NelfundPage> createState() => _NelfundPageState();
}

class _NelfundPageState extends State<NelfundPage> {
  static const String _registrationUrl = 'https://portal.nelf.gov.ng/auth/register';
  static const String _loginUrl = 'https://portal.nelf.gov.ng/auth/login';
  static const String _portalHomeUrl = 'https://nelf.gov.ng';
  static const String _supportEmail = 'info@nelfund.gov.ng';

  void _openInWebView(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PortalWebViewPage(
          initialUrl: url,
          title: title,
        ),
      ),
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening portal: $e')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=NELFUND Inquiry - Abdulkadir Kure University Student',
    );
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email client for $email')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance_rounded, size: 22, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'NELFUND Student Portal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF008751), // Official Nigerian Emerald Green
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'NELFUND Website',
            icon: const Icon(Icons.language_rounded),
            onPressed: () => _openExternalUrl(_portalHomeUrl),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Official Federal Government Header Banner
            _buildOfficialHeader(),

            const SizedBox(height: 18),

            // Key Highlights Bar (Tuition + Upkeep + 0% Interest)
            _buildHighlightsRow(),

            const SizedBox(height: 24),

            // CARD 1: NEW REGISTRATION & MANUAL (Runs in WebView)
            _buildRegistrationCard(),

            const SizedBox(height: 20),

            // CARD 2: LOGIN & TRACKING MANUAL (Runs in WebView)
            _buildLoginCard(),

            const SizedBox(height: 20),

            // Official Support & AKUM Campus Desk Card
            _buildOfficialSupportCard(),

            const SizedBox(height: 20),

            // Quick FAQs Accordion
            _buildFaqSection(),
          ],
        ),
      ),
    );
  }

  // Official Federal Government Header Banner
  Widget _buildOfficialHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006837), Color(0xFF008751), Color(0xFF00A86B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008751).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FEDERAL REPUBLIC OF NIGERIA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Nigeria Education Loan Fund',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Empowering students of Abdulkadir Kure University with zero-interest institutional fee loans and monthly upkeep allowances.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  // Key Highlights Bar
  Widget _buildHighlightsRow() {
    return Row(
      children: [
        _buildHighlightBadge(
          icon: Icons.money_off_rounded,
          title: '0% Interest',
          subtitle: 'Pure Student Loan',
        ),
        const SizedBox(width: 10),
        _buildHighlightBadge(
          icon: Icons.payments_outlined,
          title: 'Monthly Upkeep',
          subtitle: 'Direct to Account',
        ),
        const SizedBox(width: 10),
        _buildHighlightBadge(
          icon: Icons.timelapse_rounded,
          title: 'Post-NYSC',
          subtitle: '2 Years Grace',
        ),
      ],
    );
  }

  Widget _buildHighlightBadge({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF008751), size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // CARD 1: NEW REGISTRATION & MANUAL (Opens in WebView)
  Widget _buildRegistrationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: const Text(
                  'FIRST-TIME APPLICANTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF008751),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF008751), size: 24),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'New Student Loan Registration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Create your official NELFUND student profile, verify your identity using NIN and BVN, and submit your loan application for AKUM tuition and monthly upkeep.',
            style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _openInWebView(_registrationUrl, 'NELFUND Registration'),
                  icon: const Icon(Icons.language_rounded, size: 16),
                  label: const Text(
                    'Register Online',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008751),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: _showRegistrationManualModal,
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text(
                    'Guide / Manual',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF008751),
                    side: const BorderSide(color: Color(0xFF008751), width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CARD 2: LOGIN & TRACKING MANUAL (Opens in WebView)
  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'REGISTERED STUDENTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1D4ED8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Icon(Icons.login_rounded, color: Color(0xFF1D4ED8), size: 24),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'Student Portal Login & Tracking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Already created an account? Sign in to check your application status, verify university fee clearance, and monitor monthly upkeep disbursement into your bank account.',
            style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _openInWebView(_loginUrl, 'NELFUND Login'),
                  icon: const Icon(Icons.dashboard_rounded, size: 16),
                  label: const Text(
                    'Student Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: _showLoginManualModal,
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  label: const Text(
                    'Login Manual',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D4ED8),
                    side: const BorderSide(color: Color(0xFF1D4ED8), width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Official Support & AKUM Campus Desk
  Widget _buildOfficialSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.support_agent_rounded, color: Color(0xFF008751), size: 22),
              SizedBox(width: 8),
              Text(
                'NELFUND Official Support & Helpdesk',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Official NELFUND Email Row
          InkWell(
            onTap: () => _sendEmail(_supportEmail),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_rounded, size: 18, color: Color(0xFF008751)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Official Support Email',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Text(
                          _supportEmail,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF008751),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Campus Desk Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                    children: [
                      TextSpan(
                        text: 'AKUM Campus Desk: ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      TextSpan(
                        text: 'Student Affairs Division (NELFUND Desk Officer), West Campus Admin Building.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              const Text(
                'Campus Desk Hours: Mon - Fri (9:00 AM - 3:00 PM)',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Frequently Asked Questions
  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        _buildFaqItem(
          question: 'Who is eligible for NELFUND?',
          answer:
              'Any Nigerian student currently admitted and studying at Abdulkadir Kure University with a verified JAMB admission number, National Identity Number (NIN), and Bank Verification Number (BVN).',
        ),
        _buildFaqItem(
          question: 'How is the institutional tuition fee paid?',
          answer:
              'Tuition fee loans are disbursed directly by NELFUND into the official bank account of Abdulkadir Kure University on your behalf. You do not receive the tuition cash directly.',
        ),
        _buildFaqItem(
          question: 'How does the monthly upkeep allowance work?',
          answer:
              'The upkeep allowance is deposited directly into your personal commercial bank account on a monthly basis to support your accommodation, feeding, books, and campus living expenses.',
        ),
        _buildFaqItem(
          question: 'When does loan repayment start?',
          answer:
              'Repayment commences exactly two (2) years after completing the mandatory National Youth Service Corps (NYSC) scheme, subject to employment. 10% of your salary will be deducted through your employer or direct remittance.',
        ),
      ],
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        iconColor: const Color(0xFF008751),
        collapsedIconColor: const Color(0xFF64748B),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.45),
          ),
        ],
      ),
    );
  }

  // ================= MODAL MANUALS =================

  // Modal 1: Complete Step-by-Step Registration Guide & Checklist
  void _showRegistrationManualModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: const [
                  Icon(Icons.menu_book_rounded, color: Color(0xFF008751), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'NELFUND Registration Manual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Complete checklist and step-by-step instructions for AKUM students.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),

              const Divider(height: 24),

              // Checklist Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.checklist_rounded, color: Color(0xFF008751), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Pre-Registration Checklist (Must Have):',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF008751),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _CheckItem(text: 'National Identity Number (NIN) with active phone link'),
                    _CheckItem(text: 'Bank Verification Number (BVN) matching your exact name'),
                    _CheckItem(text: 'JAMB Registration Number (From your JAMB admission slip)'),
                    _CheckItem(text: 'AKUM Matriculation Number (For returning students)'),
                    _CheckItem(text: 'Active email address & mobile phone number'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Step-by-Step Registration Procedure',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              const _StepCard(
                step: '1',
                title: 'Access Official Portal',
                description:
                    'Navigate to portal.nelf.gov.ng/auth/register on your browser or tap the "Register Online" button to open in the app.',
              ),
              const _StepCard(
                step: '2',
                title: 'Verify NIN & Personal Details',
                description:
                    'Enter your 11-digit NIN. An OTP verification code may be sent to the phone number linked to your NIN. Verify date of birth and full name.',
              ),
              const _StepCard(
                step: '3',
                title: 'BVN Authentication',
                description:
                    'Input your Bank Verification Number (BVN). Ensure the name on your BVN exactly matches your NIN to prevent automatic rejection.',
              ),
              const _StepCard(
                step: '4',
                title: 'Select Institution & Academic Records',
                description:
                    'Select State and choose "Abdulkadir Kure University". Enter your JAMB registration number and Matric number. Select your faculty and department.',
              ),
              const _StepCard(
                step: '5',
                title: 'Select Loan Packages',
                description:
                    'Tick both: (a) Institutional Fee Loan (covers your academic session tuition) and (b) Upkeep Allowance (monthly stipend to your bank account).',
              ),
              const _StepCard(
                step: '6',
                title: 'Review & Submit Application',
                description:
                    'Carefully double-check your account details (bank name and account number for upkeep). Submit and download your acknowledgment slip.',
              ),

              const SizedBox(height: 16),

              // Warning Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'CRITICAL NOTICE: NELFUND systems perform automated cross-validation between NIMC (NIN), NIBSS (BVN), and JAMB. If there is a surname or date-of-birth discrepancy, correct it at NIMC or your bank before applying.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF991B1B), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openInWebView(_registrationUrl, 'NELFUND Registration');
                  },
                  icon: const Icon(Icons.language_rounded, size: 18),
                  label: const Text('Proceed to Online Registration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008751),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modal 2: Login & Tracking Manual (Removed 'Pending Institution Verification' card)
  void _showLoginManualModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: const [
                  Icon(Icons.help_outline_rounded, color: Color(0xFF1D4ED8), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Login & Status Tracking Guide',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'How to monitor your loan approval, verify school fees, and fix portal issues.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),

              const Divider(height: 24),

              const Text(
                'Understanding Your Application Statuses',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              _buildStatusExplainer(
                status: 'SUBMITTED',
                color: Colors.orange,
                desc: 'Your application has been received and queued for university verification.',
              ),
              _buildStatusExplainer(
                status: 'VERIFIED BY INSTITUTION',
                color: Colors.blue,
                desc: 'AKUM Student Affairs has cross-referenced and confirmed your matriculation status.',
              ),
              _buildStatusExplainer(
                status: 'APPROVED',
                color: const Color(0xFF008751),
                desc: 'Loan granted by NELFUND Board. Funds are scheduled for disbursement.',
              ),
              _buildStatusExplainer(
                status: 'DISBURSED',
                color: const Color(0xFF008751),
                desc: 'Tuition paid to AKUM; monthly upkeep transferred to your personal bank account.',
              ),

              const SizedBox(height: 20),

              const Text(
                'Troubleshooting Common Issues',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              _buildTroubleshootCard(
                issue: 'Forgotten Password',
                solution:
                    'Tap "Forgot Password" on the login screen. Enter your registered email to receive a password reset link. Check your spam/junk folder if not found within 2 minutes.',
              ),
              _buildTroubleshootCard(
                issue: 'Did Not Receive Upkeep Stipend',
                solution:
                    'Verify that the account number provided is a Tier-3 savings/current account with no daily deposit limit restrictions that could bounce the transfer.',
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openInWebView(_loginUrl, 'NELFUND Login');
                  },
                  icon: const Icon(Icons.dashboard_rounded, size: 18),
                  label: const Text('Proceed to Portal Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusExplainer({
    required String status,
    required Color color,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootCard({required String issue, required String solution}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_circle_outlined, size: 16, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 6),
              Text(
                issue,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            solution,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;

  const _CheckItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF008751), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF008751),
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
