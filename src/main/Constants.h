// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief An alpha value that can be used to make a view (e.g. the label of a
/// table view cell) appear disabled.
///
/// This is based on
/// http://stackoverflow.com/questions/5905608/how-do-i-make-a-uitableviewcell-appear-disabled
extern const float gDisabledViewAlpha;
/// @brief The alpha value used to draw black influence rectangles.
extern const float gInfluenceColorAlphaBlack;
/// @brief The alpha value used to draw white influence rectangles.
extern const float gInfluenceColorAlphaWhite;
/// @brief The long press gesture recognizer on the Go board must use a small
/// delay so as not to interfere with other gestures (notably the gestures used
/// to scroll and zoom, and on the iPad the swipe gesture of the main
/// UISplitViewController).
extern const CFTimeInterval gGoBoardLongPressDelay;
/// @brief The size of the array #defaultTabOrder.
extern const int arraySizeDefaultTabOrder;
/// @brief The default order in which view controllers should appear in the
/// application's main tab bar controller.
extern const int defaultTabOrder[];
/// @brief The index of the "more" navigation controller within a parent
/// UITabBarController.
///
/// This index has a constant value which was experimentally determined by
/// examining the behaviour of UITabBarController. The value is not documented
/// anywhere in Apple's documentation.
extern const int indexOfMoreNavigationController;

/// @brief Enumerates all types of user interfaces supported by the application.
/// A user interface type encompasses all layouts in all orientations that are
/// possible for that user interface type.
///
/// Before this enumeration existed, the UI idiom was used to distinguish
/// between the main two user interfaces: One UI for the iPhone, one UI for the
/// iPad. With the iPhone 6 Plus a new iPhone device appeared which was capable
/// of supporting a landscape-oriented UI, so the UI idiom was no longer
/// sufficient. Also, it was impossible to just display the iPad UI on the
/// iPhone 6 Plus layout, so a third UI type needed to be created. Using an
/// enumeration allows to support an open-ended number of UI layouts.
enum UIType
{
  /// @brief Portrait-only user interface, used on devices whose UI idiom is
  /// UIUserInterfaceIdiomPhone.
  UITypePhonePortraitOnly,
  /// @brief User interface that can be laid out both in portrait and landscape,
  /// used on devices whose UI idiom is UIUserInterfaceIdiomPhone.
  UITypePhone,
  /// @brief User interface that can be laid out both in portrait and landscape,
  /// used on devices whose UI idiom is UIUserInterfaceIdiomPad.
  UITypePad,
};

/// @brief Enumerates game-related actions that the user can trigger in the UI.
enum GameAction
{
  /// @brief Generates a "Pass" move for the human player whose turn it
  /// currently is.
  GameActionPass,
  /// @brief Discards the current board position and all positions that follow
  /// afterwards.
  GameActionDiscardBoardPosition,
  /// @brief Causes the computer player to generate a move, either for itself or
  /// on behalf of the human player whose turn it currently is.
  GameActionComputerPlay,
  /// @brief Pauses the game in a computer vs. computer game.
  GameActionPause,
  /// @brief Continues the game if it is paused in a computer vs. computer game.
  GameActionContinue,
  /// @brief Interrupts the computer while it is thinking (e.g. when calculating
  /// its next move).
  GameActionInterrupt,
  /// @brief Starts scoring mode.
  GameActionScoringStart,
  /// @brief Ends the currently active scoring mode and returns to normal play
  /// mode.
  GameActionScoringDone,
  /// @brief Displays the "Game Info" view with information about the game in
  /// progress.
  GameActionGameInfo,
  /// @brief Displays an action sheet with additional game actions.
  GameActionMoreGameActions,
  /// @brief Pseudo game action, used as the starting value during a for-loop.
  GameActionFirst = GameActionPass,
  /// @brief Pseudo game action, used as the end value during a for-loop.
  GameActionLast = GameActionMoreGameActions
};

/// @brief Enumerates the possible types of mark up to use for inconsistent
/// territory during scoring.
enum InconsistentTerritoryMarkupType
{
  InconsistentTerritoryMarkupTypeDotSymbol,  ///< @brief Mark up territory using a dot symbol
  InconsistentTerritoryMarkupTypeFillColor,  ///< @brief Mark up territory by filling it with a color
  InconsistentTerritoryMarkupTypeNeutral     ///< @brief Don't mark up territory
};

/// @brief Enumerates the main UI areas of the app. These are the areas that
/// the user can navigate to from the main application view controller that is
/// currently in use.
enum UIArea
{
  UIAreaPlay,
  UIAreaSettings,
  UIAreaArchive,
  UIAreaDiagnostics,
  UIAreaHelp,
  UIAreaAbout,
  UIAreaSourceCode,
  UIAreaLicenses,
  UIAreaCredits,
  /// @brief This is a pseudo area that refers to a list of "more UI areas".
  /// The user selects from that list to navigate to an actual area, the one
  /// that he selected. For instance, the "More" navigation controller of the
  /// main tab bar controller, or the menu presented by the main navigation
  /// controller.m
  UIAreaNavigation,
  UIAreaUnknown = -1,
  UIAreaDefault = UIAreaPlay
};

/// @brief Enumerates the types of alert views used across the application.
///
/// Enumeration values are used as UIView tags so that an alert view delegate
/// that manages several alert views knows how to distinguish between them.
enum AlertViewType
{
  AlertViewTypeGameHasEnded,
  AlertViewTypeNewGame,
  AlertViewTypeSaveGame,
  AlertViewTypeRenameGame,
  AlertViewTypeLoadGameFailed,
  AlertViewTypeSaveGameFailed,
  AlertViewTypeUndoMoveFailed,
  AlertViewTypeAddToCannedCommands,
  AlertViewTypeMemoryWarning,
  AlertViewTypeCannotSendEmail,
  AlertViewTypeDiagnosticsInformationFileGenerated,
  AlertViewTypeDiagnosticsInformationFileNotGenerated,
  AlertViewTypeComputerPlayedIllegalMoveLoggingEnabled,
  AlertViewTypeComputerPlayedIllegalMoveLoggingDisabled,
  AlertViewTypeNewGameAfterComputerPlayedIllegalMove,
  AlertViewTypeActionWillDiscardAllFutureMoves,
  AlertViewTypeHandleDocumentInteractionCommandSucceeded,
  AlertViewTypeHandleDocumentInteractionCommandFailed,
  AlertViewTypeMaxMemoryConfirmation,
  AlertViewTypeDeleteAllGamesConfirmation,
  AlertViewTypeResetPlayersProfilesConfirmation,
  AlertViewTypeResetPlayersProfilesDiscardGameConfirmation,
  AlertViewTypePlayMoveRejectedLoggingEnabled,
  AlertViewTypePlayMoveRejectedLoggingDisabled,
  AlertViewTypeSelectSideToPlay
};

