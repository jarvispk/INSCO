import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

final storageRef = FirebaseStorage.instance.ref();
final postsRef = FirebaseFirestore.instance.collection("gallery");

class Upload extends StatefulWidget {
  Upload({Key key}) : super(key: key);

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();

  handleChooseFromGallery() async {
    file = File(await ImagePicker.pickImage(source: ImageSource.gallery)
        .then((pickedFile) => pickedFile.path));
    setState(() {
      this.file = file;
      print('file piclked');
    });
  }


  clearImage() {
    setState(() {
      file = null;
    });
  }

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask =
        storageRef.child("gallery/post_$postId.jpg").putFile(imageFile);
    TaskSnapshot storageSnap =
        await uploadTask.whenComplete(() => debugPrint('task completed'));
    // TaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore(
      {String mediaUrl, String location, String description}) {
    postsRef.doc(postId).set({
      "postId": postId,
      "mediaUrl": mediaUrl,
      "description": description,
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );
    captionController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
      Future.delayed(const Duration(milliseconds: 250));
      Navigator.pop(context);
    });
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: clearImage),
        title: Text(
          "About Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          GestureDetector(
            onTap: file == null ? handleChooseFromGallery() : null,
            child: Container(
              child: Icon(Icons.add_a_photo),
            ),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? LinearProgressIndicator() : Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: file == null ? AssetImage("./assets/images/avtar.png") : FileImage(file),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 100.0),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: "Tell about something.....",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          RaisedButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text('Upload'),
          ),
        ],
      ),
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return buildUploadForm();
  }
}




// actions: [GestureDetector(
//            onTap: () async {
//             Authentication authentication = Authentication();
//             await authentication.logoutUser();
//             Navigator.pushAndRemoveUntil<dynamic>(
//               context,
//               MaterialPageRoute<dynamic>(
//                 builder: (BuildContext context) => WelcomePage(),
//               ),
//               (route) =>
//                   false, //if you want to disable back feature set to false
//             );
//             Navigator.push(context,
//                 MaterialPageRoute(builder: (context) => WelcomePage()));
//           },
//           child: Icon(Icons.logout))],