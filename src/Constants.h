// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -----------------------------------------------------------------------------


/// @file

// -----------------------------------------------------------------------------
/// @name GUI constants
// -----------------------------------------------------------------------------
//@{
/// @brief The value of this constant should be added to all drawing operations'
/// parameters to prevent anti-aliasing. See README.developer for details.
extern const float gHalfPixel;
//@}

/// @brief Enumerates possible types of GoMove objects.
enum GoMoveType
{
  PlayMove,   ///< @brief The player played a stone in this move.
  PassMove,   ///< @brief The player passed in this move.
  ResignMove  ///< @brief The player resigned in this move.
};

/// @brief Enumerates the possible stone states of a GoPoint.
enum GoStoneState
{
  NoStone,     ///< @brief There is no stone on the GoPoint.
  BlackStone,  ///< @brief There is a black stone on the GoPoint.
  WhiteStone   ///< @brief There is a white stone on the GoPoint.
};

/// @brief Enumerates the possible states of a GoGame.
enum GoGameState
{
  GameHasNotYetStarted,  ///< @brief Denotes a new game that is ready to begin.
  GameHasStarted,        ///< @brief Denotes a game that has started and has at least 1 GoMove.
  GameHasEnded           ///< @brief Denotes a game that has ended, no moves can be played anymore.
};

/// @brief Enumerates the possible directions one can take to get from one
/// GoPoint to another neighbouring GoPoint.
enum GoBoardDirection
{
  LeftDirection,     ///< @brief Used for navigating to the left neighbour of a GoPoint.
  RightDirection,    ///< @brief Used for navigating to the right neighbour of a GoPoint. 
  UpDirection,       ///< @brief Used for navigating to the neighbour that is above a GoPoint.
  DownDirection,     ///< @brief Used for navigating to the neighbour that is below a GoPoint.
  NextDirection,     ///< @brief Used for iterating all GoPoints. The first point is always A1, on a 19x19 board the last point is Q19.
  PreviousDirection  ///< @brief Same as NextDirection, but for iterating backwards.
};

/// @brief Enumerates all existing tabs in the GUI.
///
/// Values in this enumeration must match the "tag" property values of each
/// TabBarItem in MainWindow.xib.
enum TabType
{
  PlayTab,
  SettingsTab,
  ArchiveTab,
  DebugTab,
  AboutTab,
  SourceCodeTab,
  ApacheLicenseTab,
  GPLTab,
  LGPLTab,
  BoostLicenseTab
};

/// @brief Enumerates the supported board sizes.
enum GoBoardSize
{
  BoardSize7,
  BoardSize9,
  BoardSize11,
  BoardSize13,
  BoardSize15,
  BoardSize17,
  BoardSize19,
  BoardSizeMax = BoardSize19
};

// -----------------------------------------------------------------------------
/// @name GTP notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent when a command is submitted to the GTP engine. The GtpCommand
/// instance that is submitted is associated with the notification.
extern NSString* gtpCommandSubmittedNotification;
/// @brief Is sent when a response is received from the GTP engine. The
/// GtpResponse instance that was received is associated with the notification.
extern NSString* gtpResponseReceivedNotification;
/// @brief Is sent to indicate that the GTP engine is no longer idle.
extern NSString* gtpEngineRunningNotification;
/// @brief Is sent to indicate that the GTP engine is idle.
extern NSString* gtpEngineIdleNotification;
//@}

// -----------------------------------------------------------------------------
/// @name GoGame notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent to indicate that a new GoGame has been created.
extern NSString* goGameNewCreated;
/// @brief Is sent to indicate that the GoGame state has changed in some way,
/// i.e. the game has started or ended.
extern NSString* goGameStateChanged;
/// @brief Is sent to indicate that the first move of the game has changed. May
/// occur when the first move of the game is played, or when the first move is
/// removed by an undo.
extern NSString* goGameFirstMoveChanged;
/// @brief Is sent to indicate that the last move of the game has changed. May
/// occur whenever a move is played (including pass and resign), or when the
/// most recent move of the game is removed by an undo.
extern NSString* goGameLastMoveChanged;
/// @brief Is sent to indicate that a new score has been calculated. Typically
/// occurs after the game has ended.
extern NSString* goGameScoreChanged;
//@}

// -----------------------------------------------------------------------------
/// @name Computer player notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent to indicate that the computer player has started to think
/// about its next move.
extern NSString* computerPlayerThinkingStarts;
/// @brief Is sent to indicate that the computer player has stopped to think
/// about its next move.
extern NSString* computerPlayerThinkingStops;
//@}

// -----------------------------------------------------------------------------
/// @name Resource file names
// -----------------------------------------------------------------------------
//@{
extern NSString* openingBookResource;
extern NSString* aboutDocumentResource;
extern NSString* sourceCodeDocumentResource;
extern NSString* apacheLicenseDocumentResource;
extern NSString* GPLDocumentResource;
extern NSString* LGPLDocumentResource;
extern NSString* boostLicenseDocumentResource;
extern NSString* registrationDomainDefaultsResource;
extern NSString* playStoneSoundFileResource;
//@}

// -----------------------------------------------------------------------------
/// @name Keys for user defaults
// -----------------------------------------------------------------------------
//@{
extern NSString* playViewKey;
extern NSString* markLastMoveKey;
extern NSString* displayCoordinatesKey;
extern NSString* displayMoveNumbersKey;
extern NSString* playSoundKey;
extern NSString* vibrateKey;
extern NSString* backgroundColorKey;
extern NSString* boardColorKey;
extern NSString* boardOuterMarginPercentageKey;
extern NSString* boardInnerMarginPercentageKey;
extern NSString* lineColorKey;
extern NSString* boundingLineWidthKey;
extern NSString* normalLineWidthKey;
extern NSString* starPointColorKey;
extern NSString* starPointRadiusKey;
extern NSString* stoneRadiusPercentageKey;
extern NSString* crossHairColorKey;
extern NSString* crossHairPointDistanceFromFingerKey;
extern NSString* newGameKey;
extern NSString* boardSizeKey;
extern NSString* blackPlayerKey;
extern NSString* whitePlayerKey;
extern NSString* handicapKey;
extern NSString* komiKey;
extern NSString* playerListKey;
extern NSString* nameKey;
extern NSString* isHumanKey;
extern NSString* statisticsKey;
extern NSString* gamesPlayedKey;
extern NSString* gamesWonKey;
extern NSString* gamesLostKey;
extern NSString* gamesTiedKey;
extern NSString* starPointsKey;
//@}
