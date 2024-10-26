import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:test_2/ChatPage/chat_page.dart';

class WorkerInbox extends StatelessWidget {
  const WorkerInbox({super.key});

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
            .where('workerId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid)
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
              var customerId = conversation['customerId'];
              var data = conversation.data() as Map<String,
                  dynamic>?; // Ensure data is a Map<String, dynamic>
              bool isRead = data != null && data.containsKey('isRead')
                  ? data['isRead']
                  : true;
              var senderId = data != null && data.containsKey('senderId')
                  ? data['senderId']
                  : null;
              var workerId = conversation['workerId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Customers')
                    .doc(customerId)
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

                  if (workerSnapshot.data == null ||
                      !workerSnapshot.data!.exists) {
                    return const ListTile(
                      leading: CircleAvatar(
                          backgroundImage:
                              AssetImage('lib/assets/placeholder.png')),
                      title: Text('Unknown Customer'),
                    );
                  }

                  var customerData =
                      workerSnapshot.data!.data() as Map<String, dynamic>;
                  var lastMessage =
                      conversation['lastMessage'] ?? 'No messages yet';
                  var lastMessageTimestamp =
                      conversation['lastMessageTimestamp'] as Timestamp?;

                  var messageTime = lastMessageTimestamp != null
                      ? DateFormat('hh:mm a').format(lastMessageTimestamp
                          .toDate()
                          .add(const Duration(hours: 8)))
                      : '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: customerData['profileImageUrl'] != null
                          ? NetworkImage(customerData['profileImageUrl'])
                          : const AssetImage('lib/assets/placeholder.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      '${customerData['first name']} ${customerData['last name']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold), // Bold style for name
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: (isRead || workerId == senderId)
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
                            receiverFirstName: customerData['first name'],
                            receiverLastName: customerData['last name'],
                            receiverEmail: customerData['email'],
                            receiverUid: customerData['customerId'],
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
