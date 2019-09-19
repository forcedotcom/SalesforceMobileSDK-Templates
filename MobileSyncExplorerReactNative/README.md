
# MobileSyncExplorerReactNative
MobileSyncExplorer application written using React Native 

## To get started do the following from this directory
``` shell
node ./installios.js (for iOS)
node ./installandroid.js (for Android)
```
## To create the package (e.g. to run on device)
```shell
react-native bundle --platform ios --dev false --entry-file index.js --bundle-output iOS/main.jsbundle
```

## Make sure to run the react-native packager
```shell
npm start (Windows users please use "npm run-script start-windows" instead of npm start)
```

## To run the application on iOS
* Open ios/MobileSyncExplorerReactNative.xcworkspace in XCode

## To run the application on Android
* Open android/ in Android Studio
