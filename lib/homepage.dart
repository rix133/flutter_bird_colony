import 'package:flutter/material.dart';
import 'package:kakrarahu/design/homepageButton.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Future<bool> isUserSignedIn() async {
  // Trigger the authentication flow
  final GoogleSignIn googleSignIn = GoogleSignIn();
  GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
  if (googleUser != null) {return true;};
  return(await googleSignIn.isSignedIn());
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isUserSignedIn(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true) {
            // User is signed in. Return the home page
            return Scaffold(
              appBar: AppBar(
                title: Text('Kakrarahu nests'),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.settings),
                    color: Colors.white,
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
              body: Center(
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 5,
                    ),

                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomePageButton(route: "/map", icon: Icons.map_outlined, label: "map", color: Colors.green[800]!),
                          HomePageButton(route: "/mapforcreate", icon: Icons.add, label: "add new", color: Colors.purple[800]!),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                HomePageButton(route: "/listExperiments", icon: Icons.science, label: "data", color: Colors.blue[700]!),
                                HomePageButton(route: "/statistics", icon: Icons.bar_chart, label: "stats", color: Colors.amber[700]!),
                              ],
                            ),
                          ),
                          HomePageButton(route: "/findNest", icon: Icons.search, label: "find", color: Colors.red[900]!),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            );
          } else {
            // User is not signed in. Redirect to settings page
            WidgetsBinding.instance!.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/settings');
            });
            return Container(); // Return an empty container until navigation completes
          }
        } else {
          // While the connection is not done, you can return a loading spinner or a placeholder widget
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

