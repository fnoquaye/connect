import 'dart:developer';
import 'package:connect/APIs/apis.dart';
import 'package:connect/screens/blocked_user_screen.dart';
import 'package:connect/screens/profile_screen.dart';
import 'package:connect/screens/reports_screen.dart';
import 'package:connect/screens/requests_screen.dart';
import 'package:connect/screens/user_profile_screen.dart';
import 'package:connect/widgets/chat_user_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/chat_user.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //for storing all users
 List<ChatUser> _list = [];

 //for storing searched items
 final List<ChatUser> _searchlist = [];

 //for storing search status
 bool _isSearching = false;


 @override
  void initState() {
    super.initState();
    APIS.getSelfInfo();
  }


  @override
  Widget build(BuildContext context) {
   log('building HomeScreen');
    return GestureDetector(
      //keyboard hiding on tap
      onTap: () => FocusScope.of(context).unfocus(),
        //search button back call logic
        child: PopScope<Object?>(
          canPop: !_isSearching,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            // If pop was blocked (didPop == false) and _isSearching is true:
            if (!didPop && _isSearching) {
              setState(() {
                _isSearching = false;
              });
            } else if (didPop) {
              // Allowed to pop, but you can still handle here if needed
            }
          },
          child: Scaffold(
            //app bar
            appBar: AppBar(
              // home icon
              leading: Icon(CupertinoIcons.home),
          
              title:  _isSearching ? TextField(
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Name,Email,...',
                ),
                autofocus: true,
                style: const TextStyle(
                  fontSize: 17, letterSpacing: 0.5,
                ),
                //when search text changes then update search list
                onChanged: (val){
                  //logic
                  _searchlist.clear();
          
                  for (var i in _list){
                    if(i.name.toLowerCase().contains(val.toLowerCase()) ||
                        i.email.toLowerCase().contains(val.toLowerCase())){
                      _searchlist.add(i);
                    }
                    setState(() {
                      _searchlist;
                    });
                  }
                },
              ) : Text('Connect'),
              actions: [
                //search button
                IconButton(onPressed: (){
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                },
                    icon:  Icon(_isSearching
                    ? CupertinoIcons.clear_circled
                    : Icons.search)),
          
          
                //more features button
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(user: APIS.me),
                          ),
                        );
                        break;
                      case 'blocked':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlockedUserScreen(), // we’ll make this
                          ),
                        );
                        break;
                      case 'reports':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ReportsScreen()), // implement ReportsScreen
                        );
                        break;
                      case 'requests':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RequestsScreen()),
                        );
                        break;
                      case 'logout':
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Sign Out'),
                              ],
                            ),
                            content: const Text('Are you sure you want to sign out from Connect?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context), // Cancel
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  Navigator.pop(context); // Close dialog
                                  // Optional: show progress indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(child: CircularProgressIndicator()),
                                  );
                                  await APIS.signOut(); // Your sign out logic
                                  Navigator.pop(context); // Close progress indicator
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => LoginScreen()),
                                  );
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                        // APIS.signOut();
                        break;
                      case 'incoming':
                        _showRequestsDialog(context, isIncoming: true);
                        break;
                      case 'outgoing':
                        _showRequestsDialog(context, isIncoming: false);
                        break;

                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'profile', child: Text('Profile')),
                    const PopupMenuItem(value: 'blocked', child: Text('Blocked Users')),
                    const PopupMenuItem(value: 'reports', child: Text('Reports')),
                    const PopupMenuItem(value: 'incoming', child: Text('Incoming Requests')),
                    const PopupMenuItem(value: 'outgoing', child: Text('Outgoing Requests')),
                    const PopupMenuItem(value: 'logout', child: Text('Logout')),
                  ],
                ),
          //       IconButton(onPressed: (){
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user:APIS.me)));
          //       }, icon: const Icon(Icons.more_vert)),
              ],
            ),
          
            //new chat button
            floatingActionButton: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                onPressed:(){
                  _showAddUserDialog();
                },
                child: Icon(Icons.add_comment_rounded),

              ),
            ),
          
            body: StreamBuilder(
                // stream: APIS.firestore.collection('users').snapshots(),
                stream: APIS.getMyConnections(),
                builder: (context, snapshot){
                  switch (snapshot.connectionState){
                    //if data is loading
                    case  ConnectionState.waiting:
                    case ConnectionState.none:
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
          
                    //if some or all data is loaded then show it
                    case ConnectionState.active:
                    case ConnectionState.done:
                  // if(snapshot.hasData){
                      final data = snapshot.data?.docs;
                        _list = data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
          
                        if(_list.isNotEmpty){
                          return  ListView.builder(
                              itemCount: _isSearching ? _searchlist.length : _list.length,
                              padding: EdgeInsets.symmetric(vertical: mq.height * 0.001, horizontal: mq.width * 0.005),
                              // padding: EdgeInsets.only(top: mq.height * 0.01),
                              physics: BouncingScrollPhysics(),
                              // padding: EdgeInsets.all(2.0),
                              itemBuilder: (context, index){
                                return ChatUserCard(
                                  user: _isSearching ? _searchlist[index] : _list[index],
                                );
                              }
                          );
                        }else{
                          return const Center(
                            child: Text('No Connections Found\n''Build A new Connection',
                              style: TextStyle(
                                fontSize: 20,
          
                              ),
                            ),
                          );
                        }
                      // for(var i in data!){
                      //   log('Data: ${jsonEncode(i.data())}');
                      //   list.add(i.data()['name']);
                      // }
                    }
          
          
          
                  }
          
          
          )
          ),
        ),

    );
  }

 void _showAddUserDialog() {
   String email = "";

   showDialog(
     context: context,
     builder: (_) => AlertDialog(
       title: const Text("Add User"),
       content: TextField(
         decoration: const InputDecoration(
           hintText: "Enter email address",
         ),
         onChanged: (value) => email = value.trim(),
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.pop(context),
           child: const Text("Cancel"),
         ),
         ElevatedButton(
           onPressed: () async {
             Navigator.pop(context);

             if (email.isNotEmpty) {
               log("🔍 Searching for user with email: $email");

               try {
                 final user = await APIS.getUserByEmail(email);
                 if (user != null) {
                   _showUserOptions(user);
                 } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("No user found with that email")),
                   );
                 }
               } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Error: $e")),
                 );
               }
             }
           },
           child: const Text("Search"),
         ),
       ],
     ),
   );
 }

 void _showUserOptions(ChatUser user) {
   showDialog(
     context: context,
     builder: (_) => AlertDialog(
       title: Text(user.name),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           CircleAvatar(
             radius: 30,
             backgroundImage: NetworkImage(user.image), // assuming you have a photo url
           ),
           const SizedBox(height: 10),
           Text(user.email),
         ],
       ),
       actions: [
         TextButton(
           onPressed: () {
             Navigator.pop(context);
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (_) => UserProfileScreen(user: user),
               ),
             );
           },
           child: const Text("View Profile"),
         ),
         ElevatedButton(
           onPressed: () async {
             Navigator.pop(context);
             await APIS.sendConnectionRequest(user); // implement in APIS
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text("Connection Request Sent To ${user.name}")),
             );
           },
           child: const Text("Send Request"),
         ),
         TextButton(
           onPressed: () {
             Navigator.pop(context);
             APIS.blockUser(user); // implement in APIS
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text("${user.name} has been blocked")),
             );
           },
           child: const Text("Block", style: TextStyle(color: Colors.red)),
         ),
         TextButton(
           onPressed: () {
             Navigator.pop(context);
             APIS.reportUser(user, "Reported from app"); // implement in APIS
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text("${user.name} has been reported")),
             );
           },
           child: const Text("Report", style: TextStyle(color: Colors.red)),
         ),
       ],
     ),
   );
 }

 void _showRequestsDialog(BuildContext context, {required bool isIncoming}) {
   showDialog(
     context: context,
     builder: (_) {
       return AlertDialog(
         title: Text(isIncoming ? "Incoming Requests" : "Outgoing Requests"),
         content: SizedBox(
           width: double.maxFinite,
           height: 400, // scrollable area
           child: StreamBuilder(
             stream: isIncoming
                 ? APIS.getIncomingRequests()
                 : APIS.getOutgoingRequests(),
             builder: (context, snapshot) {
               if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator());
               }

               final data = snapshot.data?.docs ?? [];
               if (data.isEmpty) {
                 return Center(
                   child: Text(isIncoming
                       ? "No incoming requests"
                       : "No outgoing requests"),
                 );
               }

               return ListView.builder(
                 itemCount: data.length,
                 itemBuilder: (context, index) {
                   final user = ChatUser.fromJson(data[index].data());

                   return Padding(
                     padding: const EdgeInsets.symmetric(vertical: 4.0),
                     child: Row(
                       children: [
                         CircleAvatar(
                           backgroundImage: NetworkImage(user.image),
                         ),
                         const SizedBox(width: 10),
                         Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(user.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                 Text(user.email, style: TextStyle(fontSize: 12)),
                               ],
                             )
                         ),
                         if (isIncoming)
                           Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               IconButton(
                                 icon: Icon(Icons.check, color: Colors.green),
                                 onPressed: () async {
                                   await APIS.acceptConnectionRequest(user);
                                   setState(() {});
                                 },
                               ),
                               IconButton(
                                 icon: Icon(Icons.close, color: Colors.red),
                                 onPressed: () async {
                                   await APIS.declineConnectionRequest(user);
                                   setState(() {});
                                 },
                               ),
                             ],
                           )
                   else
                   const Text("Pending"),
                       ],
                     ),
                   );
                 },
               );
             },
           ),
         ),
       );
     },
   );
 }



}

