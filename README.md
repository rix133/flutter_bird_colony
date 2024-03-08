# Bird Colony Management App

Bird Colony Management is a Flutter application for managing seabird colonies.
It uses Firebase as its backend. In essence, the app allows users to manage nests, birds, eggs, 
and experiments, and view basic statistics related to ringing. The app also includes a map
feature for viewing nests on a map and creating nests from the map. The app is designed to be
used by researchers and conservationists working with seabirds.

## Features

- Nest management: Create, edit, and list nests.
- Bird management: Add, edit, and list birds.
- Egg management: Add and edit eggs.
- Experiment management: Add, edit, and list experiments.
- Statistics: View basic ringing statistics related to nests.
- Map: View nests on a map and create nests from the map.
- Export Data: Export data to an Excel file.
- User management: Sign in and out, and manage users.

## Getting started

If you want to try out the app, you can download the app from the Google Play Store. Setting up
for use with your colony requires a bit more work and some knowledge of Flutter and Firebase 
will be helpful. The setup process is described below. It's a one-time process and once set up
the app can be used to manage your colony without understanding the details of the setup.

### Setting up the app

To get started with the app install flutter and the flutter command line tools. You can find
instructions for installing flutter [here](https://flutter.dev/docs/get-started/install).
Then clone the repository and run  `flutter pub get` to install the dependencies.
Next, create a Firebase project and add  the `google-services.json` file to the `android/app` directory.
You will also need the `firebase_options.dart` file in the `lib` directory. To generate the `firebase_options.dart` 
file the firebase command line tools can be used. See the 
[firebase documentation](https://firebase.flutter.dev/docs/overview) for more information. 

## Dependencies

The app uses the following dependencies:

- `geolocator`
- `firebase_core`
- `cloud_firestore`
- `firebase_auth`
- `google_sign_in`
- `google_maps_flutter`
- `flutter_compass`
- `shared_preferences`
- `provider`
- `flutter_colorpicker`
- `intl`
- `path`
- `share_plus`
- `path_provider`
- `excel`

## Tests

The app includes a number of test cases to ensure its functionality. Run the tests using the `flutter test` command.

## Contributing

Contributions are welcome! Clone the repository and create a pull request with your changes.

## Issues

If you encounter any issues with the app or have a feature request, please create an issue on the repository.

## Authors

 See to commit history for a list of authors.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

