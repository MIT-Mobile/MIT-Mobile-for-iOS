#About the app

MIT Mobile for iPhone is the official iPhone app for MIT. It is created and maintained by MIT and shared under the MIT license. The project includes components from other open source projects — their licenses are detailed in their respective source files.

MIT Mobile for Phone is free and available [on the App Store](http://itunes.apple.com/us/app/mit-mobile/id353590319).

Contributions are welcome!

#Building the app

Sensitive information like API keys for Facebook and Twitter are kept within Common/Configuration/Secret.m. If the configuration file does not exist, a default 'Secret.m' will be created the when the app is built (using the 'Secret.m.in' template).

MIT Mobile for iPhone will build for the iPhone Simulator without any modifications. To build for a device, you'll need to change the `CFBundleIdentifier` in MIT_Mobile-Info.plist from `edu.mit.mitmobile` to your own app id.

#Technical Details

- Base SDK is Latest iOS (7.0)
- Deployment Target is iOS 7.0

#Feedback

Questions, comments, and feedback are welcome at [iphone-app-feedback@mit.edu](mailto:iphone-app-feedback@mit.edu?subject=MIT Mobile for iPhone on GitHub).
