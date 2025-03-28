# Bird Colony Management App

[![codecov](https://codecov.io/gh/rix133/flutter_bird_colony/graph/badge.svg?token=nIVX3odUDo)](https://codecov.io/gh/rix133/flutter_bird_colony)
![Tests](https://github.com/rix133/flutter_bird_colony/actions/workflows/codecov.yml/badge.svg)

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

If you want to try out the app you can use the testing colony. You can download and install the app
from  [Google Play Store](https://play.google.com/store/apps/details?id=ee.ut.adapt.flutter_bird_colony)
Alternatively, you can check out the web version of the app
at [Bird Colony](https://managebirdcolony.web.app/). If you want to use the app with your own colony
you can set up the app for your colony.

### Setting up the app

Setting up for use with your colony has two options:

- Write to richard.meitern@ut.ee to have your colony set up. This is the easiest option and once set
  up you can use the Play Store app to manage your colony.
- Set up the app for your colony yourself. This requires a bit more work and some knowledge of
  Flutter and Firebase
  will be helpful. The setup process is described below. It's a one-time process and once set up
  the app can be used to manage your colony without understanding the details of the setup.

To get started with the app install flutter and the flutter command line tools. You can find
instructions for installing [Flutter](https://flutter.dev/docs/get-started/install).
Then clone the repository and run  `flutter pub get` to install the dependencies.
Next, create a Firebase project and add  the `google-services.json` file to the `android/app` directory.
You will also need the `firebase_options.dart` file in the `lib` directory. To generate the `firebase_options.dart`
file the firebase command line tools can be used. See the
[Firebase docs](https://firebase.flutter.dev/docs/overview) for more information.

To run the app you also need to set up the key.properties file in the android directory. The file
should contain
the release key information and the Google Maps API key. The file should look something like this:

``` 
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=PATH_TO_YOUR_RELEASE_KEY_FILE/release-key.jks
MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

You can find more information about setting up the key.properties file
from [Flutter docs](https://docs.flutter.dev/deployment/android).

### Cloud Firestore setup 

Saving to Excel requires you set up a query that requires a COLLECTION_GROUP_ASC index for collection egg and field discover_date. 

For firestore rules we recommend something like this that allows only selected users:
``` 
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if 
      	request.auth != null && exists(/databases/$(database)/documents/users/$(request.auth.token.email));
    }
    // Specific rules for 'users' collection
    match /users/{document=**} {
      allow read, write: if request.auth.uid != null && request.auth != null && (
        request.auth.uid == "gdshgsdhd" || //Admin 1 UID
        request.auth.uid == "gdy454rjg" || //Admin 2 UID
   
        );
    }
  }
}
```

To enable nest photo upload you need to set up Firebase Storage and add the storage rules.

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /nest_images/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```


## Tests

The app includes a number of test cases to ensure its functionality. Run the tests using the `flutter test` command.

## Contributing

Contributions are welcome! Clone the repository and create a pull request with your changes. Once
you are a happy with your changes and all tests pass create a pull request and the changes will be
reviewed.
It is recommended to create an issue before starting work on a new feature or bug fix and define
test case(s) for the new feature or bug fix.

## Issues

If you encounter any issues with the app or have a feature request, please create an issue on the repository.

## Authors

See the contributors in github for a list of authors.

## License

This project will be licensed under the AGPL-3.0 License. See the LICENSE file for details.

