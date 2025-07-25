import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ApproveTherapistsScreen extends StatelessWidget {
  final _firestore = FirebaseFirestore.instance;

  ApproveTherapistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Therapist Verification Panel')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('therapists')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Error fetching data'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text('No therapists found'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final personal = data['personalInfo'] ?? {};
              final professional = data['professionalQualifications'] ?? {};
              final licensing = data['licensing'] ?? {};
              final clinic = data['clinicInfo'] ?? {};
              final languages = data['languages'] ?? {};
              final charges = data['sessionCharges'] ?? {};

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personal['fullName'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "📧 ${personal['email'] ?? '-'} | 📞 ${personal['contact'] ?? '-'}",
                      ),
                      Text(
                        "🎂 ${personal['dob'] ?? '-'} | 🧑 ${personal['gender'] ?? '-'}",
                      ),
                      const Divider(),
                      Text("🎓 Degrees: ${professional['degrees'] ?? '-'}"),
                      Text(
                        "📜 Certifications: ${professional['certifications'] ?? '-'}",
                      ),
                      Text(
                        "🏥 Specializations: ${professional['specializations'] ?? '-'}",
                      ),
                      Text(
                        "📅 Experience: ${professional['yearsOfExperience'] ?? 0} years",
                      ),
                      const Divider(),
                      Text("🏷 License: ${licensing['licenseNumber'] ?? '-'}"),
                      if ((licensing['documents'] ?? []).isNotEmpty)
                        TextButton(
                          onPressed:
                              () => _launchUrls(
                                List<String>.from(licensing['documents'] ?? []),
                              ),
                          child: const Text("📁 View Documents"),
                        ),
                      const Divider(),
                      Text("🏢 Clinic: ${clinic['clinicName'] ?? '-'}"),
                      Text("📍 Address: ${clinic['address'] ?? '-'}"),
                      Text(
                        "📆 Availability: ${clinic['availability'] != null ? clinic['availability'].toString() : '-'}",
                      ),
                      Text("💻 Mode: ${clinic['therapyMode'] ?? '-'}"),
                      Text("📎 Meet: ${clinic['googleMeetLink'] ?? '-'}"),
                      const Divider(),
                      Text(
                        "🗣 Spoken: ${(languages['spoken'] ?? []).join(', ')}",
                      ),
                      Text(
                        "🧠 Therapy: ${(languages['therapy'] ?? []).join(', ')}",
                      ),
                      Text(
                        "🔥 Expertise: ${(data['expertise'] ?? []).join(', ')}",
                      ),
                      const Divider(),
                      Text("💵 Fee: ₹${charges['fee'] ?? '0'}"),
                      Text("📦 Packages: ${charges['packages'] ?? '-'}"),
                      if ((data['introVideo'] ?? '').isNotEmpty)
                        TextButton(
                          onPressed: () => _launchUrl(data['introVideo']),
                          child: const Text("🎬 Watch Intro Video"),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(
                              data['verificationStatus'] == true
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: Colors.white,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  data['verificationStatus'] == true
                                      ? Colors.green
                                      : Colors.grey,
                            ),
                            label: Text(
                              data['verificationStatus'] == true
                                  ? 'Unapprove'
                                  : 'Approve',
                            ),
                            onPressed:
                                () => _toggleApproval(
                                  doc.id,
                                  data['verificationStatus'] ?? false,
                                  context,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleApproval(
    String docId,
    bool currentStatus,
    BuildContext context,
  ) async {
    try {
      // Get the therapist document
      final docSnapshot =
          await _firestore.collection('therapists').doc(docId).get();
      final data = docSnapshot.data();
      final therapistUid = data?['therapistId'];

      if (therapistUid == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Therapist ID missing')));
        return;
      }

      final newStatus = !currentStatus;

      // Update therapist verification status
      await _firestore.collection('therapists').doc(docId).update({
        'verificationStatus': newStatus,
      });

      // Update user profile isApproved flag
      await _firestore.collection('users').doc(therapistUid).update({
        'isApproved': newStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? 'Therapist approved' : 'Therapist unapproved',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _launchUrls(List<String> urls) async {
    for (final url in urls) {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }
}