/// @brief Enumerates the types of buttons used by the various alert views in
/// #AlertViewType.
enum AlertViewButtonType
{
  AlertViewButtonTypeOk = 0,   ///< @brief Used as the single button in a simple alert view
  AlertViewButtonTypeNo = 0,   ///< @brief Used as the "cancel" button in a Yes/No alert view
  AlertViewButtonTypeYes = 1,  ///< @brief Used as the first "other" button in a Yes/No alert view
  AlertViewButtonTypeNonAlternatingColor = 0,
  AlertViewButtonTypeAlternatingColor = 1
};

/// @brief Enumerates the types of information that the Info view can display.
enum InfoType
{
  ScoreInfoType,
  GameInfoType,
  BoardInfoType
};

/// @brief Enumerates the axis' displayed around the Go board. "A1" is in the
/// lower-left corner of the Go board.
enum CoordinateLabelAxis
{
  ///@ brief The axis that displays letters. This is the horizontal axis.
  CoordinateLabelAxisLetter,
  ///@ brief The axis that displays numbers. This is the vertical axis.
  CoordinateLabelAxisNumber
};

/// @brief Enumerates all possible styles how to mark up territory.
enum TerritoryMarkupStyle
{
  TerritoryMarkupStyleBlack,
  TerritoryMarkupStyleWhite,
  TerritoryMarkupStyleInconsistentFillColor,
  TerritoryMarkupStyleInconsistentDotSymbol
};
//@}

// -----------------------------------------------------------------------------
/// @name Logging constants
// -----------------------------------------------------------------------------
//@{
/// @brief The log level used by the application. This is always set to the
/// highest possible value. Whether or not logging is actually enabled is a user
/// preference that can be changed at runtime from within the application. If
/// logging is enabled the log output goes to a DDFileLogger with default
/// values.
extern const DDLogLevel ddLogLevel;
//@}

// -----------------------------------------------------------------------------
/// @name Go constants
// -----------------------------------------------------------------------------
//@{
/// @brief Enumerates possible types of GoMove objects.
enum GoMoveType
{
  GoMoveTypePlay,   ///< @brief The player played a stone in this move.
  GoMoveTypePass    ///< @brief The player passed in this move.
};

/// @brief Enumerates colors in Go. The values from this enumeration can be
/// attributed to various things: stones, players, points, moves, etc.
enum GoColor
{
  GoColorNone,   ///< @brief Used, among other things, to say that a GoPoint is empty and has no stone placed on it.
  GoColorBlack,
  GoColorWhite
};

/// @brief Enumerates the possible types of GoGame objects.
enum GoGameType
{
  GoGameTypeUnknown,             ///< @brief Unknown game type.
  GoGameTypeComputerVsHuman,     ///< @brief A computer and a human player play against each other.
  GoGameTypeComputerVsComputer,  ///< @brief Two computer players play against each other.
  GoGameTypeHumanVsHuman         ///< @brief Two human players play against each other.
};

/// @brief Enumerates the possible states of a GoGame.
enum GoGameState
{
  GoGameStateGameHasStarted,        ///< @brief Denotes a game that has not yet ended, and is not paused.
  GoGameStateGameIsPaused,          ///< @brief Denotes a computer vs. computer game that is paused.
  GoGameStateGameHasEnded           ///< @brief Denotes a game that has ended, no moves can be played anymore.
};

/// @brief Enumerates the possible reasons why a GoGame has reached the state
/// #GoGameStateGameHasEnded.
enum GoGameHasEndedReason
{
  GoGameHasEndedReasonNotYetEnded,   ///< @brief The game has not yet ended.
  GoGameHasEndedReasonTwoPasses,     ///< @brief The game ended due to two consecutive pass moves. This
                                     ///  occurs only if #GoLifeAndDeathSettlingRuleTwoPasses is active.
  GoGameHasEndedReasonThreePasses,   ///< @brief The game ended due to three consecutive pass moves. This
                                     ///  occurs only if #GoLifeAndDeathSettlingRuleThreePasses is active.
  GoGameHasEndedReasonFourPasses,    ///< @brief The game ended due to four consecutive pass moves. This
                                     ///  occurs only if #GoFourPassesRuleFourPassesEndTheGame is active.
  GoGameHasEndedReasonResigned,      ///< @brief The game ended due to one of the players resigning.
  GoGameHasEndedReasonTimeExceeded   ///< @brief The game ended due to one of the players having no time left.
};

/// @brief Enumerates the possible results of a game that has reached the state
/// #GoGameStateGameHasEnded.
enum GoGameResult
{
  GoGameResultNone,         ///< @brief The game has not been decided yet, usually because the game has not yet ended.
  GoGameResultBlackHasWon,  ///< @brief Black has won the game.
  GoGameResultWhiteHasWon,  ///< @brief White has won the game.
  GoGameResultTie           ///< @brief The game is a tie.
};

/// @brief Enumerates the possible reasons why a GoGame's isComputerThinking
/// property is true.
enum GoGameComputerIsThinkingReason
{
  GoGameComputerIsThinkingReasonIsNotThinking,   ///< @brief The isComputerThinking property is currently false.
  GoGameComputerIsThinkingReasonComputerPlay,    ///< @brief The computer is thinking about a game move.
  GoGameComputerIsThinkingReasonPlayerInfluence  ///< @brief The computer is calculating player influence.
};

