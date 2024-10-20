import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String receiverFirstName;
  final String receiverLastName;
  final String receiverUid; // Use UID for receiver
  final String receiverEmail; // Add receiver email

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.receiverFirstName,
    required this.receiverLastName,
    required this.receiverUid,
    required this.receiverEmail,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _updateConversationDetails();
    _markMessagesAsRead(); // Mark messages as read when entering the chat
  }

  // Update conversation details with customer and worker names
  Future<void> _updateConversationDetails() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Fetch customer name from 'Customers' collection
      DocumentSnapshot customerDoc =
          await _firestore.collection('Customers').doc(currentUser.uid).get();

      String customerName = '';
      if (customerDoc.exists) {
        customerName =
            '${customerDoc['first name']} ${customerDoc['last name']}';
      } else {
        print('Customer document does not exist for uid: ${currentUser.uid}');
        return; // Exit if customer document doesn't exist
      }

      // Fetch worker name from 'Workers' collection using receiver's UID
      DocumentSnapshot workerDoc =
          await _firestore.collection('Workers').doc(widget.receiverUid).get();

      String workerName = '';
      if (workerDoc.exists) {
        workerName = '${workerDoc['first name']} ${workerDoc['last name']}';
      } else {
        print('Worker document does not exist for uid: ${widget.receiverUid}');
        return; // Exit if worker document doesn't exist
      }

      // Update the conversation with customer and worker names
      await _firestore
          .collection('Conversations')
          .doc(widget.conversationId)
          .update({
        'customerName': customerName,
        'workerName': workerName,
      });
    }
  }

  // Send a message
  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      var currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Fetch sender's first and last name from either 'Customers' or 'Workers' collection
        DocumentSnapshot senderDoc;
        String senderName = '';

        senderDoc =
            await _firestore.collection('Customers').doc(currentUser.uid).get();
        if (senderDoc.exists) {
          senderName = '${senderDoc['first name']} ${senderDoc['last name']}';
        } else {
          senderDoc =
              await _firestore.collection('Workers').doc(currentUser.uid).get();
          if (senderDoc.exists) {
            senderName = '${senderDoc['first name']} ${senderDoc['last name']}';
          } else {
            print('Sender document does not exist.');
            return; // Exit if sender document is not found
          }
        }

        // Add a message to Firestore 'Messages' sub-collection
        _firestore
            .collection('Conversations')
            .doc(widget.conversationId)
            .collection('Messages')
            .add({
          'senderId': currentUser.uid,
          'receiverId': widget.receiverUid, // Use receiver's UID
          'receiverEmail': widget.receiverEmail, // Store receiver's email
          'senderName': senderName, // Use sender's full name
          'receiverName':
              '${widget.receiverFirstName} ${widget.receiverLastName}', // Use receiver's full name
          'messageText': _messageController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false, // New message is unread by default
        });

        // Update the last message and timestamp in the parent conversation document
        _firestore
            .collection('Conversations')
            .doc(widget.conversationId)
            .update({
          'lastMessage': _messageController.text,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });

        _messageController.clear(); // Clear the message input field
      }
    }
  }

  // Mark all messages as read when the conversation is opened
  Future<void> _markMessagesAsRead() async {
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      QuerySnapshot unreadMessages = await _firestore
          .collection('Conversations')
          .doc(widget.conversationId)
          .collection('Messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.receiverFirstName} ${widget.receiverLastName}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('Conversations')
                  .doc(widget.conversationId)
                  .collection('Messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    var isCurrentUser = message['senderId'] ==
                        FirebaseAuth.instance.currentUser!.uid;

                    // Handle the timestamp safely with a null check
                    var timestamp = message['timestamp'] != null
                        ? (message['timestamp'] as Timestamp)
                            .toDate()
                            .add(const Duration(hours: 8)) // Convert to UTC+8
                        : null;

                    return Align(
                      alignment:
                          isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: isCurrentUser
                                ? const Radius.circular(15)
                                : const Radius.circular(0),
                            bottomRight: isCurrentUser
                                ? const Radius.circular(0)
                                : const Radius.circular(15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['messageText'],
                              style: TextStyle(
                                color: isCurrentUser ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (timestamp != null)
                              Text(
                                DateFormat('MMM dd, hh:mm a').format(timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCurrentUser ? Colors.white70 : Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.grey),
                  onPressed: () {
                    // Implement the add button functionality if needed
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            const BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
