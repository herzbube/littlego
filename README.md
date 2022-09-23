## Introduction

Little Go is a free and open source iOS application that lets you play the game of Go on the iPhone or iPad. You can play against another human (on the same device), or against the computer. The computer player is powered by the open source software library [Fuego](http://fuego.sf.net/). The minimum requirement for running the most recent version of Little Go is iOS 9.0.

For more information about Little Go's features have a look at its [App Store page](https://apps.apple.com/us/app/little-go/id490753989?ls=1). A manual is also available in the "Help" UI area when you launch the app.

Little Go is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0) (2.0).


## Changes in this release

This is the Little Go bugfix release 1.7.1. It contains two fixes for bugs that caused the app to crash (#397 and #398).

The previous release was the Little Go feature release 1.7.0. A selection of the most important changes are:

- The app now supports reading and writing of all SGF node annotation and move annotation properties (#339). The app also displays these properties' values and lets you edit them. This means that you can now add a valuation to a move (e.g. good/bad move) and/or to the entire board position (e.g. good position for black/white), designate a board position to be a "hotspot" (e.g. it contains a game-deciding move), annotate a board position with an estimated score, and finally you can add textual notes to a board position. Annotation data is displayed by, and can be edited via, an all-new annotation view.
- The app now supports reading and writing of all SGF markup properties (#349). Except for the DD property (dim parts of the board), the app also displays these properties' values and lets you edit them. This means that you can now mark intersections on the board with 5 different symbols (circle, square, triangle, "X" mark, "selected" symbol), place single-character letter markers or single-digit number markers, place a free-form label text, and finally you can draw arrows or plain lines on the board. The app has an all-new markup editing mode for this (accessible via menu icon) that includes drag & drop support to move around existing markup.
- The general user interface (UI) of Little Go now looks and behaves the same on all device types (#371). This unification of UI layouts became necessary because the effort to support different layouts proved to be too much. Also the unification provided the opportunity to get rid of many behind-the-scenes hacks. The main changes are: 1) Smaller iPhone devices which only support the Portrait orientation UI layout, now display board positions and the navigation buttons differently than before. 2) Larger iPhone devices now display a tab bar when in Landscape orientation (alas, reducing the size of the board). 3) iPad devices now always show board positions when in Portrait orientation, and when in Landscape orientation they display board positions and navigation buttons differently than before.

A number of bugs have also been fixed, among them various speculative fixes for app crashes (#366, #369, #370 and #364) and a painful regression that would sometimes break Ko detection (#372).

The [ChangeLog](doc/ChangeLog) document has more details.


## Getting and building the source code

If you are interested in Little Go as a developer, you should clone the GitHub source code repository. Downloading just the latest release snapshot of the source code is not sufficient because the 3rdparty software build depends on [CocoaPods](https://cocoapods.org/) and Git submodules. Once you have the source code you should start by reading the file [README.developer](doc/README.developer) - the quick-start guide at the top of the file should get you up and running with a minimum amount of hassle.


## Links and resources

* [Project website](https://littlego.herzbube.ch/)
* [App Store page](https://apps.apple.com/us/app/little-go/id490753989?ls=1)
* [This Open Hub page](https://www.openhub.net/p/littlego) provides mildly interesting source code statistics
