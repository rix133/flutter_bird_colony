import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/homepageButton.dart';
import 'package:flutter_bird_colony/services/authService.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  AuthService _auth = AuthService.instance;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _auth.isUserSignedIn(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true) {
            // User is signed in. Return the home page
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
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
                          HomePageButton(
                              route: '/mapNests',
                              icon: Icons.map_outlined,
                              label: "map",
                              color: Colors.green[800]!,
                              auth: _auth),
                          HomePageButton(
                              route: '/mapCreateNest',
                              icon: Icons.add,
                              label: "add nest",
                              color: Colors.purple[800]!,
                              auth: _auth),
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
                                HomePageButton(
                                    route: "/listDatas",
                                    icon: Icons.science,
                                    label: "data",
                                    color: Colors.blue[700]!,
                                    auth: _auth),
                                HomePageButton(
                                    route: "/statistics",
                                    icon: Icons.bar_chart,
                                    label: "stats",
                                    color: Colors.amber[700]!,
                                    auth: _auth),
                              ],
                            ),
                          ),
                          HomePageButton(
                              route: "/findNest",
                              icon: Icons.search,
                              label: "find nest",
                              color: Colors.red[900]!,
                              auth: _auth),
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
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