/// @brief Enumerates the possible reasons why playing at a given intersection
/// can be illegal.
enum GoMoveIsIllegalReason
{
  GoMoveIsIllegalReasonIntersectionOccupied,
  GoMoveIsIllegalReasonSuicide,
  GoMoveIsIllegalReasonSimpleKo,
  GoMoveIsIllegalReasonSuperko,  // don't distinguish between superko variants
  GoMoveIsIllegalReasonUnknown
};

/// @brief Enumerates the possible directions one can take to get from one
/// GoPoint to another neighbouring GoPoint.
enum GoBoardDirection
{
  GoBoardDirectionLeft,     ///< @brief Used for navigating to the left neighbour of a GoPoint.
  GoBoardDirectionRight,    ///< @brief Used for navigating to the right neighbour of a GoPoint.
  GoBoardDirectionUp,       ///< @brief Used for navigating to the neighbour that is above a GoPoint.
  GoBoardDirectionDown,     ///< @brief Used for navigating to the neighbour that is below a GoPoint.
  GoBoardDirectionNext,     ///< @brief Used for iterating all GoPoints. The first point is always A1, on a 19x19 board the last point is T19.
  GoBoardDirectionPrevious  ///< @brief Same as #GoBoardDirectionNext, but for iterating backwards.
};

/// @brief Enumerates the supported board sizes.
enum GoBoardSize
{
  GoBoardSize7 = 7,
  GoBoardSize9 = 9,
  GoBoardSize11 = 11,
  GoBoardSize13 = 13,
  GoBoardSize15 = 15,
  GoBoardSize17 = 17,
  GoBoardSize19 = 19,
  GoBoardSizeMin = GoBoardSize7,
  GoBoardSizeMax = GoBoardSize19,
  GoBoardSizeUndefined = 0
};

/// @brief Enumerates the 4 corners of the Go board.
enum GoBoardCorner
{
  GoBoardCornerBottomLeft,   ///< @brief A1 on all board sizes
  GoBoardCornerBottomRight,  ///< @brief T1 on a 19x19 board
  GoBoardCornerTopLeft,      ///< @brief A19 on a 19x19 board
  GoBoardCornerTopRight      ///< @brief T19 on a 19x19 board
};

/// @brief Enumerates the possible ko rules.
enum GoKoRule
{
  GoKoRuleSimple,              ///< @brief The traditional simple ko rule.
  GoKoRuleSuperkoPositional,   ///< @brief Positional superko, i.e. a board position may not be repeated over the entire game span.
  GoKoRuleSuperkoSituational,  ///< @brief Situtational superko, i.e. a player may not repeat his/her own board positions over the entire game span.
  GoKoRuleMax = GoKoRuleSuperkoSituational,
  GoKoRuleDefault = GoKoRuleSimple
};

/// @brief Enumerates the possible scoring systems.
enum GoScoringSystem
{
  GoScoringSystemAreaScoring,
  GoScoringSystemTerritoryScoring,
  GoScoringSystemMax = GoScoringSystemTerritoryScoring,
};

/// @brief Enumerates the rules how the game can proceed from normal game play
/// to the life & death settling phase.
enum GoLifeAndDeathSettlingRule
{
  GoLifeAndDeathSettlingRuleTwoPasses,     ///< @brief The game proceeds to the life & death settling phase after two pass moves.
  GoLifeAndDeathSettlingRuleThreePasses,   ///< @brief The game proceeds to the life & death settling phase after three pass moves. This is used to implement IGS rules.
  GoLifeAndDeathSettlingRuleMax = GoLifeAndDeathSettlingRuleThreePasses,
  GoLifeAndDeathSettlingRuleDefault = GoLifeAndDeathSettlingRuleTwoPasses,
};

/// @brief Enumerates the rules how play proceeds when the game is resumed to
/// resolve disputes that arose during the life & death settling phase.
enum GoDisputeResolutionRule
{
  GoDisputeResolutionRuleAlternatingPlay,      ///< @brief The game is resumed, alternating play is enforced.
  GoDisputeResolutionRuleNonAlternatingPlay,   ///< @brief The game is resumed, alternating play is not enforced.
  GoDisputeResolutionRuleMax = GoDisputeResolutionRuleNonAlternatingPlay,
  GoDisputeResolutionRuleDefault = GoDisputeResolutionRuleAlternatingPlay,
};

/// @brief Enumerates the rules what four consecutive pass moves mean.
enum GoFourPassesRule
{
  GoFourPassesRuleFourPassesHaveNoSpecialMeaning,   ///< @brief Four consecutive pass moves have no special meaning
  GoFourPassesRuleFourPassesEndTheGame,             ///< @brief Four consecutive pass moves end the game. All stones on the board are deemed alive. This is used to implement AGA rules.
  GoFourPassesRuleMax = GoFourPassesRuleFourPassesEndTheGame,
  GoFourPassesRuleDefault = GoFourPassesRuleFourPassesHaveNoSpecialMeaning,
};

/// @brief Enumerates the states that a stone group can have during scoring.
enum GoStoneGroupState
{
  GoStoneGroupStateUndefined,
  GoStoneGroupStateAlive,
  GoStoneGroupStateDead,
  GoStoneGroupStateSeki
};

/// @brief Enumerates the modes the user can choose to mark stone groups.
enum GoScoreMarkMode
{
  GoScoreMarkModeDead,   ///< @brief Stone groups are marked as dead / alive.
  GoScoreMarkModeSeki    ///< @brief Stone groups are marked as in seki / not in seki
};

/// @brief Enumerates the rulesets that the user can select when he starts a new
/// game. A ruleset is a collection of rules that the user can select as a whole
/// instead of selecting individual rules, thus simplifying the game setup
/// process.
enum GoRuleset
{
  /// @brief The rules of the American Go Association (AGA).
  GoRulesetAGA,
  /// @brief The rules of the Internet Go server (IGS), also known as Pandanet.
  GoRulesetIGS,
  /// @brief The Chinese rules of Weiqi (Go).
  GoRulesetChinese,
  /// @brief The Japanese rules of Go.
  GoRulesetJapanese,
  /// @brief The default rules of the app.
  GoRulesetLittleGo,
  /// @brief A custom ruleset, i.e. any combination of rules that does not match
  /// one of the other values in this enumeration.
  GoRulesetCustom,
  GoRulesetMin = GoRulesetAGA,
  GoRulesetMax = GoRulesetLittleGo,
  GoRulesetDefault = GoRulesetLittleGo
};

