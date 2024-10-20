import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Import for formatting timestamps
import 'package:test_2/ChatPage/chat_page.dart'; // Import your ChatPage

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
          color: Colors.white, // Set back button color to white
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context); // Navigate back when tapped
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

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Workers')
                    .doc(workerId)
                    .get(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> workerSnapshot) {
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

                  // Cast the worker data as a Map<String, dynamic>
                  var workerData = workerSnapshot.data!.data() as Map<String, dynamic>;
                  var lastMessage = conversation['lastMessage'] ?? 'No messages yet'; // Fallback for empty conversations
                  var lastMessageTimestamp = conversation['lastMessageTimestamp'] as Timestamp?;

                  // Format the timestamp with UTC +8 offset
var messageTime = lastMessageTimestamp != null
    ? DateFormat('hh:mm a').format(lastMessageTimestamp.toDate().add(const Duration(hours: 8)))
    : ''; // If no timestamp, leave it blank


                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: workerData['profileImageUrl'] != null
                          ? NetworkImage(workerData['profileImageUrl'])
                          : const AssetImage('lib/assets/placeholder.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      '${workerData['first name']} ${workerData['last name']}',
                      style: TextStyle(fontWeight: FontWeight.bold), // Added bold style for name
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Truncate long messages
                    ),
                    trailing: Text(
                      messageTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ), // Display the time in the trailing position
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            conversationId: conversation.id,
                            receiverFirstName: workerData['first name'],
                            receiverLastName: workerData['last name'],
                            receiverEmail: workerData['email'], // This can be removed from the ChatPage constructor if not needed
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
