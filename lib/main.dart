// import 'package:connect/screens/auth/login_screen.dart';
import 'package:connect/screens/splash_screen.dart';
import 'package:connect/helper/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

//global object for accessing device screen size
late Size mq;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //enter fullscreen
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
// portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((value){
        _initializeFirebase();
        runApp(ChangeNotifierProvider(create:(_)=> ThemeProvider(),
        child: const MyApp()));
      });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Connect',
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light().copyWith(
        appBarTheme: const AppBarTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
          ),
          centerTitle: true,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
          backgroundColor: Colors.blue,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: const AppBarTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          centerTitle: true,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
          backgroundColor: Colors.black,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

_initializeFirebase() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}






// return MaterialApp(
//   title: 'Connect',
//   themeMode: themeProvider.themeMode,
//   theme: ThemeData.light(),
//     darkTheme: ThemeData.dark(),
//     appBarTheme: const AppBarTheme(
//       shape:RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(
//           bottom: Radius.circular(20),
//         ),
//       ) ,
//       centerTitle: true,
//       elevation: 1,
//      iconTheme: IconThemeData(color: Colors.black),
//      titleTextStyle: TextStyle(
//        color: Colors.black,
//        fontSize: 28,
//        fontWeight: FontWeight.w400,
//      ),
//       backgroundColor: Colors.blue,
//     ),
//   home: const SplashScreen(),
// );