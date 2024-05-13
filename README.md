## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 15.0.

For more information about Little Go's features have a look at its [App Store page](https://apps.apple.com/us/app/little-go/id490753989?ls=1). A user manual is also available, both within the app (in the "Help" UI area when you launch the app) and [online](https://littlego-usermanual.herzbube.ch/).

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go bugfix release 2.0.1. It contains a fix for a bug that caused the app and Fuego to become out of sync when a game with handicap was started, or when a game with black or white setup stones was loaded from the archive (#430).

The previous release was the Little Go feature release 2.0.0. A selection of the most important changes are:

- The app now has support for game variations (#380). A new tree view was added at the bottom of the Play tab that displays the tree of nodes formed by all variations of the game. New game variations can be created by going back to an older node and playing a move - the app will automatically insert a new game variation. Finally, a number of new settings were added under "Settings > Tree view" and "Settings > Game variation".
- The user manual has been rewritten from scratch, complete with icons, illustrations, a few animatons and hyperlinks. Besides the in-app version of the user manual there is now also an identical [online version](https://littlego-usermanual.herzbube.ch/). Many thanks go to Andreas Fischlin who gave me the impetus to take on this long overdue task.
- Support for iOS 9 up to 14 has been dropped (#409). The minimum required version is now iOS 15.0. This cut is not as bad as it may seem at first glance because even the newest devices that are now no longer supported are quite old - the newest of these devices were released by Apple 10 years ago, and were discontinued 7-8 years ago.

As usual a number of bugs have also been fixed, although most of them are rather obscure and/or not very impactful.

The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you should clone the GitHub source code repository. Downloading just the latest release snapshot of the source code is not sufficient because the 3rdparty software build depends on [CocoaPods](https://cocoapods.org/) and Git submodules. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](https://littlego.herzbube.ch/)
* [App Store page](https://apps.apple.com/us/app/little-go/id490753989?ls=1)
* [User manual](https://littlego-usermanual.herzbube.ch/)
* [This Open Hub page](https://www.openhub.net/p/littlego) provides mildly interesting source code statistics
