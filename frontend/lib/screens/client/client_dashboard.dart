import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/screens/client/sos_radar_screen.dart';
import 'package:frontend/screens/client/client_edit_profile_screen.dart';
import 'package:frontend/screens/client/ai_chat_screen.dart';
import 'package:frontend/screens/client/document_scanner_screen.dart';
import 'package:frontend/screens/shared/case_history_screen.dart';
import 'package:frontend/screens/shared/support_tickets_screen.dart';
import 'package:frontend/utils/responsive_layout.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Widget _buildGreeting(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Good Day,",
          style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Loading...", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold));
            }
            String displayName = user?.phoneNumber ?? "Citizen";
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              if (data.containsKey('name') && data['name'].toString().isNotEmpty) {
                displayName = data['name'];
              }
            }
            return Text(
              displayName,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF2D3142), letterSpacing: -0.5),
            );
          },
        ),
      ],
    );
  }

  // 🚀 REMOVED the hardcoded margin here so the parent layout can strictly control sizing
  Widget _buildPremiumCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Ink(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final List<Widget> serviceCards = [
      _buildPremiumCard(context: context, title: "Emergency SOS", subtitle: "Instant radar broadcast to nearby lawyers.", icon: Icons.emergency_share_rounded, gradientColors: [const Color(0xFFFF4B4B), const Color(0xFFD60000)], onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const SosRadarScreen())); }),
      _buildPremiumCard(context: context, title: "AI Paralegal", subtitle: "Smart triage and instant legal advice.", icon: Icons.auto_awesome_rounded, gradientColors: [const Color(0xFF8A2387), const Color(0xFFE94057)], onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const AiChatScreen())); }),
      _buildPremiumCard(context: context, title: "Document Scanner", subtitle: "Translate complex legal jargon instantly.", icon: Icons.document_scanner_rounded, gradientColors: [const Color(0xFF1CB5E0), const Color(0xFF000046)], onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const DocumentScannerScreen())); }),
      _buildPremiumCard(context: context, title: "Active Cases", subtitle: "Resume secure communication channels.", icon: Icons.forum_rounded, gradientColors: [const Color(0xFF11998E), const Color(0xFF38EF7D)], onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const CaseHistoryScreen(role: 'client'))); }),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        title: const Text(
          "NyayaBridge",
          style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_rounded, color: Color(0xFF2D3142), size: 28),
            tooltip: "Customer Support",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportTicketsScreen(role: 'client')));
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.person_outline, color: Color(0xFF2D3142), size: 24),
            ),
            tooltip: "Edit Profile",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientEditProfileScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black45),
            tooltip: "Logout",
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          // --- MOBILE VIEW (Scrollable) ---
          mobile: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(user),
                const SizedBox(height: 32),
                const Text("Legal Services", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                const SizedBox(height: 20),
                serviceCards[0],
                const SizedBox(height: 20),
                serviceCards[1],
                const SizedBox(height: 20),
                serviceCards[2],
                const SizedBox(height: 20),
                serviceCards[3],
                const SizedBox(height: 24),
              ],
            ),
          ),

          // --- CHROME / DESKTOP VIEW (Zero Scroll, Locked 2x2 Grid) ---
          desktop: Padding(
            padding: const EdgeInsets.only(left: 40.0, right: 40.0, bottom: 40.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel (Greeting & Info)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreeting(user),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade100)
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.security, color: Colors.blue, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text("End-to-End Encrypted", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                                  SizedBox(height: 8),
                                  Text("Welcome to the NyayaBridge Web Portal. All your communications, document scans, and SOS alerts are secured.", style: TextStyle(color: Colors.blue, height: 1.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(width: 40),

                // Right Panel (The 4 Locked Boxes)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Legal Services", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                      const SizedBox(height: 24),
                      // 🚀 THE MAGIC: Uses Expanded to force the 4 boxes to perfectly fill the screen height
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: serviceCards[0]),
                                  const SizedBox(width: 24),
                                  Expanded(child: serviceCards[1]),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: serviceCards[2]),
                                  const SizedBox(width: 24),
                                  Expanded(child: serviceCards[3]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
