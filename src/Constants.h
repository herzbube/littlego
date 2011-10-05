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
///
/// @note It's important to have two states that distinguish the color of the
/// stone placed on the GoPoint. Two states allow for efficient comparison
/// whether two GoPoints have the potential to belong to the same GoBoardRegion.
enum GoStoneState
{
  NoStone,     ///< @brief There is no stone on the GoPoint.
  BlackStone,  ///< @brief There is a black stone on the GoPoint.
  WhiteStone   ///< @brief There is a white stone on the GoPoint.
};

/// @brief Enumerates the possible types of GoGame objects.
enum GoGameType
{
  ComputerVsHumanGame,     ///< @brief A computer and a human player play against each other.
  ComputerVsComputerGame,  ///< @brief Two computer players play against each other.
  HumanVsHumanGame         ///< @brief Two human players play against each other.
};

/// @brief Enumerates the possible states of a GoGame.
enum GoGameState
{
  GameHasNotYetStarted,  ///< @brief Denotes a new game that is ready to begin.
  GameHasStarted,        ///< @brief Denotes a game that has started and has at least 1 GoMove.
  GameIsPaused,          ///< @brief Denotes a computer vs. computer game that is paused.
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
  BoardSizeMax = BoardSize19,
  BoardSizeUndefined
};
/// @brief Default board size that should be used if no sensible user default
/// is available.
extern const enum GoBoardSize gDefaultBoardSize;

/// @brief Enumerates the types of alert views used across the application.
///
/// Enumeration values are used as UIView tags so that an alert view delegate
/// that manages several alert views knows how to distinguish between them.
enum AlertViewType
{
  GameHasEndedAlertView,
  NewGameAlertView,
  SaveGameAlertView,
  RenameGameAlertView,
  LoadGameFailedAlertView,
  UndoMoveFailedAlertView
};

/// @brief Enumerates the types of buttons used by the various alert views in
/// #AlertViewType.
enum AlertViewButtonType
{
  OkAlertViewButton = 0,  ///< @brief Used as the single button in a simple alert view
  NoAlertViewButton = 0,  ///< @brief Used as the "cancel" button in a Yes/No alert view
  YesAlertViewButton = 1  ///< @brief Used as the first "other" button in a Yes/No alert view
};

/// @brief Enumerates the supported sort criteria on the Archive view.
enum ArchiveSortCriteria
{
  FileNameArchiveSort,
  FileDateArchiveSort
};

// -----------------------------------------------------------------------------
/// @name Filesystem related constants
// -----------------------------------------------------------------------------
//@{
/// @brief Simple file name that violates none of the GTP protocol restrictions
/// for file names. Is used for the "loadsgf" and "savesgf" GTP commands.
extern NSString* sgfTemporaryFileName;
/// @brief Name of the .sgf file used for backup/restore when the app goes
// to/returns from the background. The file is stored in the Library folder.
extern NSString* sgfBackupFileName;
//@}

// -----------------------------------------------------------------------------
/// @name Table cell constants
// -----------------------------------------------------------------------------
//@{
extern const int cellContentDistanceFromEdgeHorizontal;
extern const int cellContentDistanceFromEdgeVertical;
// Spacing between UI elements
extern const int cellContentSpacingHorizontal;
extern const int cellContentSpacingVertical;
// UI elements sizes
extern const int cellContentLabelHeight;
extern const int cellContentSliderHeight;
//@}

// -----------------------------------------------------------------------------
/// @name GTP notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent just before a command is submitted to the GTP engine. The
/// GtpCommand instance that is submitted is associated with the notification.
///
/// @attention This notification may be delivered in a secondary thread.
extern NSString* gtpCommandWillBeSubmittedNotification;
/// @brief Is sent after a response is received from the GTP engine. The
/// GtpResponse instance that was received is associated with the notification.
extern NSString* gtpResponseWasReceivedNotification;
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
/// @name Archive related notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent to indicate that the current game has been saved and a
/// corresponding .sgf file has been placed in the archive. An NSString instance
/// with the .sgf filename is associated with the notification.
extern NSString* gameSavedToArchive;
/// @brief Is sent to indicate that a game has been loaded from an .sgf file in
/// the archive. An NSString instance with the .sgf filename is associated with
/// the notification.
extern NSString* gameLoadedFromArchive;
/// @brief Is sent to indicate that something about the content of the archive
/// has changed (e.g. an .sgf file has been added, removed, renamed etc.).
extern NSString* archiveContentChanged;
//@}

// -----------------------------------------------------------------------------
/// @name GTP log related notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent to indicate that the something about the content of the
/// GTP log has changed (e.g. a new GtpLogItem has been added, the log has
/// been cleared, the log has rotated).
extern NSString* gtpLogContentChanged;
/// @brief Is sent to indicate that the information stored in a GtpLogItem
/// object has changed. The GtpLogItem object is associated with the
/// notification.
extern NSString* gtpLogItemChanged;
//@}

// -----------------------------------------------------------------------------
/// @name GTP engine settings default values
///
/// @brief See GtpEngineSettings for attribute documentation.
// -----------------------------------------------------------------------------
//@{
extern const int fuegoMaxMemoryMinimum;
extern const int fuegoMaxMemoryMaximum;
extern const int fuegoMaxMemoryDefault;
extern const int fuegoThreadCountMinimum;
extern const int fuegoThreadCountMaximum;
extern const int fuegoThreadCountDefault;
extern const bool fuegoPonderingDefault;
extern const bool fuegoReuseSubtreeDefault;
//@}

// -----------------------------------------------------------------------------
/// @name Debug view settings default values
// -----------------------------------------------------------------------------
//@{
extern const int gtpLogSizeMinimum;
extern const int gtpLogSizeMaximum;
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
// Play view settings
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
// New game settings
extern NSString* newGameKey;
extern NSString* boardSizeKey;
extern NSString* blackPlayerKey;
extern NSString* whitePlayerKey;
extern NSString* handicapKey;
extern NSString* komiKey;
// Players
extern NSString* playerListKey;
extern NSString* uuidKey;
extern NSString* nameKey;
extern NSString* isHumanKey;
extern NSString* statisticsKey;
extern NSString* gamesPlayedKey;
extern NSString* gamesWonKey;
extern NSString* gamesLostKey;
extern NSString* gamesTiedKey;
extern NSString* starPointsKey;
// GTP engine settings
extern NSString* gtpEngineSettingsKey;
extern NSString* fuegoMaxMemoryKey;
extern NSString* fuegoThreadCountKey;
extern NSString* fuegoPonderingKey;
extern NSString* fuegoReuseSubtreeKey;
// Archive view settings
extern NSString* archiveViewKey;
extern NSString* sortCriteriaKey;
extern NSString* sortAscendingKey;
// Debug view settings
extern NSString* debugViewKey;
extern NSString* gtpLogSizeKey;
extern NSString* gtpLogViewFrontSideIsVisibleKey;
//@}
