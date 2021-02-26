## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 9.0.

For more information about Little Go's features have a look at its [App Store page](https://apps.apple.com/us/app/little-go/id490753989?ls=1). A manual is also available in the "Help" UI area when you launch the app.

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go feature release 1.6.0. A selection of the most important changes are:

- Addition of an SGF parser (#112). Little Go can now read and write SGF data on its own without having to delegate this task to Fuego (the built-in computer player library). The core piece of software is SGFC, the SGF Syntax Checker & Converter. A big thank you to Arno Hollosi for writing this tool and making it available under a free license, and also for helping with integrating it into Little Go.
- The user interface has been adapted to newer iOS devices with a sensor notch, rounded corners and/or a Home indicator instead of a Home button (#336).
- When Little Go is newly installed from the App Store the default computer player is now weaker (#358). This should give more users a positive first app experience. Users who want a challenge can still increase the difficulty by switching to a stronger computer player. A side effect of this change is that the default computer player no longer uses the "Pondering" setting, which means that the iOS device's battery should now be used up a lot less.
- The project has received its first code contribution! Thanks to Dan Hassin for making a user interface improvement (#346) and improving the project's software build (cf. pull rquests on GitHub) so that it now works out of the box for new contributors.

A number of bugs have also been fixed, among them three app crashes (#357, #361 and #362) and a major regression (#359).

The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you should clone the GitHub source code repository. Downloading just the latest release snapshot of the source code is not sufficient because the 3rdparty software build depends on [CocoaPods](https://cocoapods.org/) and Git submodules. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](https://littlego.herzbube.ch/)
* [App Store page](https://apps.apple.com/us/app/little-go/id490753989?ls=1)
* [This Open Hub page](https://www.openhub.net/p/littlego) provides mildly interesting source code statistics