extern const enum GoGameType gDefaultGameType;
extern const enum GoBoardSize gDefaultBoardSize;
extern const int gNumberOfBoardSizes;
extern const bool gDefaultComputerPlaysWhite;
extern const int gDefaultHandicap;
extern const enum GoScoringSystem gDefaultScoringSystem;
extern const double gDefaultKomiAreaScoring;
extern const double gDefaultKomiTerritoryScoring;
//@}

// -----------------------------------------------------------------------------
/// @name Application constants
// -----------------------------------------------------------------------------
//@{
/// @brief Enumerates different ways how the application can be launched.
enum ApplicationLaunchMode
{
  ApplicationLaunchModeUnknown,
  ApplicationLaunchModeNormal,      ///< @brief The application was launched normally. Production uses
                                    ///  this mode only.
  ApplicationLaunchModeDiagnostics  ///< @brief The application was launched to diagnose a bug report. This
                                    ///  mode is available only in the simulator.
};
//@}

// -----------------------------------------------------------------------------
/// @name Filesystem related constants
// -----------------------------------------------------------------------------
//@{
/// @brief Simple file name that violates none of the GTP protocol restrictions
/// for file names. Is used for the "loadsgf" and "savesgf" GTP commands.
extern NSString* sgfTemporaryFileName;
/// @brief Name of the primary NSCoding archive file used for backup/restore
/// when the app goes to/returns from the background. The file is stored in the
/// Library folder.
extern NSString* archiveBackupFileName;
/// @brief Name of the secondary .sgf file used for the same purpose as
/// @e archiveBackupFileName.
extern NSString* sgfBackupFileName;
/// @brief Name of the folder used by the document interaction system to pass
/// files into the app. The folder is located in the Documents folder.
extern NSString* inboxFolderName;
//@}

// -----------------------------------------------------------------------------
/// @name GTP notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent just before a command is submitted to the GTP engine. The
/// GtpCommand instance that is submitted is associated with the notification.
///
/// @attention This notification is delivered in a secondary thread.
extern NSString* gtpCommandWillBeSubmittedNotification;
/// @brief Is sent after a response is received from the GTP engine. The
/// GtpResponse instance that was received is associated with the notification.
///
/// @attention This notification is delivered in a secondary thread.
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
/// @brief Is sent to indicate that a new GoGame object is about to be created
/// and and old GoGame object (if one exists) is about to be deallocated.
///
/// This notification is sent while the old GoGame object and its dependent
/// objects (e.g. GoBoard) are still around and fully functional.
///
/// The old GoGame object is associated with the notification.
///
/// @note If this notification is sent during application startup, i.e. the
/// first game is about to be created, the old GoGame object is nil.
///
/// @attention This notification may be delivered in a secondary thread.
extern NSString* goGameWillCreate;
/// @brief Is sent to indicate that a new GoGame object has been created. This
/// notification is sent after the GoGame object and its dependent objects (e.g.
/// GoBoard) have been fully configured.
///
/// The new GoGame object is associated with the notification.
///
/// @attention This notification may be delivered in a secondary thread.
extern NSString* goGameDidCreate;
/// @brief Is sent to indicate that the GoGame state has changed in some way,
/// i.e. the game has been paused or ended.
///
/// The GoGame object is associated with the notification.
extern NSString* goGameStateChanged;
//@}

// -----------------------------------------------------------------------------
/// @name Computer player notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent to indicate that the computer player has started to think
/// about its next move.
///
/// The GoGame object is associated with the notification.
extern NSString* computerPlayerThinkingStarts;
/// @brief Is sent to indicate that the computer player has stopped to think
/// about its next move. Occurs only after the move has actually been made, i.e.
/// any GoGame notifications have already been delivered.
///
/// The GoGame object is associated with the notification.
extern NSString* computerPlayerThinkingStops;
//@}

// -----------------------------------------------------------------------------
/// @name Archive related notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent to indicate that something about the content of the archive
/// has changed (e.g. a game has been added, removed, renamed etc.).
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
/// object has changed.
///
//// The GtpLogItem object is associated with the notification.
extern NSString* gtpLogItemChanged;
//@}

// -----------------------------------------------------------------------------
/// @name Scoring related notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent to indicate that scoring mode has been enabled.
extern NSString* goScoreScoringEnabled;
/// @brief Is sent to indicate that scoring mode has been disabled.
///
/// Is sent before #goGameWillCreate in case a new game is started.
///
/// @attention The two notifications may be delivered on different threads:
/// #goScoreScoringDisabled is always delivered in the main thread, but
/// #goGameWillCreate may be delivered in a secondary thread.
extern NSString* goScoreScoringDisabled;
/// @brief Is sent to indicate that the calculation of a new score is about to
/// start.
///
/// The GoScore object is associated with the notification.
extern NSString* goScoreCalculationStarts;
/// @brief Is sent to indicate that a new score has been calculated and is
/// available for display. Is usually sent after #goScoreCalculationStarts, but
/// there are occasions where #goScoreCalculationEnds is sent alone without a
/// preceding #goScoreCalculationStarts.
///
/// The GoScore object is associated with the notification.
///
/// @note The only known occasion where #goScoreCalculationEnds is sent alone
/// without a preceding #goScoreCalculationStarts is during application launch,
/// after a GoScore object is unarchived. In this scenario no one has initiated
/// a score calculation, so #goScoreCalculationStarts is not sent, but the
/// scoring information is available nonetheless, so #goScoreCalculationEnds
/// must be sent.
extern NSString* goScoreCalculationEnds;
/// @brief Is sent to indicate that querying the GTP engine for an initial set
/// of dead stones is about to start. Is sent after #goScoreCalculationStarts.
extern NSString* askGtpEngineForDeadStonesStarts;
/// @brief Is sent to indicate that querying the GTP engine for an initial set
/// of dead stones has ended. Is sent before #goScoreCalculationEnds.
extern NSString* askGtpEngineForDeadStonesEnds;
//@}

