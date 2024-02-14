import 'package:flutter/material.dart';

class DataSearch extends SearchDelegate<String> {
  final List<String> items;
  final String hintText;

  DataSearch(this.items, this.hintText)
      : super(
    searchFieldStyle: TextStyle(color: Colors.black87), // Set your desired color here
  );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? items
        : items.where((p) => p.startsWith(query)).toList();

    return ListView.builder(
      itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(5.0),
          child:ListTile(
        onTap: () {
          close(context, suggestionList[index]);
        },
        title: Padding(
          padding: const EdgeInsets.all(5.0),
          child: RichText(
            text: TextSpan(
              text: 'add $hintText: ',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 20, // Increased text size
              ),
              children: [
                TextSpan(
                  text: '${suggestionList[index]}',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 20, // Increased text size
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
      itemCount: suggestionList.length,
    );
  }
}