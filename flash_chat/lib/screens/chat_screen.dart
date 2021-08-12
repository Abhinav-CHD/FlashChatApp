import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

String? loggedInUserEmail;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? messageText;

  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  void getCurrentUser() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        loggedInUserEmail = _auth.currentUser!.email;
        showSnackBar(context, '$loggedInUserEmail has signed in');
      }
    });
    // final user = await _auth.currentUser();
  }
  //
  // void getMessages() async {
  //   final messages = await _firestore.collection('messages').get();
  //   for (var message in messages.docs) {
  //     print(message.data());
  //     // // // print('\n');
  //     // print(message);
  //   }
  // }

  // void messageStream() async {
  //   await for (var snapshots in _firestore.collection('messages').snapshots()) {
  //     for (var message in snapshots.docs) {
  //       print(message.data());
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                // messageStream();

                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': _auth.currentUser!.email,
                        "time": DateTime.now()
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  const MessagesStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent,
              ),
            );
          }
          final messages = snapshot.data!.docs.reversed;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages) {
            final messageText = (message.data() as dynamic)['text'];
            final messageSender = (message.data() as dynamic)['sender'];
            final messageTime = (message.data() as dynamic)["time"];
            final currentUser = loggedInUserEmail;

            if (currentUser == messageSender) {
              //Edit
            }

            final messageBubble = MessageBubble(
              sender: messageSender,
              text: messageText,
              time: messageTime,
              isMe: currentUser == messageSender,
            );
            messageBubbles.add(messageBubble);
            messageBubbles.sort((a, b) => b.time.compareTo(a.time));
          }

          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              children: messageBubbles,
            ),
          );
        });
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble(
      {required this.sender,
      required this.text,
      required this.isMe,
      required this.time});

  final String sender;
  final String text;
  final Timestamp time;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  )
                : BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    topRight: Radius.circular(30.0)),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Text(
                '$text',
                style: TextStyle(
                    fontSize: 15.0,
                    color: isMe ? Colors.white : Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
