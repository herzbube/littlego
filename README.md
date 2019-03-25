## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 8.1.

For more information about Little Go's features have a look at its [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8). A manual is also available in the "Help" UI area when you launch the app.

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go bugfix release 1.5.1. It contains a fix for a bug that causes the app to crash during launch on iOS 9.x and below (#332). Thanks to Li Chen Ke and Dennis for reporting the issue.

The previous release was the Little Go feature release 1.5.0. It adds a single new feature: Board setup mode (#276). When you start a new game, instead of beginning to play you can now switch to board setup mode. In this mode you can place black or white stones in any order and combination to set up the initial board before you begin to play moves. In addition to placing stones, you can select the side which is to play the first move. Read the "Board setup" section in the in-game manual for a detailed feature description.

The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you should clone the GitHub source code repository. Downloading just the latest release snapshot of the source code is not sufficient because the 3rdparty software build depends on [CocoaPods](https://cocoapods.org/) and Git submodules. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](http://littlego.herzbube.ch/)
* [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8)
* [This Open Hub page](https://www.openhub.net/p/littlego) provides mildly interesting source code statistics
