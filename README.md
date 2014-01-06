## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 6.1.

For more information about Little Go's features have a look at its [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8). A manual is also available on the "Help" tab when you launch the app.

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go feature release 1.0.0. A selection of the most important changes are:

* When a new game is started, it is now possible to select one of several ko rules. Simple ko remains the default, new choices are positional and situational superko (#169).
* When a new game is started, it is now possible to select whether area or territory scoring should be in effect (#30). Area scoring is the default because the computer player (Fuego) does not properly support territory scoring.
* During scoring it is now possible to mark stones in seki (#190). Tap the "Actions" button to find the menu entry that lets you switch from "mark dead stones" to "mark stones in seki".
* It is now possible to display player influence, aka territory statistics, for an estimate who owns an area (#18). The feature can be enabled under "Settings > Display > Display player influence".
* iOS 7: The app no longer crashes on startup after a game has been imported from an external app such as Mail or DropBox (#184)
* Support for iOS 5 has been dropped, the minimum required version is now iOS 6.1 (#198). Devices that are no longer supported are iPad 1st generation and iPod Touch 3rd generation.
* The project has been upgraded to Xcode 5.0 (#183)
* The 3rd party software build process has been completely rewritten (#92)


The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you should clone the GitHub source code repository. Downloading just the latest release snapshot of the source code is not sufficient because the 3rdparty software build depends on the presence of Git submodules. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](http://littlego.herzbube.ch/)
* [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8)
* There is a public [Trello board](https://trello.com/board/little-go/4fd84c295027333d460dcc32) that shows what is currently in the works (don't expect daily updates)
* [This Ohloh page](https://www.ohloh.net/p/littlego) provides mildly interesting source code statistics
