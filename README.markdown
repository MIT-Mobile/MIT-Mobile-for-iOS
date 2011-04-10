#About the app

MIT Mobile for iPhone is open source software, created and maintained by MIT, and shared under the MIT license. The project includes components from other open source projects which remain under their existing licenses, which are detailed in their respective source files.

MIT Mobile for iPhone is free and available for [download](http://itunes.apple.com/us/app/mit-mobile/id353590319) on the App Store.

Contributions are welcome!

#Building the app

Sensitive information like API keys for Facebook and Twitter are kept within Common/Secret.m. Before building, create your own Secret.m from Secret.m.in.

MIT Mobile for iPhone will build for the iPhone Simulator without any modifications. To build for a device, you must change the `CFBundleIdentifier` in MIT_Mobile-Info.plist from `edu.mit.mitmobile` to your own app id.

#Technical Details

- Base SDK is Latest iPhone OS
- Deployment Target is iPhone OS 4.0

#Feedback

Questions, comments, and feedback are welcome at [iphone-app-feedback@mit.edu](mailto:iphone-app-feedback@mit.edu?subject=MIT Mobile for iPhone on GitHub).

A better README is forthcoming.