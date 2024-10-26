import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:test_2/ChatPage/chat_page.dart';

class CustomerInbox extends StatelessWidget {
  const CustomerInbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inbox',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 21,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Conversations')
            .where('customerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var conversation = snapshot.data!.docs[index];
              var workerId = conversation['workerId'];
              var data = conversation.data() as Map<String, dynamic>?; // Ensure data is a Map<String, dynamic>
              bool isRead = data != null && data.containsKey('isRead') ? data['isRead'] : true;
              var senderId = data != null && data.containsKey('senderId') ? data['senderId'] : null;
              var customerId = conversation['customerId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Workers')
                    .doc(workerId)
                    .get(),
                builder:
                    (context, AsyncSnapshot<DocumentSnapshot> workerSnapshot) {
                  if (!workerSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(
                          backgroundImage:
                              AssetImage('lib/assets/placeholder.png')),
                      title: Text('Loading...'),
                    );
                  }

                  if (workerSnapshot.data == null || !workerSnapshot.data!.exists) {
                    return const ListTile(
                      leading: CircleAvatar(
                          backgroundImage:
                              AssetImage('lib/assets/placeholder.png')),
                      title: Text('Unknown Worker'),
                    );
                  }

                  var workerData = workerSnapshot.data!.data() as Map<String, dynamic>;
                  var lastMessage = conversation['lastMessage'] ?? 'No messages yet';
                  var lastMessageTimestamp = conversation['lastMessageTimestamp'] as Timestamp?;

                  var messageTime = lastMessageTimestamp != null
                      ? DateFormat('hh:mm a').format(lastMessageTimestamp
                          .toDate()
                          .add(const Duration(hours: 8)))
                      : '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: workerData['profileImageUrl'] != null
                          ? NetworkImage(workerData['profileImageUrl'])
                          : const AssetImage('lib/assets/placeholder.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      '${workerData['first name']} ${workerData['last name']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold), // Bold style for name
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: (isRead || customerId == senderId)
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    trailing: Text(
                      messageTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            conversationId: conversation.id,
                            receiverFirstName: workerData['first name'],
                            receiverLastName: workerData['last name'],
                            receiverEmail: workerData['email'],
                            receiverUid: workerData['workerId'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
