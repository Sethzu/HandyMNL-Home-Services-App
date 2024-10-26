import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String receiverFirstName;
  final String receiverLastName;
  final String receiverUid;
  final String receiverEmail;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.receiverFirstName,
    required this.receiverLastName,
    required this.receiverUid,
    required this.receiverEmail,
  });

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _updateConversationDetails();
    _markMessagesAsRead();
  }

  Future<void> _updateConversationDetails() async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    print('No current user is logged in.');
    return;
  }

  String customerName = '';
  String workerName = '';
  
  try {
    // Check if the current user is a customer
    DocumentSnapshot customerDoc =
        await FirebaseFirestore.instance.collection('Customers').doc(currentUser.uid).get();

    if (customerDoc.exists) {
      // Current user is a customer, so fetch their name
      customerName = '${customerDoc['first name']} ${customerDoc['last name']}';

      // Now fetch the worker (the receiver)
      DocumentSnapshot workerDoc =
          await FirebaseFirestore.instance.collection('Workers').doc(widget.receiverUid).get();

      if (workerDoc.exists) {
        workerName = '${workerDoc['first name']} ${workerDoc['last name']}';
      } else {
        print('Worker document does not exist for uid: ${widget.receiverUid}');
        return;
      }
    } else {
      // Current user is not a customer, so check if they are a worker
      DocumentSnapshot workerDoc =
          await FirebaseFirestore.instance.collection('Workers').doc(currentUser.uid).get();

      if (workerDoc.exists) {
        // Current user is a worker, so fetch their name
        workerName = '${workerDoc['first name']} ${workerDoc['last name']}';

        // Now fetch the customer (the receiver)
        DocumentSnapshot customerDoc =
            await FirebaseFirestore.instance.collection('Customers').doc(widget.receiverUid).get();

        if (customerDoc.exists) {
          customerName = '${customerDoc['first name']} ${customerDoc['last name']}';
        } else {
          print('Customer document does not exist for uid: ${widget.receiverUid}');
          return;
        }
      } else {
        print('Current user is neither a customer nor a worker.');
        return;
      }
    }

    // Update the conversation with customer and worker names
    await FirebaseFirestore.instance
        .collection('Conversations')
        .doc(widget.conversationId)
        .update({
      'customerName': customerName,
      'workerName': workerName,
    });
  } catch (e) {
    print('Error updating conversation details: $e');
  }
}

  // Send a message
void _sendMessage() async {
  if (_messageController.text.isNotEmpty) {
    var currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Fetch sender's name from Firestore (either 'Customers' or 'Workers')
      DocumentSnapshot senderDoc;
      String senderName = '';

      // Determine if sender is a Customer or Worker
      senderDoc = await _firestore.collection('Customers').doc(currentUser.uid).get();
      if (senderDoc.exists) {
        senderName = '${senderDoc['first name']} ${senderDoc['last name']}';
      } else {
        senderDoc = await _firestore.collection('Workers').doc(currentUser.uid).get();
        if (senderDoc.exists) {
          senderName = '${senderDoc['first name']} ${senderDoc['last name']}';
        } else {
          print('Sender document does not exist.');
          return;
        }
      }

      // Add a message to Firestore 'Messages' sub-collection
      _firestore
          .collection('Conversations')
          .doc(widget.conversationId)
          .collection('Messages')
          .add({
        'senderId': currentUser.uid,
        'receiverId': widget.receiverUid,
        'receiverEmail': widget.receiverEmail,
        'senderName': senderName,
        'receiverName': '${widget.receiverFirstName} ${widget.receiverLastName}',
        'messageText': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false, // Message starts as unread
      });

      // Update the last message and timestamp in the parent conversation document
      _firestore.collection('Conversations').doc(widget.conversationId).update({
        'lastMessage': _messageController.text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'isRead': false, // Set conversation's isRead to false because the new message is unread
        'senderId': currentUser.uid, 
      });

      _messageController.clear();
    }
  }
}


// Send an image (with option to choose between camera or gallery in iOS style)
  Future<void> _sendImage() async {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: <Widget>[
            // Camera option comes first
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickImage(
                    ImageSource.camera); // Take a new photo with camera
              },
              child: const Text(
                'Take a photo',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueAccent, // Accent blue color for text
                ),
              ),
            ),
            // Gallery option comes second
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickImage(
                    ImageSource.gallery); // Pick image from gallery
              },
              child: const Text(
                'Choose from library',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueAccent, // Accent blue color for text
                ),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop(); // Close the action sheet
            },
            isDefaultAction: true,
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold, // Bold text for Cancel
                color: Colors.blueAccent, // Accent blue color for Cancel button
              ),
            ),
          ),
        );
      },
    );
  }

// Function to pick an image from the selected source (gallery or camera)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      var currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && _selectedImage != null) {
        // Fetch sender's name from Firestore (either 'Customers' or 'Workers')
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
            return;
          }
        }

        // Upload image to Firebase Storage
        String filePath =
            'message_uploaded_images/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.png';
        UploadTask uploadTask = _storage.ref(filePath).putFile(_selectedImage!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Add the image URL to the Firestore 'Messages' sub-collection
        await _firestore
            .collection('Conversations')
            .doc(widget.conversationId)
            .collection('Messages')
            .add({
          'senderId': currentUser.uid,
          'receiverId': widget.receiverUid,
          'receiverEmail': widget.receiverEmail,
          'senderName': senderName,
          'receiverName':
              '${widget.receiverFirstName} ${widget.receiverLastName}',
          'imageUrl': downloadUrl,
          'messageText': '$senderName sent a photo.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        // Update the last message and timestamp in the parent conversation document
        await _firestore
            .collection('Conversations')
            .doc(widget.conversationId)
            .update({
          'lastMessage': '$senderName sent a photo.',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'isRead': false,  // Mark conversation as unread
        });

        setState(() {
          _selectedImage = null;
        });
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

    // Mark all unread messages as read
    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }

    // After marking all messages as read, update the 'Conversations' collection
    // Set 'isRead' to true, meaning the conversation has no unread messages for the current user
    if (unreadMessages.docs.isNotEmpty) {
      await _firestore
          .collection('Conversations')
          .doc(widget.conversationId)
          .update({'isRead': true});
    }
  }
}


  // Show image in full screen
  void _showImageFullScreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
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

                    var timestamp = message['timestamp'] != null
                        ? (message['timestamp'] as Timestamp)
                            .toDate()
                            .add(const Duration(hours: 8))
                        : null;

                    var messageData = message.data() as Map<String, dynamic>;

                    // If message contains an image URL, display it without a chat bubble
                    if (messageData.containsKey('imageUrl')) {
                      return GestureDetector(
                        onTap: () => _showImageFullScreen(message['imageUrl']),
                        child: Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                message['imageUrl'],
                                fit: BoxFit.cover,
                                width: MediaQuery.of(context).size.width * 0.4,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    // For text messages, display in chat bubbles
                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.blueAccent
                              : Colors.grey[300],
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
                                color:
                                    isCurrentUser ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (timestamp != null)
                              Text(
                                DateFormat('MMM dd, hh:mm a').format(timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCurrentUser
                                      ? Colors.white70
                                      : Colors.black54,
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
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    minLines: 1, // Minimum number of lines (collapsed)
    maxLines: null, // Expands as user types
    keyboardType: TextInputType.multiline,
  ),
),
IconButton(
  icon: const Icon(Icons.image, color: Colors.grey),
  onPressed: _sendImage, // Handle sending an image
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