// -----------------------------------------------------------------------------
/// @name Cross-hair related notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent to indicate that the board view is about to display a
/// cross-hair in order to help the user place a stone.
extern NSString* boardViewWillDisplayCrossHair;
/// @brief Is sent to indicate that the board view is about to hide the
/// cross-hair that is currently being displayed.
extern NSString* boardViewWillHideCrossHair;
/// @brief Is sent to indicate that the board view changed the cross-hair,
/// typically to display it at a new intersection. Is sent after
/// #boardViewWillDisplayCrossHair and after #boardViewWillHideCrossHair.
///
/// An NSArray object is associated with the notification that contains
/// information about the new cross-hair location.
///
/// If the NSArray is empty this indicates that the cross-hair is currently not
/// visible because the gesture that drives the cross-hair is currently outside
/// of the board's boundaries. The NSArray is also empty if this is the final
/// notification sent after boardViewWillHideCrossHair.
///
/// If the NSArray is not empty, this indicates that the cross-hair is currently
/// visible. The NSArray in this case contains the following objects:
/// - Object at index position 0: A GoPoint object that identifies the
///   intersection at which the cross-hair is currently displayed.
/// - Object at index position 1: An NSNumber that holds a boolean value,
///   indicating whether a move that would place a stone at the cross-hair
///   intersection would be legal or illegal.
/// - Object at index position 2: An NSNumber that holds an int value that is
///   actually a value from the enumeration #GoMoveIsIllegalReasonUnknown. If
///   placing a stone at the cross-hair intersection would be legal the NSNumber
///   holds the value #GoMoveIsIllegalReasonUnknown, otherwise it holds the
///   actual reason why the move would be illegal.
///
/// Receivers of the notification must process the NSArray immediately because
/// the NSArray may be deallocated, or its content changed, after the
/// notification has been delivered.
extern NSString* boardViewDidChangeCrossHair;
//@}

// -----------------------------------------------------------------------------
/// @name Other notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent when the first of a nested series of long-running actions
/// starts. See LongRunningActionCounter for a detailed discussion of the
/// concept.
extern NSString* longRunningActionStarts;
/// @brief Is sent when the last of a nested series of long-running actions
/// ends. See LongRunningActionCounter for a detailed discussion of the concept.
extern NSString* longRunningActionEnds;
/// @brief Is sent (B-A) times while the current board position in
/// GoBoardPosition changes from A to B. Observers can use this notification to
/// power a progress meter.
extern NSString* boardPositionChangeProgress;
/// @brief Is sent to indicate that players and profiles are about to be reset
/// to their factory defaults. Is sent before #goGameWillCreate.
extern NSString* playersAndProfilesWillReset;
/// @brief Is sent to indicate that players and profiles have been reset to
/// their factory defaults. Is sent after #goGameDidCreate.
extern NSString* playersAndProfilesDidReset;
/// @brief Is sent to indicate that territory statistics in GoPoint objects have
/// been updated.
extern NSString* territoryStatisticsChanged;
//@}

// -----------------------------------------------------------------------------
/// @name Default values for properties that define how the Go board is
/// displayed.
// -----------------------------------------------------------------------------
//@{
extern const float iPhoneMaximumZoomScale;
extern const float iPadMaximumZoomScale;
extern const float moveNumbersPercentageDefault;
extern const bool displayPlayerInfluenceDefault;
extern const bool discardFutureMovesAlertDefault;
extern const bool markNextMoveDefault;
//@}

// -----------------------------------------------------------------------------
/// @name Constants related to the magnifying glass
// -----------------------------------------------------------------------------
//@{
/// @brief Enumerates the different modes when the magnifying glass is enabled.
enum MagnifyingGlassEnableMode
{
  MagnifyingGlassEnableModeAlwaysOn,    ///< @brief The magnifying glass is always on
  MagnifyingGlassEnableModeAlwaysOff,   ///< @brief The magnifying glass is always off
  MagnifyingGlassEnableModeAuto,        ///< @brief The magnifying glass is on if the grid cell size on the board view falls
                                        ///  below the threshold where it is hard to see the cross-hair stone below the finger
  MagnifyingGlassEnableModeDefault = MagnifyingGlassEnableModeAlwaysOn
};

/// @brief Enumerates the different thresholds for
/// #MagnifyingGlassEnableModeAuto
///
/// The numeric values of these enumeration items are compared with the grid
/// cell size on the board view. The unit of the numeric values is points (for
/// drawing in CoreGraphics).
///
/// The size of a toolbar button is roughly 20 points as per Apple's HIG. A
/// fingertip therefore covers at least this area when it touches the screen.
/// However, when the user places a stone he should still be able to slightly
/// see the stone peeking out from under his fingertip. A 50% increase of the
/// standard toolbar button size should be sufficient for our normal use case.
enum MagnifyingGlassAutoThreshold
{
  MagnifyingGlassAutoThresholdLessOften = 25,
  MagnifyingGlassAutoThresholdNormal = 30,
  MagnifyingGlassAutoThresholdMoreOften = 35,
  MagnifyingGlassAutoThresholdDefault = MagnifyingGlassAutoThresholdNormal
};

/// @brief Enumerates the different distances of the magnifying glass from the
/// magnification center.
///
/// The numeric values of these enumeration items are points (for drawing in
/// CoreGraphics).
///
/// The default value has been determined experimentally.
enum MagnifyingGlassDistanceFromMagnificationCenter
{
  MagnifyingGlassDistanceFromMagnificationCenterCloser = 80,
  MagnifyingGlassDistanceFromMagnificationCenterNormal = 100,
  MagnifyingGlassDistanceFromMagnificationCenterFarther = 120,
  MagnifyingGlassDistanceFromMagnificationCenterDefault = MagnifyingGlassDistanceFromMagnificationCenterNormal
};

