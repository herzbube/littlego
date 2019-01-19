## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 8.1.

For more information about Little Go's features have a look at its [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8). A manual is also available in the "Help" UI area when you launch the app.

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go bugfix release 1.4.1. It contains an important fix for a bug in Fuego that could cause Fuego to play a stone during the opening game on an intersection that was already occupied by a handicap or setup stone (#328). In addition, Little Go's error handling is now capable of dealing with such a situation so that user's are not stuck in a seemingly endless "computer is thinking" loop. Thanks to Rob Wildschut and Mark Spurlock for reporting the issue.

The previous release was the Little Go maintenance and bugfix release 1.4.0. A selection of the most important changes are:

* Added support for loading and saving .sgf files that contain stone and/or player setup nodes (#323). This kind of .sgf files is frequently used for sharing board positions that teach how to play best in certain game situations, or that are puzzles to be solved. Notes:
  * It was already possible to load these .sgf files before the change, but Little Go would not display the stones specified by the stone setup nodes, and playing after loading such an .sgf file would usually result in the alert message "Your move was rejected by Fuego".
  * Even after this change, only those .sgf files are properly handled which contain setup nodes at the beginning of the file. Little Go still cannot properly handle .sgf file that contain setup nodes after the first move is played.
* When playing with area scoring, the Fuego computer player now correctly includes handicap compensation in its score calculation (#319). Before this fix, the Fuego computer player was calculating scores without handicap compensation, which would lead to it resigning (when playing as white) even though it had actually won the game. Or it might not resign (when playing as black) even though it had actually lost the game. This serious bug was reported by dtsudo - thanks a lot!
* The app now synchronizes komi with Fuego when board positions are changed (#324). Up until now the app never synchronized komi. This omission could lead to the following problems:
  * An .sgf file is saved with the wrong komi value in it.
  * Fuego is likely to play wrong moves. For instance, towards the end of the game Fuego might start to pass because it thinks it is winning, or it might resign because it thinks it is losing. The probability of misplays increases when there is a large difference in komi values.
  * These problems would occur only if the user loaded an .sgf file that contained a different komi value than the last game that was started with the "New game" function, and then changed board positions or discarded a move.
* White player influence is now shown correctly with white squares (#317). White player influence was erroneously shown with black squares since the release of version 1.1.0. Thanks for reporting this bug go to ecru86.
* Users that do not have automatic crash reporting enabled are now asked whether they want to submit a crash report (#321). The alert that asks for permission was accidentally disabled since the release of version 1.3.0. Because the alert was disabled, no crash reports were submitted at all unless the user had automatic crash reporting enabled.
* The project has been upgraded to the iOS 12.1 SDK (#314) and Xcode 10.1 (#315)
* Started migration from Twitter Fabric to Google Firebase (#320). A best effort has been made to disable all other Google services and to only keep Crashlytics enabled. **Notably, Firebase Analytics data collection has been explicitly disabled!** An explanatory side note: This technical change has become necessary because in January 2017 Google acquired Fabric/Crashlytics and, after a grace period of 1.5 years, announced in September 2018 that they will discontinue Fabric in favour of the Firebase platform. It's all very complicated, but the main point is that Little Go wants to continue to use the excellent Crashlytics as its crash reporting service, and since that now requires integration with the Firebase platform, Little Go has no choice but to follow Google's lead.

The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you should clone the GitHub source code repository. Downloading just the latest release snapshot of the source code is not sufficient because the 3rdparty software build depends on [CocoaPods](https://cocoapods.org/) and Git submodules. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](http://littlego.herzbube.ch/)
* [App Store page](http://itunes.apple.com/us/app/little-go/id490753989?ls=1&mt=8)
* [This Open Hub page](https://www.openhub.net/p/littlego) provides mildly interesting source code statistics
