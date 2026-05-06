## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 16.0.

For more information about Little Go's features have a look at its [App Store page](https://apps.apple.com/us/app/little-go/id490753989?ls=1). A user manual is also available, both within the app (in the "Help" UI area when you launch the app) and [online](https://littlego-usermanual.herzbube.ch/).

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go feature release 2.1.0. A selection of the most important changes are:

- The app now supports time-based play (#29). The default mode to play Go in this app is without any time limit. If you like, however, you can now give yourself (and your opponent) a limited amount of time to make your moves. You can read all about the details of this feature in the user manual under "Playing the game > Timed play" ([link to the online manual](https://littlego-usermanual.herzbube.ch/playing-the-game/timed-play/)).
- The app now has full support for recording the game result for the game's main variation (#414). The app automatically sets the result when the game ends, but the user can override the automatically determined result in the Game Info screen. You can read all about the details of this feature in the user manual under "Playing the game > The game result" ([link to online manual](https://littlego-usermanual.herzbube.ch/playing-the-game/game-result/)). Thanks go to user Deionus for requesting this feature.
- The app now supports entering 18 different so-called "Game Info" items (#384). These are pieces of information that describe various aspects of the game being played, such as the dates when the game was played, player names, player ranks, the location where the game was played, etc.. You can read all about the details of this feature in the user manual under "Other features > Game info screen > The "Info" tab" ([link to online manual](https://littlego-usermanual.herzbube.ch/other-features/game-info-screen/#the-info-tab)).
- The app now supports Multitasking on iPad devices (#304 and #435), i.e. Stage Manager (added by Apple in iOS 16) and Windowed Apps (added by Apple in iOS 26). The implementation is "best effort" only - for instance, if you make the app window too small it will stop being useful.
- The touch area size of several buttons has been increased (#441), notably for the buttons with which to navigate back and forth between the nodes of the current game variation. Thanks go to Merlin Faidherbe for requesting this improvement.
- Support for iOS 15 has been dropped (#437). The minimum required version is now iOS 16.0.

As usual there were other changes and bugfixes. The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you should clone the GitHub source code repository. Downloading just the latest release snapshot of the source code is not sufficient because the 3rdparty software build depends on [CocoaPods](https://cocoapods.org/) and Git submodules. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](https://littlego.herzbube.ch/)
* [App Store page](https://apps.apple.com/us/app/little-go/id490753989?ls=1)
* [User manual](https://littlego-usermanual.herzbube.ch/)
* [This Open Hub page](https://www.openhub.net/p/littlego) provides mildly interesting source code statistics
