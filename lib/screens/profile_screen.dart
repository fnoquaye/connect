// import 'dart:convert';
// import 'dart:developer';

// import 'package:connect/APIs/apis.dart';
// import 'dart:developer';

import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect/APIs/apis.dart';
import 'package:connect/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../helper/dialogs.dart';
import '../main.dart';
import '../models/chat_user.dart';


//profile screen to show signed in users
class ProfileScreen extends StatefulWidget {
  final ChatUser user;



  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formkey = GlobalKey<FormState>();
  String? _image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        //app bar
          appBar: AppBar(
            // leading: Icon(CupertinoIcons.home),
            title: const Text('Profile'),
            // actions: [
            //   //search button
            //   IconButton(onPressed: (){}, icon: const Icon(Icons.search)),
            //   //more features button
            //   IconButton(onPressed: (){}, icon: const Icon(Icons.more_vert)),
            // ],
          ),



          // Sign Out Button

          floatingActionButton: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.redAccent,
              onPressed:
                  () async {
                    //sign out function
                    Dialogs.showProgressBar(context);
                    await FirebaseAuth.instance.signOut().then((value) async {
                      await GoogleSignIn().signOut().then((value){
                        //hide progress bar
                        Navigator.pop(context);
                        //for moving to home screen
                        Navigator.pop(context);
                        //redirect to loginScreen
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => LoginScreen()));
                      });
                    });
                  },
              label: Text('Sign Out'),
              icon: Icon(Icons.logout),
            ),
          ),

          // BODY!!

          body: Form(
            key: _formkey,
            child: Padding(
              padding:  EdgeInsets.symmetric(horizontal: mq.width * 0.05),
              child: SingleChildScrollView(
                child: ConstrainedBox(constraints: BoxConstraints(minHeight: mq.height),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        //space with sizedbox
                        SizedBox(width: mq.width, height: mq.height * 0.03),
                        //profile picture
                        Stack(
                            children: [
                              //profile picture
                              _image != null ?
                              //local image
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(mq.height * 0.1),
                                  child: Image.file(
                                    File(_image!),
                                    width: mq.height * 0.2,
                                    height: mq.height * 0.2,
                                    fit: BoxFit.cover,
                                  )
                              )
                                  :
                              //image from server
                              ClipRRect(
                                borderRadius: BorderRadius.circular(mq.height * 0.1),
                                child: CachedNetworkImage(
                                  width: mq.height * 0.2,
                                  height: mq.height * 0.2,
                                  fit: BoxFit.cover,
                                  imageUrl: widget.user.image,
                                  placeholder: (context, url) => CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => CircleAvatar(child: Icon(CupertinoIcons.person)),
                                ),
                              ),

                              //edit image button
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: MaterialButton(
                                  elevation: 1,
                                  onPressed: (){
                                    _showBottomSheet();
                                  },
                                  shape: const CircleBorder(),
                                  child: Icon(Icons.edit),
                                  color: Colors.blue,
                                ),
                              ),
                            ]),

                        SizedBox(width: mq.width, height: mq.height * 0.03),

                        //user email label
                        Text(widget.user.email,
                          style: const TextStyle(fontSize: 18),
                        ),

                        SizedBox(width: mq.width, height: mq.height * 0.07),


                        TextFormField(
                          initialValue: widget.user.name,
                          onSaved: (val) => APIS.me.name = val ?? '',
                          validator: (val) => val != null && val.isNotEmpty ? null: 'Required Field',
                          decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person, color: Colors.blue,),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              // hintText: '',
                              label: const Text ('Name')
                          ),
                        ),

                        SizedBox(width: mq.width, height: mq.height * 0.04),


                        TextFormField(
                          initialValue: widget.user.about,
                          onSaved: (val) => APIS.me.about = val ?? '',
                          validator: (val) => val != null && val.isNotEmpty ? null: 'Required Field',
                          decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.info_outline, color: Colors.blue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              hintText: 'eg. Feeling Happy',
                              label: const Text ('About')
                          ),
                        ),

                        SizedBox(width: mq.width, height: mq.height * 0.07),

                        //update profile button
                        ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                minimumSize: Size(mq.width * .7, mq.height * 0.07)
                            ),
                            onPressed: (){
                              if(_formkey.currentState!.validate()){
                                _formkey.currentState!.save();
                                print('Updated name: ${APIS.me.name}');
                                print('Updated about: ${APIS.me.about}');

                                APIS.UpdateUserInfo().then((value){
                                  Dialogs.showSnackbar(context, 'Profile Updated Successfully');
                                }).catchError((e){
                                  print('Update Error: $e');
                                });
                              }
                            },
                            icon: Icon(Icons.edit),
                            label: const Text('Update',
                              style: TextStyle(fontSize: 20),
                            ))
                      ],
                    ),
                  ),
                )

              ),
            ),
          )
      ),
    );
  }
  //bottom sheet for picking a profile picture for user
void _showBottomSheet(){
  showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          )
      ),
      builder: (_){
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(
              top: mq.height * 0.01,
              bottom: mq.height * 0.05),
          children: [
            const Text('Pick Profile Picture',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20)),
            SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                //pick from gallery
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        // elevation: 4,
                      ),
                        onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        //pick an image
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if(image != null){
                            log('Image Path: ${image.path} -- MimeType: ${image.mimeType}');
                            setState(() {
                              _image = image.path;
                            });
                            Navigator.pop(context);

                          }
                        },
                        child: SvgPicture.asset('assets/photos.svg',
                          width: mq.width * 0.2,
                          height: mq.width * 0.2,
                        )
                        ),
                    const SizedBox(height: 8),
                    const Text('Photos'),
                  ],
                ),

                //take new photo
                Column(
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),

                          // elevation: 4,
                        ),
                        onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            //pick an image
                            final XFile? image = await picker.pickImage(source: ImageSource.camera);
                            if(image != null){
                            log('Image Path: ${image.path}');
                            setState(() {
                            _image = image.path;
                            });
                            Navigator.pop(context);}
                            },
                        child: SvgPicture.asset('assets/camera.svg',
                          fit: BoxFit.cover,
                          width: mq.width * 0.2,
                          height: mq.width * 0.2,
                        )
                    ),
                    const SizedBox(height: 8),
                    const Text('camera'),
                  ],
                )
              ],
            )
          ],
        );
      });
}
}






// void _showBottomSheet() {
//   showModalBottomSheet(
//     context: context,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.only(
//         topLeft: Radius.circular(20),
//         topRight: Radius.circular(20),
//       ),
//     ),
//     builder: (_) {
//       return ListView(
//         shrinkWrap: true,
//         padding: const EdgeInsets.symmetric(vertical: 20),
//         children: [
//           const Text(
//             'Pick Profile Picture',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
//           ),
//           const SizedBox(height: 20),
//           ListTile(
//             leading: const Icon(Icons.camera_alt, color: Colors.blue),
//             title: const Text('Camera'),
//             onTap: () async {
//               final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
//               if (pickedFile != null) {
//                 // You can now upload or use the file
//                 print('Picked from camera: ${pickedFile.path}');
//               }
//               Navigator.pop(context); // Close the bottom sheet
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.photo, color: Colors.green),
//             title: const Text('Gallery'),
//             onTap: () async {
//               final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//               if (pickedFile != null) {
//                 // You can now upload or use the file
//                 print('Picked from gallery: ${pickedFile.path}');
//               }
//               Navigator.pop(context); // Close the bottom sheet
//             },
//           ),
//         ],
//       );
//     },
//   );
// }


