Folder "7x7"
------------
SGF files in this folder contain games on a 7x7 board.

All SGF files in this folder are referenced in the TESTING document.


Folder "9x9"
------------
SGF files in this folder contain games on a 9x9 board.

All SGF files in this folder except for the following are referenced in the
TESTING document.

9x9_2.sgf
- This SGF file is used to prepare screenshots of the app in the App Store.
  See NOTES.Marketing for details.

annotations.sgf
- This SGF file is handcrafted and contains all variants of SGF node annotation
  and move annotation properties. The file can be used to demonstrate/test how
  the app handles these properties.

Anonymous vs. Fuego 1.sgf
- This SGF file is used to prepare screenshots of the app in the App Store.
  See NOTES.Marketing for details.

game_050.sgf
- This SGF file is used to prepare screenshots of the app in the App Store.
  See NOTES.Marketing for details.

gameinfo.sgf
- This SGF file is handcrafted and contains all variants of SGF game info
  properties. The file can be used to demonstrate/test how the app handles
  these properties.
- The SGF file also contains multiple game trees with alternative game results.
  This can be used to demonstrate/test what the app displays when an SGF file
  with multiple game trees is selected on the Archive tab.


Folder "19x19"
--------------
SGF files in this folder contain games on a 19x19 board.

All SGF files in this folder except for the following are referenced in the
TESTING document.

Fuego vs. Fuego.sgf
- The SGF file is used to prepare screenshots of the app in the App Store.
  See NOTES.Marketing for details.

markup.sgf
- This SGF file is handcrafted and contains all variants of SGF markup
  properties. The file can be used to demonstrate/test how the app handles
  these properties.

pu2-gokifu-20110910-Melkisheva_Anastasia-Shikshina_Svetlana.sgf
- This SGF file contains a real-world game from the Russian Women's Championship
  2011. The file contains a number of SGF game info properties but is not
  notable otherwise.


Folder "25x25"
--------------
SGF files in this folder contain games on a 25x25 board.

All SGF files in this folder are referenced in the TESTING document.


Folder "Famous games"
---------------------
SGF files in this folder contain notable games of Go history.
Reference: https://en.wikipedia.org/wiki/List_of_Go_games

Blood-vomiting game.sgf
- The blood-vomiting game is a famous game of Go of the Edo period of Japan,
  played on June 27, 1835, between Hon'inbō Jōwa (white) and Akaboshi Intetsu
  (black).
- This SGF file is used to prepare screenshots of the app in the App Store.
  See NOTES.Marketing for details.
- This SGF file also contains annotations and markup that are useful to
  demonstrate/test these features in the app.
- References
  - https://en.wikipedia.org/wiki/Blood-vomiting_game
  - https://senseis.xmp.net/?BloodVomitingGame

Ear-reddening game.sgf
- The ear-reddening game is a game of go of the Edo period of Japan, played on
  September 11, 1846 between Honinbo Shusaku (black) and Inoue Genan Inseki
  (white).
- This SGF file is used to prepare screenshots of the app in the App Store.
  See NOTES.Marketing for details.
- References
  - https://en.wikipedia.org/wiki/Ear-reddening_game
  - https://senseis.xmp.net/?EarReddeningMove

Lee's Broken Ladder Game.sgf
- This game was played between Lee Sedol and Hong Chang-sik during the
  2003 KAT cup, on 23 April 2003.
- A screenshot of this game is the main representation of the app in the
  App Store, first because a ladder formation of Go stones is visually
  characteristic, and second because people with Go knowledge might recognize
  the position/game. See NOTES.Marketing for details.
- References
  - https://en.wikipedia.org/wiki/Lee_Sedol#Lee's_Broken_Ladder_Game
  - https://senseis.xmp.net/?LeeSedolHongChangSikLadderGame


Folder "Illegal games"
---------------------
SGF files in this folder cannot be loaded by the app for various reasons
(illegal SGF content, illegal play due to violating some game rule, content
that violates some limitation of the app, etc.).

All SGF files in this folder are referenced in the TESTING document.


Folder "sgfc"
-------------
SGF files in this folder are copies from the SGFC project. The files are
duplicated in this project for convenient access.

ff4_ex.sgf
- A general SGF FF[4] example file.
- This file uses all sorts of properties, including variations.
- SGFC can process this file without any warnings.
- https://www.red-bean.com/sgf/examples/

ff4_ex-rewritten-by-sgfc.sgf
- The file ff4_ex.sgf after passing it through SGFC

print1.sgf
print2.sgf
- These are print example files that make use of properties for storing print
  and layout information.
- https://www.red-bean.com/sgf/examples/

test-strict.sgf
test.sgf 
test-reorder.sgf
- These are files from the SGFC BitBucket repository (folder "test").
- test-strict.sgf is an SGF file that strictly conforms to the SGF standard.
  SGFC can process this file without any warnings.
- test-reorder.sgf is also processed by SGFC without any warnings. I haven't
  analyzed its content yet.
- test.sgf is an "evil" SGF file that contains a lot of errors. It is used to
  test all messages of SGFC.