/// @brief Enumerates the different directions that the magnifying glass can
/// veer towards when it reaches the upper border of the screen.
enum MagnifyingGlassVeerDirection
{
  MagnifyingGlassVeerDirectionLeft,    ///< @brief The magnifying glass veers to the left. Useful if the right hand is used for placing stones.
  MagnifyingGlassVeerDirectionRight,   ///< @brief The magnifying glass veers to the right. Useful if the left hand is used for placing stones.
  MagnifyingGlassVeerDirectionDefault = MagnifyingGlassVeerDirectionLeft   ///< @brief Because most people are right-handed, this is the default.
};

/// @brief Enumerates the different update modes of the magnifying glass.
enum MagnifyingGlassUpdateMode
{
  MagnifyingGlassUpdateModeSmooth,      ///< @brief The magnifying glass updates continuously with the panning gesture. Nicer but requires more CPU.
  MagnifyingGlassUpdateModeCrossHair,   ///< @brief The magnifying glass updates only when the cross-hair intersection changes. Requires less CPU.
  MagnifyingGlassUpdateModeDefault = MagnifyingGlassUpdateModeSmooth
};

extern const CGFloat defaultMagnifyingGlassDimension;
extern const CGFloat defaultMagnifyingGlassMagnification;
//@}

// -----------------------------------------------------------------------------
/// @name GTP engine profile constants
///
/// @brief See GtpEngineProfile for attribute documentation.
// -----------------------------------------------------------------------------
//@{
extern const int minimumPlayingStrength;
extern const int maximumPlayingStrength;
extern const int customPlayingStrength;
extern const int defaultPlayingStrength;
extern const int minimumResignBehaviour;
extern const int maximumResignBehaviour;
extern const int customResignBehaviour;
extern const int defaultResignBehaviour;
extern const int fuegoMaxMemoryMinimum;
extern const int fuegoMaxMemoryDefault;
extern const int fuegoThreadCountMinimum;
extern const int fuegoThreadCountMaximum;
extern const int fuegoThreadCountDefault;
extern const bool fuegoPonderingDefault;
extern const unsigned int fuegoMaxPonderTimeMinimum;
extern const unsigned int fuegoMaxPonderTimeMaximum;
extern const unsigned int fuegoMaxPonderTimeDefault;
extern const bool fuegoReuseSubtreeDefault;
extern const unsigned int fuegoMaxThinkingTimeMinimum;
extern const unsigned int fuegoMaxThinkingTimeMaximum;
extern const unsigned int fuegoMaxThinkingTimeDefault;
extern const unsigned long long fuegoMaxGamesMinimum;
extern const unsigned long long fuegoMaxGamesMaximum;
extern const unsigned long long fuegoMaxGamesDefault;
extern const unsigned long long fuegoMaxGamesPlayingStrength1;
extern const unsigned long long fuegoMaxGamesPlayingStrength2;
extern const unsigned long long fuegoMaxGamesPlayingStrength3;
extern const bool autoSelectFuegoResignMinGamesDefault;
extern const unsigned long long fuegoResignMinGamesDefault;
extern const int arraySizeFuegoResignThresholdDefault;
extern const int fuegoResignThresholdDefault[];
/// @brief The hardcoded UUID of the human vs. human games GTP engine profile.
/// This profile is the fallback profile if no other profile is available or
/// appropriate. The user cannot delete this profile.
extern NSString* fallbackGtpEngineProfileUUID;

/// @brief Enumerates the types of additive knowledge known by the GTP engine.
enum AdditiveKnowledgeType
{
  AdditiveKnowledgeTypeNone,
  AdditiveKnowledgeTypeGreenpeep,
  AdditiveKnowledgeTypeRulebased,
  AdditiveKnowledgeTypeBoth  ///< @brief Both = AdditiveKnowledgeTypeGreenpeep and AdditiveKnowledgeTypeRulebased
};
//@}

// -----------------------------------------------------------------------------
/// @name Archive view constants
// -----------------------------------------------------------------------------
//@{
extern NSString* sgfMimeType;
extern NSString* sgfUTI;
extern NSString* illegalArchiveGameNameCharacters;

/// @brief Enumerates the supported sort criteria on the Archive tab.
enum ArchiveSortCriteria
{
  ArchiveSortCriteriaFileName,
  ArchiveSortCriteriaFileDate
};

/// @brief Enumerates possible results of validating the name of an archived
/// game.
enum ArchiveGameNameValidationResult
{
  ArchiveGameNameValidationResultValid,              ///< @brief The name is valid.
  ArchiveGameNameValidationResultIllegalCharacters,  ///< @brief The name contains illegal characters.
  ArchiveGameNameValidationResultReservedWord        ///< @brief The name consists of a reserved word.
};
//@}

// -----------------------------------------------------------------------------
/// @name Diagnostics view settings default values
// -----------------------------------------------------------------------------
//@{
extern const int gtpLogSizeMinimum;
extern const int gtpLogSizeMaximum;
//@}

// -----------------------------------------------------------------------------
/// @name Bug report constants
// -----------------------------------------------------------------------------
//@{
extern const int bugReportFormatVersion;
/// @brief Name of the diagnostics information file that is attached to the
/// bug report email.
///
/// The file name should relate to the project name because the file is user
/// visible, either as an email attachment or when the user transfers it via
/// iTunes file sharing.
extern NSString* bugReportDiagnosticsInformationFileName;
/// @brief Mime-type used for attaching the diagnostics information file to the
/// bug report email.
extern NSString* bugReportDiagnosticsInformationFileMimeType;
/// @brief Name of the bug report information file that stores the bug report
/// format number, the iOS version and the device type.
extern NSString* bugReportInfoFileName;
/// @brief Name of the bug report file that stores an archive of in-memory
/// objects.
extern NSString* bugReportInMemoryObjectsArchiveFileName;
/// @brief Name of the bug report file that stores user defaults.
extern NSString* bugReportUserDefaultsFileName;
/// @brief Name of the bug report file that stores the current game in .sgf
/// format.
extern NSString* bugReportCurrentGameFileName;
/// @brief Name of the bug report file that stores a screenshot of the views
/// visible in #UIAreaPlay.
extern NSString* bugReportScreenshotFileName;
/// @brief Name of the bug report file that stores a depiction of the board as
/// it is seen by the GTP engine.
extern NSString* bugReportBoardAsSeenByGtpEngineFileName;
/// @brief Name of the .zip archive file that is used to collect the application
/// log files.
extern NSString* bugReportLogsArchiveFileName;
/// @brief Email address of the bug report email recipient.
extern NSString* bugReportEmailRecipient;
/// @brief Subject for the bug report email.
extern NSString* bugReportEmailSubject;
//@}

