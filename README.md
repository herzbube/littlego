## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 5.0.

For more information about Little Go's features have a look at its [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8). A manual is also available on the "Help" tab when you launch the app.

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go feature release 0.12.0. A selection of the most important changes are:

* It is now possible to configure the computer player with a threshold how quickly it will resign a game (#133). For instance, it is now possible to tell the computer player to never resign so that the game can be played out to the very end. This also allows beginners to play with a large handicap on a small board (up until now the computer player would always resign immediately when faced with an overwhelming handicap). The resignation behaviour setting can be found towards the bottom on the "edit profile" screen.
* When an old board position is viewed, the intersection where the next stone will be placed is now marked with the letter "A" (#101). This can be disabled in the "Board position" settings.
* Changes to the active profile are now immediately applied to the GTP engine (#123). For instance, it is now possible to change the playing strength or the resign behaviour of the computer player without starting a new game.
* Loading a game from the archive is now about 10% faster (#166)
* The user interface for changing the dangerous "Max. memory" profile setting is now vastly improved (#153). The maximum value that can be selected for the setting is now limited to a fraction of the device's physical memory, and the amount of physical memory that the device has is also displayed.
* The GTP engine is configured to no longer recognize positional superko (#171). This is a temporary solution to bring the GTP engine's rules into sync with Little Go's rules. Little Go currently does not recognize superko, so this sync'ing fixes the problem that Little Go lets the user make a superko move which is then rejected by the GTP engine. Many thanks to Brid Griffin for emailing me a bug report that helped me with diagnosing this problem! Note that Little Go will officially support superko in 1.0.
* On the iPad, the board size is now correct after the device is rotated while the board is zoomed (#162)
* Dragging a stone outside the zoomed in board section no longer places the stone (#143)


The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you should clone the GitHub source code repository. Downloading just the latest release snapshot of the source code is not sufficient because the 3rdparty software build depends on the presence of Git submodules. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](http://littlego.herzbube.ch/)
* [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8)
* There is a public [Trello board](https://trello.com/board/little-go/4fd84c295027333d460dcc32) that shows what is currently in the works (don't expect daily updates)
* [This Ohloh page](https://www.ohloh.net/p/littlego) provides mildly interesting source code statistics
