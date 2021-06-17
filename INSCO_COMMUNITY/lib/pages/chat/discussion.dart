import 'package:INSCO_COMMUNITY/pages/chat/chat_constants.dart';
import 'package:INSCO_COMMUNITY/constants/color.dart';
import 'package:INSCO_COMMUNITY/modal/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:INSCO_COMMUNITY/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final _firestore = FirebaseFirestore.instance;

class DiscussionScreen extends StatefulWidget {
  @override
  _DiscussionScreenState createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final messageTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colour.primaryColor,
      appBar: AppBar(
        title: Center(child: Text("Community Discussion")),
        automaticallyImplyLeading: true,
        backgroundColor: Colour.secondaryColor,
        actions: [
          currentUser.title == 'Admin'
              ? GestureDetector(
                  onTap: () {
                    _firestore.collection('messages').get().then((snapshot) {
                      for (DocumentSnapshot ds in snapshot.docs) {
                        ds.reference.delete();
                      }
                    });
                  },
                  child: Container(child: Icon(Icons.clear)))
              : Text('')
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MessageStream(),
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 10.0, top: 5.0, left: 10.0, right: 5.0),
              child: Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        decoration: kMessageContainerDecoration,
                        child: TextField(
                          controller: messageTextController,
                          maxLines: 5,
                          minLines: 1,
                          // style: TextStyle(color: Colors.white),
                          decoration: kMessageTextFieldDecoration,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Container(
                        decoration: kSendButtonDecoration,
                        child: GestureDetector(
                          onTap: () {
                            if (messageTextController.text != '' &&
                                messageTextController.text != null) {
                              final msgPath = _firestore.collection('messages');
                              DocumentReference msgRef = msgPath.doc();
                              msgRef.set({
                                'id': currentUser.id,
                                'sender': currentUser.username,
                                'msg': messageTextController.text,
                                'msgTime': DateTime.now(),
                                'msgId': null,
                                'userPhotoUrl': currentUser.photoUrl,
                                'isVisibal': true,
                              }).whenComplete(
                                  () => msgPath.doc(msgRef.id).update({
                                        'msgId': msgRef.id,
                                      }));
                              messageTextController.clear();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 10.0),
                            child: Icon(Icons.send_sharp,
                                color: Colour.primaryColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("messages")
          .orderBy('msgTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.all(Radius.circular(50.0)),
              color: Colour.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        // final messages = snapshot.data.docs;

        List<MessageBox> messageWidgets = [];
        snapshot.data.docs.forEach((doc) {
          ChatData message = ChatData.fromJson(doc.data());
          MessageBox msgs = MessageBox(message);
          int now = DateTime.now().day;
          if (message.isVisibal) {
            if ((now - message.msgTime.toDate().day) >= 30) {
              FirebaseFirestore.instance
                  .collection('messages')
                  .doc(message.msgId)
                  .update({
                'isVisibal': false,
              });
            } else {
              messageWidgets.add(msgs);
            }
          }
        });
        return Expanded(
          child: ListView(
            reverse: true,
            children: messageWidgets,
          ),
        );
      },
    );
  }
}

class MessageBox extends StatelessWidget {
  final ChatData message;
  MessageBox(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: Column(
        crossAxisAlignment: currentUser.username == message.sender
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          currentUser.username != message.sender
              ? Padding(
                  padding: const EdgeInsets.only(
                      bottom: 3.0, right: 15.0, left: 5.0),
                  child: Text(
                    message.sender,
                    style: GoogleFonts.lato(fontSize: 10.0),
                  ),
                )
              : Text(''),
          Padding(
            padding: currentUser.username == message.sender
                ? EdgeInsets.only(right: 15.0, left: 60.0)
                : EdgeInsets.only(right: 60.0, left: 5.0),
            child: GestureDetector(
              onLongPress: () {
                int timegap =
                    DateTime.now().difference(message.msgTime.toDate()).inMinutes;
                print("timegap is : $timegap");
                if (currentUser.username != message.sender) {
                  if (timegap < 6) {
                    showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                              color: Colour.buttonColor,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  new Wrap(children: <Widget>[
                                    new ListTile(
                                        leading: new Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                        title: new Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        onTap: () {
                                          try {
                                            _firestore
                                                .collection('messages')
                                                .doc(message.msgId)
                                                .delete();
                                            Navigator.pop(context);
                                          } catch (e) {}
                                        })
                                  ]),
                                ],
                              ));
                        });
                  } else {
                    showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height: 50,
                            color: Colour.buttonColor,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Cannot delete post after 5 minutes",
                                  style: TextStyle(color: Colour.primaryColor),
                                ),
                              ),
                            ),
                          );
                        });
                  }
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Material(
                    borderRadius: currentUser.username == message.sender
                        ? BorderRadius.only(
                            topLeft: Radius.circular(30.0),
                            bottomLeft: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0),
                          )
                        : BorderRadius.only(
                            topRight: Radius.circular(30.0),
                            bottomLeft: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0),
                          ),
                    elevation: 5.0,
                    color: currentUser.username == message.sender
                        ? Colour.buttonColor
                        : Colour.tertioryColor,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 15.0),
                        child: Text(
                          message.msg,
                          style: GoogleFonts.lato(
                              color: Colors.white, fontSize: 15.0),
                        )),
                  ),
                  Container(
                    child: currentUser.username == message.sender
                        ? (message.msgId == null
                            ? Icon(Icons.dangerous,
                                color: Colors.red, size: 12.0)
                            : Icon(Icons.check, size: 12.0))
                        : Text(''),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
