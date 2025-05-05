import 'package:cloud_firestore/cloud_firestore.dart';
class AdminService {
Future<List<Map<String, dynamic>>> getAllUsers() async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('users')
      .get();

  return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
}

}
