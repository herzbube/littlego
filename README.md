## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 5.0.

For more information about Little Go's features have a look at its [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8). A manual is also available on the "Help" tab when you launch the app.

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go bugfix release 0.11.1. The following evil bugs have been squashed:

* Board position can no longer be changed while other commands are executed (#156). This hard-to-find bug caused numerous crashes (e.g. those described by issues #128 and #129) and other problems, such as the infamous "The computer played an illegal move." alert. Many thanks to Logan Bouia and Carole Wolf for emailing me bug reports that helped me with diagnosing the problem.
* The entire game is now saved when an old board position is viewed (#150)
* The app should no longer crash after receiving a memory warning on iOS 5 while the "Game info", "New game" or "Save game" screens are displayed (#157). Thanks to the anonymous iPad 1 user who patiently reminded me that the issue needs fixing by sending an occasional crash report.
* Fix for a memory leak in TableViewSliderCell (#155)

The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you can either clone the GitHub source code repository, or download the latest release snapshot of the source code. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](http://littlego.herzbube.ch/)
* [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8)
* There is a public [Trello board](https://trello.com/board/little-go/4fd84c295027333d460dcc32) that shows what is currently in the works (don't expect daily updates)
* [This Ohloh page](https://www.ohloh.net/p/littlego) provides mildly interesting source code statistics
