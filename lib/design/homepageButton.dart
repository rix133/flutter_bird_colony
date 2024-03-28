import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/services/authService.dart';

class HomePageButton extends StatelessWidget {
  final String route;
  final IconData icon;
  final String label;
  final Color color;

  HomePageButton({required this.route, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.instance.isUserSignedIn(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show loading spinner while waiting for future to complete
        } else {
          bool isLoggedIn = snapshot.data ?? false; // Default to false if snapshot.data is null
          return Expanded(
            child: GestureDetector(
              onTap: isLoggedIn ? () {
                Navigator.pushNamed(context, route);
              } : () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Not Logged In', style: TextStyle(color: Colors.redAccent)),
                      content: Text('Please log in to access features.', style: TextStyle(color: Colors.black)),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Go to Settings'),
                          onPressed: () {
                            // pop all and push settings
                            Navigator.pushNamedAndRemoveUntil(context, '/settings', (Route<dynamic> route) => false);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isLoggedIn ? color : Colors.grey,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 70,
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

