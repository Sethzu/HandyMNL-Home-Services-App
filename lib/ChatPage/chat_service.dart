
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to count unread messages for a specific conversation
  Future<int> countUnreadMessages(String conversationId, String userId) async {
    QuerySnapshot unreadMessages = await _firestore
        .collection('Conversations')
        .doc(conversationId)
        .collection('Messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    return unreadMessages.docs.length;
  }
}
