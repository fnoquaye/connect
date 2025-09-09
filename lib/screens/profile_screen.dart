import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect/APIs/apis.dart';
import 'package:connect/models/languages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
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
  late String _selectedLanguage;
  bool _isUploading = false; // track upload state
  bool _uploadFailed = false;
  File? _lastPickedImage;
  final _formkey = GlobalKey<FormState>();
  String? _image;


  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.user.preferredLanguage ?? 'en';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        //app bar
          appBar: AppBar(
            // leading: Icon(CupertinoIcons.home),
            title: const Text('My Profile'),
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

                        // _buildProfilePicture(),

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
                              GestureDetector(
                                onTap: _showBottomSheet,
                                child: Container(
                                  width: mq.height * 0.2,
                                  height: mq.height * 0.2,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(mq.height * 0.1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26, // subtle shadow
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.blueAccent, // subtle border
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(mq.height * 0.1),
                                    child: _image != null
                                    ? Image.file(File(_image!),fit: BoxFit.cover,)
                                    : CachedNetworkImage(
                                      fit: BoxFit.cover,
                                      imageUrl: widget.user.image,
                                      placeholder: (context, url) => CircularProgressIndicator(),
                                      errorWidget: (context, url, error) => CircleAvatar(child: Icon(CupertinoIcons.person)),
                                    ),
                                  ),
                                ),
                              ),

                              // Overlay for uploading/loading
                              if (_isUploading)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black38,
                                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                                  ),
                                ),


                              // retry button if upload failed
                              if (_uploadFailed)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: IconButton(
                                  icon: Icon(Icons.refresh),
                                  onPressed: (){
                                    // _showBottomSheet();
                                    if (_lastPickedImage != null) {
                                      _uploadToCloudinary(_lastPickedImage!);
                                    }
                                  },
                                ),
                              ),
                            ]),

                        SizedBox(width: mq.width, height: mq.height * 0.03),

                        // User name (large, bold)
                        Text(
                          widget.user.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(width: mq.width, height: mq.height * 0.02),

                        //user email label
                        Text(widget.user.email,
                          style: const TextStyle(fontSize: 14),
                        ),

                        SizedBox(width: mq.width, height: mq.height * 0.04),

                        // // Editable info cards
                        // _buildEditableInfoCard(
                        //   icon: Icons.person,
                        //   title: 'Name',
                        //   initialValue: widget.user.name,
                        //   onSaved: (val) => APIS.me.name = val ?? '',
                        //   validator: (val) => val != null && val.isNotEmpty ? null : 'Required Field',
                        // ),

                        // SizedBox(width: mq.width, height: mq.height * 0.02),


                        // name field
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

                        // _buildEditableInfoCard(
                        //   icon: Icons.info_outline,
                        //   title: 'About',
                        //   initialValue: widget.user.about,
                        //   hintText: 'eg. Feeling Happy',
                        //   onSaved: (val) => APIS.me.about = val ?? '',
                        //   validator: (val) => val != null && val.isNotEmpty ? null : 'Required Field',
                        // ),

                        // about field
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

                        SizedBox(width: mq.width, height: mq.height * 0.04),

                        // // Language selection card
                        // _buildLanguageCard(),

                        DropdownButtonFormField<String>(
                          value: _selectedLanguage,
                          items: LanguageConstants.languageCodes.map((lang) {
                            return DropdownMenuItem(
                              value: lang,
                              child: Text(LanguageConstants.getFullDisplayName(lang)),
                            );
                          }).toList(),
                          onChanged: (newLang) {
                            if (newLang != null) {
                              setState(() => _selectedLanguage = newLang);

                              String languageName = LanguageConstants.getLanguageName(newLang);

                              showDialog(
                                context: context,
                                barrierDismissible: false, // force user to press OK
                                builder: (_) => AlertDialog(
                                  title: Text('Language Changed'),
                                  content: Text(
                                      'You are switching to $languageName. '
                                          'Your next messages are now in $languageName. '
                                          'Your older conversations will remain in the older language for consistency.'
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.language, color: Colors.blue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            label: Text('Preferred Language'),
                          ),
                        ),

                        SizedBox(width: mq.width, height: mq.height * 0.04),

                        //update profile button
                        SizedBox(
                          width: mq.width * 0.8,
                          height: mq.height * 0.08,
                          child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                elevation: 2,
                              ),
                              onPressed: (){
                                if(_formkey.currentState!.validate()){
                                  _formkey.currentState!.save();
                                  APIS.me.preferredLanguage = _selectedLanguage;
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
                              label: const Text('Update Profile',
                                style: TextStyle(fontSize: 18),
                              )),
                        )
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

                              // Upload to Cloudinary
                            _uploadToCloudinary(File(image.path));
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
                            Navigator.pop(context);
                            // Upload to Cloudinary
                            _uploadToCloudinary(File(image.path));

                            }
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

  Future<String?> uploadImageToCloudinary(File image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dfhmxr0iy/image/upload'), // replace <CLOUD_NAME>
      );

      request.fields['upload_preset'] = 'unsigned_preset'; // your unsigned preset
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();
      var resStream = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        var data = json.decode(resStream.body);
        return data['secure_url']; // this is the URL you store in Firestore
      } else {
        print('Cloudinary upload failed: ${resStream.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _uploadToCloudinary(File image) async {
    setState(() {
      _isUploading = true;
      _uploadFailed = false;
      _lastPickedImage = image;
    });

    String? imageUrl = await uploadImageToCloudinary(image);

    if (imageUrl != null) {
      APIS.me.image = imageUrl;
      await APIS.UpdateUserInfo();
      setState(() {
        _image = image.path;
        _isUploading = false;
      });
      Dialogs.showSnackbar(context, 'Profile picture updated');
    } else {
      setState(() {
        _isUploading = false;
        _uploadFailed = true;
      });
      Dialogs.showSnackbar(context, 'Failed to upload image. Tap retry.');
    }
  }



}

// Widget _buildImagePickerOption({required String icon, required String label, required VoidCallback onTap,}) {
//   return GestureDetector(
//     onTap: onTap,
//     child: Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.grey[100],
//             shape: BoxShape.circle,
//             border: Border.all(color: Colors.grey[300]!),
//           ),
//           child: SvgPicture.asset(
//             icon,
//             width: 40,
//             height: 40,
//             // color: Colors.blue,
//           ),
//         ),
//         SizedBox(height: 12),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: Colors.grey[700],
//           ),
//         ),
//       ],
//     ),
//   );
// }






