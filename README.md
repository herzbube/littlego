## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 8.1.

For more information about Little Go's features have a look at its [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8). A manual is also available in the "Help" UI area when you launch the app.

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go bugfix release 1.3.1. It contains an important fix for a bug that sometimes caused ko detection to fail when an old board position was viewed (#307). Special thanks go to Manuel Braun for submitting the crucial bug report that finally let me reproduce this long-standing problem, and to all the other patient people who also submitted reports for the same issue.

The previous release was the Little Go technical and bugfix release 1.3.0. A selection of the most important changes are:

* Ko detection now works correctly if an old board position is viewed (#289). Many thanks to Denis Martynov for bringing this to my attention. I promised to release the bugfix "as soon as possible, probably next weekend". This was in June 2015 - over a year ago :-(
* iPad Pro is now supported with its native screen resolution (#297)
* The project has been upgraded to the iOS 9.3 SDK (#298) and Xcode 7.3.1
* Support for iOS 7 has been dropped, the minimum required version is now iOS 8.1 (#260). The only device that is no longer supported is the iPhone 4.

The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you should clone the GitHub source code repository. Downloading just the latest release snapshot of the source code is not sufficient because the 3rdparty software build depends on [CocoaPods](https://cocoapods.org/) and Git submodules. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](http://littlego.herzbube.ch/)
* [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8)
* [This Open Hub page](https://www.openhub.net/p/littlego) provides mildly interesting source code statistics