# Changelog

## 1.0.0

* Updated ***path_provider*** dependency to ***2.0.8***.
* Updated to Flutter Embedding 2.
* Updated to null safety. Thanks to @albemala.
* Fixes for player state and media controls.

## 0.3.0

* Added audio focus functionality and settings in controller. (#7)
* Added volume control functionality in platform code and in MediaController. (#9 partial, looping is in progress.)
* Updated ***path_provider*** dependency to ***1.6.14***.

## 0.2.1

* Added memory leak fix for iOS. Thanks to @mentalmap

## 0.1.9

* Fixed swift kCMTimeZero crash. Changed kCMTimeZero to CMTime.zero. (Thanks to @ngocdtph03070) 
* Updated path_provider dependency.

## 0.1.8

* Added an ExoPlayer controller for Android. This option can be 
set when creating the widget.

## 0.1.4

* Improved Android dispose mechanism.
* Added controller dispose method.
* Fixes in temp file lifecycle.

## 0.1.3

* Removed flutter.jar dependency in build.gradle

## 0.1.2

* Added a better description in pubspec.yaml

## 0.1.1

* Removed conflicting file in iOS folder

## 0.1.0

* Widget to play videos.
* Media controls widget.
* Callbacks to control the state of the player.
* Use of platform view to display the player in each platform.
