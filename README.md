## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 7.0.

For more information about Little Go's features have a look at its [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8). A manual is also available in the "Help" UI area when you launch the app.

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go bugfix release 1.1.2. It contains a couple of fixes for potential crashes (#243, #247), one drawing bug (#245) and one regression (#246).

The previous release was the Little Go technical release 1.1.0. A selection of the most important changes are:

* The app's user interface has been updated to the iOS 7 look & feel (#204)
* Drawing for Retina displays has been fixed (#205). Many thanks to Eric O. Lebigot for reporting the issue and giving me the necessary KITB to investigate the problem.
* Memory usage during zooming has been greatly reduced (#212, #214, #215)
* The project has been upgraded to the iOS 7 SDK (#204) and Xcode Xcode 5.1.1
* Support for iOS 6 has been dropped, the minimum required version is now iOS 7.0. Devices that are no longer supported are the iPhone 3GS and the iPod Touch 4th generation.
* Various rarely occurring crashes have been fixed


The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you should clone the GitHub source code repository. Downloading just the latest release snapshot of the source code is not sufficient because the 3rdparty software build depends on the presence of Git submodules. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](http://littlego.herzbube.ch/)
* [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8)
* There is a public [Trello board](https://trello.com/board/little-go/4fd84c295027333d460dcc32) that shows what is currently in the works (don't expect daily updates)
* [This Open Hub page](https://www.openhub.net/p/littlego) provides mildly interesting source code statistics