// -----------------------------------------------------------------------------
/// @name Crash reporting constants
// -----------------------------------------------------------------------------
//@{
extern NSString* fabricAPIKeyResource;
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
extern NSString* MBProgressHUDLicenseDocumentResource;
extern NSString* lumberjackLicenseDocumentResource;
extern NSString* zipkitLicenseDocumentResource;
extern NSString* quincykitLicenseDocumentResource;
extern NSString* plcrashreporterLicenseDocumentResource;
extern NSString* protobufcLicenseDocumentResource;
extern NSString* readmeDocumentResource;
extern NSString* manualDocumentResource;
extern NSString* creditsDocumentResource;
extern NSString* registrationDomainDefaultsResource;
extern NSString* playStoneSoundFileResource;
extern NSString* mainMenuIconResource;
extern NSString* uiAreaPlayIconResource;
extern NSString* uiAreaSettingsIconResource;
extern NSString* uiAreaArchiveIconResource;
extern NSString* uiAreaHelpIconResource;
extern NSString* uiAreaDiagnosticsIconResource;
extern NSString* uiAreaAboutIconResource;
extern NSString* uiAreaSourceCodeIconResource;
extern NSString* uiAreaLicensesIconResource;
extern NSString* uiAreaCreditsIconResource;
extern NSString* computerPlayButtonIconResource;
extern NSString* passButtonIconResource;
extern NSString* discardButtonIconResource;
extern NSString* pauseButtonIconResource;
extern NSString* continueButtonIconResource;
extern NSString* gameInfoButtonIconResource;
extern NSString* interruptButtonIconResource;
extern NSString* scoringStartButtonIconResource;
extern NSString* scoringDoneButtonIconResource;
extern NSString* moreGameActionsButtonIconResource;
extern NSString* forwardButtonIconResource;
extern NSString* forwardToEndButtonIconResource;
extern NSString* backButtonIconResource;
extern NSString* rewindToStartButtonIconResource;
extern NSString* stoneBlackImageResource;
extern NSString* stoneWhiteImageResource;
extern NSString* stoneCrosshairImageResource;
extern NSString* computerVsComputerImageResource;
extern NSString* humanVsComputerImageResource;
extern NSString* humanVsHumanImageResource;
extern NSString* woodenBackgroundImageResource;
extern NSString* bugReportMessageTemplateResource;
//@}

// -----------------------------------------------------------------------------
/// @name Constants (mostly keys) for user defaults
// -----------------------------------------------------------------------------
//@{
// Device-specific suffixes
extern NSString* iPhoneDeviceSuffix;
extern NSString* iPadDeviceSuffix;
// User Defaults versioning
extern NSString* userDefaultsVersionRegistrationDomainKey;
extern NSString* userDefaultsVersionApplicationDomainKey;
// Board view settings
extern NSString* boardViewKey;
extern NSString* markLastMoveKey;
extern NSString* displayCoordinatesKey;
extern NSString* displayPlayerInfluenceKey;
extern NSString* moveNumbersPercentageKey;
extern NSString* playSoundKey;
extern NSString* vibrateKey;
extern NSString* infoTypeLastSelectedKey;
// New game settings
extern NSString* newGameKey;
extern NSString* gameTypeKey;
extern NSString* gameTypeLastSelectedKey;
extern NSString* humanPlayerKey;
extern NSString* computerPlayerKey;
extern NSString* computerPlaysWhiteKey;
extern NSString* humanBlackPlayerKey;
extern NSString* humanWhitePlayerKey;
extern NSString* computerPlayerSelfPlayKey;
extern NSString* boardSizeKey;
extern NSString* handicapKey;
extern NSString* komiKey;
extern NSString* koRuleKey;
extern NSString* scoringSystemKey;
extern NSString* lifeAndDeathSettlingRuleKey;
extern NSString* disputeResolutionRuleKey;
extern NSString* fourPassesRuleKey;
// Players
extern NSString* playerListKey;
extern NSString* playerUUIDKey;
extern NSString* playerNameKey;
extern NSString* isHumanKey;
extern NSString* gtpEngineProfileReferenceKey;
extern NSString* statisticsKey;
extern NSString* gamesPlayedKey;
extern NSString* gamesWonKey;
extern NSString* gamesLostKey;
extern NSString* gamesTiedKey;
extern NSString* starPointsKey;
// GTP engine profiles
extern NSString* gtpEngineProfileListKey;
extern NSString* gtpEngineProfileUUIDKey;
extern NSString* gtpEngineProfileNameKey;
extern NSString* gtpEngineProfileDescriptionKey;
extern NSString* fuegoMaxMemoryKey;
extern NSString* fuegoThreadCountKey;
extern NSString* fuegoPonderingKey;
extern NSString* fuegoMaxPonderTimeKey;
extern NSString* fuegoReuseSubtreeKey;
extern NSString* fuegoMaxThinkingTimeKey;
extern NSString* fuegoMaxGamesKey;
extern NSString* autoSelectFuegoResignMinGamesKey;
extern NSString* fuegoResignMinGamesKey;
extern NSString* fuegoResignThresholdKey;
// GTP engine configuration not related to profiles
extern NSString* additiveKnowledgeMemoryThresholdKey;
// Archive view settings
extern NSString* archiveViewKey;
extern NSString* sortCriteriaKey;
extern NSString* sortAscendingKey;
// GTP Log view settings
extern NSString* gtpLogViewKey;
extern NSString* gtpLogSizeKey;
extern NSString* gtpLogViewFrontSideIsVisibleKey;
// GTP canned commands settings
extern NSString* gtpCannedCommandsKey;
// Scoring settings
extern NSString* scoringKey;
extern NSString* autoScoringAndResumingPlayKey;
extern NSString* askGtpEngineForDeadStonesKey;
extern NSString* markDeadStonesIntelligentlyKey;
extern NSString* inconsistentTerritoryMarkupTypeKey;
extern NSString* scoreMarkModeKey;
// Crash reporting settings
extern NSString* collectCrashDataKey;
extern NSString* automaticReportCrashDataKey;
extern NSString* allowContactCrashDataKey;
extern NSString* contactEmailCrashDataKey;
// Board position settings
extern NSString* boardPositionKey;
extern NSString* discardFutureMovesAlertKey;
extern NSString* markNextMoveKey;
// Logging settings
extern NSString* loggingEnabledKey;
// User interface settings
extern NSString* visibleUIAreaKey;
extern NSString* tabOrderKey;
// Magnifying glass settings
extern NSString* magnifyingGlassEnableModeKey;
extern NSString* magnifyingGlassAutoThresholdKey;
extern NSString* magnifyingGlassVeerDirectionKey;
extern NSString* magnifyingGlassDistanceFromMagnificationCenterKey;
//@}

