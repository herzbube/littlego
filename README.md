## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 7.0.

For more information about Little Go's features have a look at its [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8). A manual is also available in the "Help" UI area when you launch the app.

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go feature release 1.2.0. A selection of the most important changes are:

* iPhone 6/6+ are now supported with their native screen resolution (#263). iPhone 6+ also has a redesigned user interface which supports holding the device in landscape (#253).
* 3 new game rules were added that govern gameplay mechanics at the end of the game. As a consequence, a much wider array of .sgf files can now be loaded from the archive (e.g. files with games that were played on IGS). Thanks to Norbert Langermann for the suggestion that triggered the development of this feature.
* When placing a stone a magnifying glass is now displayed that shows the area of the board that currently under the user's 'fingertip (#271). This feature replaces the old "stone distance from fingertip" feature, which confused and was hated by many users.
* Fuego pondering in human vs. human games has been disabled by default (#281). This saves **a lot** of otherwise wasted battery power. Thanks to Ben Jackson for the suggestion. Unfortunately, a nasty piece of code was required to upgrade existing user preferences, which may result in unnecessary player and profile backup copies cluttering the upgraded preferences. Users will get an alert if this happens so that they can clean up their preferences.
* The app now correctly synchronizes handicap stones with Fuego when board positions are changed (#279). This is the most important bugfix of this release because it fixes another source for the infamous "The computer played an illegal move" and "Your move was rejected by Fuego" alerts. Many thanks to Laurent Guanzini for providing step-by-step instructions that helped me with diagnosing the problem!
* The project has been upgraded to the iOS 8.1 SDK (#248) and Xcode 6.1.1. Also, 64-bit support was added (#249).
* The vector graphics sources (.svg files) for all icons in the app were added to the project and to version control (#264)

The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you should clone the GitHub source code repository. Downloading just the latest release snapshot of the source code is not sufficient because the 3rdparty software build depends on the presence of Git submodules. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](http://littlego.herzbube.ch/)
* [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8)
* [This Open Hub page](https://www.openhub.net/p/littlego) provides mildly interesting source code statistics
* There is a public [Trello board](https://trello.com/board/little-go/4fd84c295027333d460dcc32) that shows what is currently in the works (don't expect daily updates - in fact, since this has fallen somewhat into disuse, don't expect *any* updates at all)