// -----------------------------------------------------------------------------
/// @name Constants for NSCoding
// -----------------------------------------------------------------------------
//@{
// General constants
extern const int nscodingVersion;
extern NSString* nscodingVersionKey;
// Top-level object keys
extern NSString* nsCodingGoGameKey;
// GoGame keys
extern NSString* goGameTypeKey;
extern NSString* goGameBoardKey;
extern NSString* goGameHandicapPointsKey;
extern NSString* goGameKomiKey;
extern NSString* goGamePlayerBlackKey;
extern NSString* goGamePlayerWhiteKey;
extern NSString* goGameNextMoveColorKey;
extern NSString* goGameAlternatingPlayKey;
extern NSString* goGameMoveModelKey;
extern NSString* goGameStateKey;
extern NSString* goGameReasonForGameHasEndedKey;
extern NSString* goGameReasonForComputerIsThinking;
extern NSString* goGameBoardPositionKey;
extern NSString* goGameRulesKey;
extern NSString* goGameDocumentKey;
extern NSString* goGameScoreKey;
// GoPlayer keys
extern NSString* goPlayerPlayerUUIDKey;
extern NSString* goPlayerIsBlackKey;
// GoMove keys
extern NSString* goMoveTypeKey;
extern NSString* goMovePlayerKey;
extern NSString* goMovePointKey;
extern NSString* goMovePreviousKey;
extern NSString* goMoveNextKey;
extern NSString* goMoveCapturedStonesKey;
extern NSString* goMoveMoveNumberKey;
// GoMoveModel keys
extern NSString* goMoveModelGameKey;
extern NSString* goMoveModelMoveListKey;
extern NSString* goMoveModelNumberOfMovesKey;
// GoBoardPosition keys
extern NSString* goBoardPositionGameKey;
extern NSString* goBoardPositionCurrentBoardPositionKey;
extern NSString* goBoardPositionNumberOfBoardPositionsKey;
// GoBoard keys
extern NSString* goBoardSizeKey;
extern NSString* goBoardVertexDictKey;
extern NSString* goBoardStarPointsKey;
// GoBoardRegion keys
extern NSString* goBoardRegionPointsKey;
extern NSString* goBoardRegionScoringModeKey;
extern NSString* goBoardRegionTerritoryColorKey;
extern NSString* goBoardRegionTerritoryInconsistencyFoundKey;
extern NSString* goBoardRegionStoneGroupStateKey;
extern NSString* goBoardRegionCachedSizeKey;
extern NSString* goBoardRegionCachedIsStoneGroupKey;
extern NSString* goBoardRegionCachedColorKey;
extern NSString* goBoardRegionCachedLibertiesKey;
extern NSString* goBoardRegionCachedAdjacentRegionsKey;
// GoPoint keys
extern NSString* goPointVertexKey;
extern NSString* goPointBoardKey;
extern NSString* goPointIsStarPointKey;
extern NSString* goPointStoneStateKey;
extern NSString* goPointTerritoryStatisticsScoreKey;
extern NSString* goPointRegionKey;
// GoScore keys
extern NSString* goScoreScoringEnabledKey;
extern NSString* goScoreMarkModeKey;
extern NSString* goScoreKomiKey;
extern NSString* goScoreCapturedByBlackKey;
extern NSString* goScoreCapturedByWhiteKey;
extern NSString* goScoreDeadBlackKey;
extern NSString* goScoreDeadWhiteKey;
extern NSString* goScoreTerritoryBlackKey;
extern NSString* goScoreTerritoryWhiteKey;
extern NSString* goScoreAliveBlackKey;
extern NSString* goScoreAliveWhiteKey;
extern NSString* goScoreHandicapCompensationBlackKey;
extern NSString* goScoreHandicapCompensationWhiteKey;
extern NSString* goScoreTotalScoreBlackKey;
extern NSString* goScoreTotalScoreWhiteKey;
extern NSString* goScoreResultKey;
extern NSString* goScoreNumberOfMovesKey;
extern NSString* goScoreStonesPlayedByBlackKey;
extern NSString* goScoreStonesPlayedByWhiteKey;
extern NSString* goScorePassesPlayedByBlackKey;
extern NSString* goScorePassesPlayedByWhiteKey;
extern NSString* goScoreGameKey;
extern NSString* goScoreDidAskGtpEngineForDeadStonesKey;
extern NSString* goScoreLastCalculationHadErrorKey;
// GtpLogItem keys
extern NSString* gtpLogItemCommandStringKey;
extern NSString* gtpLogItemTimeStampKey;
extern NSString* gtpLogItemHasResponseKey;
extern NSString* gtpLogItemResponseStatusKey;
extern NSString* gtpLogItemParsedResponseStringKey;
extern NSString* gtpLogItemRawResponseStringKey;
// GoGameDocument keys
extern NSString* goGameDocumentDirtyKey;
extern NSString* goGameDocumentDocumentNameKey;
// GoGameRules keys
extern NSString* goGameRulesKoRuleKey;
extern NSString* goGameRulesScoringSystemKey;
extern NSString* goGameRulesLifeAndDeathSettlingRuleKey;
extern NSString* goGameRulesDisputeResolutionRuleKey;
extern NSString* goGameRulesFourPassesRuleKey;
//@}
