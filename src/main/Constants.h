// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
/// https://stackoverflow.com/questions/5905608/how-do-i-make-a-uitableviewcell-appear-disabled
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
  /// @brief Causes the computer player to generate a move suggestion for the
  /// human player whose turn it currently is.
  GameActionComputerSuggestMove,
  /// @brief Pauses the game in a computer vs. computer game.
  GameActionPause,
  /// @brief Continues the game if it is paused in a computer vs. computer game.
  GameActionContinue,
  /// @brief Interrupts the computer while it is thinking (e.g. when calculating
  /// its next move).
  GameActionInterrupt,
  /// @brief Starts scoring mode.
  GameActionScoringStart,
  /// @brief Starts play mode.
  GameActionPlayStart,
  /// @brief Switch the default color for new stones placed during board setup
  /// from black to white. The icon representing this game action is a black
  /// stone icon, indicating the current default color instead of what the game
  /// action actually does.
  GameActionSwitchSetupStoneColorToWhite,
  /// @brief Switch the default color for new stones placed during board setup
  /// from white to black. The icon representing this game action is a white
  /// stone icon, indicating the current default color instead of what the game
  /// action actually does.
  GameActionSwitchSetupStoneColorToBlack,
  /// @brief Discards all board setup stones. Handicap stones remain.
  GameActionDiscardAllSetupStones,
  /// @brief Displays the list of board positions. Used only in #UIAreaPad when
  /// the interface orientation is Portrait.
  GameActionMoves,
  /// @brief Displays the "Game Info" view with information about the game in
  /// progress.
  GameActionGameInfo,
  /// @brief Displays an alert message with additional game actions.
  GameActionMoreGameActions,
  /// @brief Pseudo game action, used as the starting value during a for-loop.
  GameActionFirst = GameActionPass,
  /// @brief Pseudo game action, used as the end value during a for-loop.
  GameActionLast = GameActionMoreGameActions
};

/// @brief Enumerates buttons that are displayed when the user taps the
/// "More Game Actions" button in #UIAreaPlay.
///
/// The order in which buttons are enumerated also defines the order in which
/// they appear in the alert message.
enum MoreGameActionsButton
{
  MoreGameActionsButtonSetupFirstMove,
  MoreGameActionsButtonBoardSetup,
  MoreGameActionsButtonScore,
  MoreGameActionsButtonMarkAsSeki,
  MoreGameActionsButtonMarkAsDead,
  MoreGameActionsButtonUpdatePlayerInfluence,
  MoreGameActionsButtonSetBlackToMove,
  MoreGameActionsButtonSetWhiteToMove,
  MoreGameActionsButtonResumePlay,
  MoreGameActionsButtonResign,
  MoreGameActionsButtonUndoResign,
  MoreGameActionsButtonUndoTimeout,
  MoreGameActionsButtonUndoForfeit,
  MoreGameActionsButtonSaveGame,
  MoreGameActionsButtonNewGame,
  MoreGameActionsButtonNewGameRematch,
  MoreGameActionsButtonCancel,
  MoreGameActionsButtonMax,     ///< @brief Pseudo enum value, used to iterate over the other enum values
};

/// @brief Enumerates buttons used to navigate between board positions.
enum BoardPositionNavigationButton
{
  BoardPositionNavigationButtonRewindToStart,
  BoardPositionNavigationButtonPrevious,
  BoardPositionNavigationButtonNext,
  BoardPositionNavigationButtonForwardToEnd,
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
  UIAreaChangelog,
  /// @brief This is a pseudo area that refers to a list of "more UI areas".
  /// The user selects from that list to navigate to an actual area, the one
  /// that he selected. For instance, the "More" navigation controller of the
  /// main tab bar controller, or the menu presented by the main navigation
  /// controller.
  UIAreaNavigation,
  UIAreaUnknown = -1,
  UIAreaDefault = UIAreaPlay
};

/// @brief Enumerates the possible modes that the "Play" UI area can be in.
enum UIAreaPlayMode
{
  UIAreaPlayModePlay,        ///< @brief The "Play" UI area is in play mode, i.e. the user can play moves.
  UIAreaPlayModeScoring,     ///< @brief The "Play" UI area is in scoring mode.
  UIAreaPlayModeBoardSetup,  ///< @brief The "Play" UI area is in board setup mode. Only possible if no moves have been played yet.
  UIAreaPlayModeTsumego,     ///< @brief The "Play" UI area is in tsumego (problem solving) mode
  UIAreaPlayModeDefault = UIAreaPlayModePlay,
};

/// @brief Enumerates the types of information that the Info view can display.
enum InfoType
{
  ScoreInfoType,
  GameInfoType,
  BoardInfoType
};

/// @brief Enumerates the pages that the Annotation view can display.
enum AnnotationViewPage
{
  ValuationAnnotationViewPage,
  DescriptionAnnotationViewPage
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

/// @brief Enumerates a number of standard alert button types.
enum AlertButtonType
{
  AlertButtonTypeOk,
  AlertButtonTypeYes,
  AlertButtonTypeNo,
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
#ifndef LITTLEGO_UITESTS
extern const DDLogLevel ddLogLevel;
#endif
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
  GoGameHasEndedReasonBlackWinsByResignation, ///< @brief The game ended due to the black player winning by resignation.
  GoGameHasEndedReasonWhiteWinsByResignation, ///< @brief The game ended due to the white player winning by resignation.
  GoGameHasEndedReasonBlackWinsOnTime,        ///< @brief The game ended due to the black player winning on time.
  GoGameHasEndedReasonWhiteWinsOnTime,        ///< @brief The game ended due to the white player winning on time.
  GoGameHasEndedReasonBlackWinsByForfeit,     ///< @brief The game ended due to the black player winning by forfeit.
  GoGameHasEndedReasonWhiteWinsByForfeit,     ///< @brief The game ended due to the white player winning by forfeit.
};

/// @brief Enumerates the possible results of a game that has reached the state
/// #GoGameStateGameHasEnded.
///
/// This enumeration is similar to the enumeration #GoScoreSummary, but due to
/// slight semantic differences the two enumerations are kept separate.
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
  GoGameComputerIsThinkingReasonMoveSuggestion,  ///< @brief The computer is generating a move suggestion.
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

/// @brief Enumerates the possible reasons why setting up a stone at a given
/// intersection can be illegal.
enum GoBoardSetupIsIllegalReason
{
  /// @brief The setup stone to be placed would have no liberties.
  GoBoardSetupIsIllegalReasonSuicideSetupStone,
  /// @brief The setup stone to be placed would connect to a friendly stone
  /// group and take away that stone group's last liberty.
  GoBoardSetupIsIllegalReasonSuicideFriendlyStoneGroup,
  /// @brief The setup stone to be placed would take away all liberties from an
  /// opposing stone group.
  GoBoardSetupIsIllegalReasonSuicideOpposingStoneGroup,
  /// @brief The setup stone to be placed would take away all liberties from a
  /// single opposing stone.
  GoBoardSetupIsIllegalReasonSuicideOpposingStone,
  /// @brief The setup stone to be placed would split up an opposing stone
  /// group and take away all liberties from one of the resulting sub-groups.
  GoBoardSetupIsIllegalReasonSuicideOpposingColorSubgroup,
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

/// @brief Enumerates possible valuations of a position on the Go board.
enum GoBoardPositionValuation
{
  GoBoardPositionValuationNone,               ///< @brief The position is not valuated. Corresponds to the absence of the SGF properties GB, GW, DM and UC.
  GoBoardPositionValuationGoodForBlack,       ///< @brief The position is good for black. Corresponds to the SGF property value GB[1].
  GoBoardPositionValuationVeryGoodForBlack,   ///< @brief The position is very good for black. Corresponds to the SGF property value GB[2].
  GoBoardPositionValuationGoodForWhite,       ///< @brief The position is good for white. Corresponds to the SGF property value GW[1].
  GoBoardPositionValuationVeryGoodForWhite,   ///< @brief The position is very good for white. Corresponds to the SGF property value GW[2].
  GoBoardPositionValuationEven,               ///< @brief The position is even. Corresponds to the SGF property value DM[1].
  GoBoardPositionValuationVeryEven,           ///< @brief The position is very even. Corresponds to the SGF property value DM[2].
  GoBoardPositionValuationUnclear,            ///< @brief The position is unclear. Corresponds to the SGF property value UC[1].
  GoBoardPositionValuationVeryUnclear         ///< @brief The position is very unclear. Corresponds to the SGF property value UC[2].
};

/// @brief Enumerates possible hotspot designations of a position on the Go
/// board.
enum GoBoardPositionHotspotDesignation
{
  GoBoardPositionHotspotDesignationNone,           ///< @brief The position is not a hotspot. Corresponds to the absence of the SGF property HO.
  GoBoardPositionHotspotDesignationYes,            ///< @brief The position is a hotspot, the move that created the position is interesting. Corresponds to the SGF property value HO[1].
  GoBoardPositionHotspotDesignationYesEmphasized   ///< @brief The position is a hotspot, the move that created the position is even more interesting, possibly a game-deciding move. Corresponds to the SGF property value HO[2].
};

/// @brief Enumerates possible valuations of a move.
enum GoMoveValuation
{
  GoMoveValuationNone,              ///< @brief The move is not valuated. Corresponds to the absence of the SGF properties TE, BM, IT and DO.
  GoMoveValuationGood,              ///< @brief The played move is good (tesuji). Corresponds to the SGF property value TE[1].
  GoMoveValuationVeryGood,          ///< @brief The played move is very good (tesuji). Corresponds to the SGF property value TE[2].
  GoMoveValuationBad,               ///< @brief The played move is bad. Corresponds to the SGF property value BM[1].
  GoMoveValuationVeryBad,           ///< @brief The played move is very bad. Corresponds to the SGF property value BM[2].
  GoMoveValuationInteresting,       ///< @brief The played move is interesting. Corresponds to the SGF property value IT[].
  GoMoveValuationDoubtful           ///< @brief The played move is doubtful. Corresponds to the SGF property value DO[].
};

/// @brief Enumerates possible summary scores.
///
/// This enumeration is similar to the enumeration #GoGameResult, but due to
/// slight semantic differences the two enumerations are kept separate.
enum GoScoreSummary
{
  GoScoreSummaryNone,        ///< @brief The score summary is not available. Corresponds to the absence of the SGF property V.
  GoScoreSummaryBlackWins,   ///< @brief The score summary is that black wins. Corresponds to a positive value of the SGF property V.
  GoScoreSummaryWhiteWins,   ///< @brief The score summary is that white wins. Corresponds to a negative value of the SGF property V.
  GoScoreSummaryTie          ///< @brief The score summary is that the game is a tie. Corresponds to value 0 (zero) of the SGF property V.
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
/// @brief Simple but relatively unique file name that violates none of the GTP
/// protocol restrictions for file names. It can be used for the "loadsgf" and
/// "savesgf" GTP commands or for other purposes.
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
/// @brief Is sent to indicate that the computer player has generated a move
/// suggestion for the human player whose turn it currently is.
///
/// A dictionary is associated with the notification that contains the following
/// key/value pairs:
/// - #moveSuggestionColorKey: NSNumber that wraps a GoColor enum value. This
///   indicates the color of the player for which the move suggestion was
///   generated.
/// - #moveSuggestionTypeKey: NSNumber that wraps a MoveSuggestionType enum
///   value. This indicates the type of move suggestion generated by the
///   computer player (e.g. a pass move).
/// - #moveSuggestionPointKey: A GoPoint object that indicates the intersection
///   on which the computer player suggested to play a stone. Is @e nil if the
///   move suggestion type is not #MoveSuggestionTypePlay.
/// - #moveSuggestionErrorMessageKey: An NSString containing an error message
///   that describes the problem if generating the move suggestion failed.
///   Is @e nil if generating the move suggestion succeeded. If not @e nil then
///   the #moveSuggestionTypeKey and #moveSuggestionPointKey values are
///   undefined.
extern NSString* computerPlayerGeneratedMoveSuggestion;
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
/// @brief Is sent to indicate that the mode of the UI area "Play" is about
/// to change. An NSArray object containing to NSNumber objects is associated
/// with the notification. The first NSNumber object contains the old
/// UIAreaPlayMode value, the second NSNumber object the new UIAreaPlayMode
/// value. Receivers of the notification must process the NSArray immediately
/// because the NSArray may be deallocated, or its content changed, after the
/// notification has been delivered.
extern NSString* uiAreaPlayModeWillChange;
/// @brief Is sent to indicate that the mode of the UI area "Play" has changed.
/// An NSArray object containing to NSNumber objects is associated with the
/// notification. The first NSNumber object contains the old UIAreaPlayMode
/// value, the second NSNumber object the new UIAreaPlayMode value. Receivers
/// of the notification must process the NSArray immediately because the NSArray
/// may be deallocated, or its content changed, after the notification has been
/// delivered.
extern NSString* uiAreaPlayModeDidChange;
/// @brief Is sent to indicate that the state of an intersection has changed
/// during board setup. The intersection now has a handicap stone, or a
/// previously set handicap stone has been removed. The GoPoint object that
/// identifies the intersection is associated with the notification.
extern NSString* handicapPointDidChange;
/// @brief Is sent to indicate that the state of an intersection has changed
/// during board setup. The intersection how has a black or white stone, or the
/// color of a previously set setup stone has been changed, or a previously set
/// setup stone has been removed. The GoPoint object that identifies the
/// intersection is associated with the notification.
extern NSString* setupPointDidChange;
/// @brief Is sent to indicate that all setup stones are about to be discarded.
extern NSString* allSetupStonesWillDiscard;
/// @brief Is sent to indicate that all setup stones have been discarded.
extern NSString* allSetupStonesDidDiscard;
/// @brief Is sent before an animation is started on the board view. As a
/// response user interaction should be suspended until the balancing
/// #boardAnimationDidEnd is sent.
extern NSString* boardViewAnimationWillBegin;
/// @brief Is sent after an animation has ended on the board view. This is the
/// balancing notification to #boardAnimationWillBegin.
extern NSString* boardViewAnimationDidEnd;
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
extern const bool discardMyLastMoveDefault;
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
/// @name Computer assistance constants
// -----------------------------------------------------------------------------
//@{
/// @brief Enumerates the possible types of how the computer can assist a human
/// player in making a move.
enum ComputerAssistanceType
{
  ComputerAssistanceTypePlayForMe,    ///< @brief The computer assists by generating an actual move on behalf of the human player whose turn it currently is.
  ComputerAssistanceTypeSuggestMove,  ///< @brief The computer assists by generating a move suggestion for the human player whose turn it currently is.
  ComputerAssistanceTypeNone          ///< @brief The computer provides no assistance.
};

/// @brief Enumerates possible types of move suggestions that the computer
/// player can generate.
enum MoveSuggestionType
{
  MoveSuggestionTypePlay,   ///< @brief The computer player suggests to play a stone.
  MoveSuggestionTypePass,   ///< @brief The computer player suggests to pass.
  MoveSuggestionTypeResign  ///< @brief The computer player suggests to resign.
};

extern NSString* moveSuggestionColorKey;
extern NSString* moveSuggestionTypeKey;
extern NSString* moveSuggestionPointKey;
extern NSString* moveSuggestionErrorMessageKey;
extern const int moveSuggestionAnimationRepeatCount;
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
/// @brief Maximum number of moves that a game can have for it to be loadable.
///
/// The limiting factor is Fuego. The value of this constant is hardcoded to be
/// equal to the limit that is in use in Fuego's GTP engine.
extern const int maximumNumberOfMoves;

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
/// @name SGF constants
// -----------------------------------------------------------------------------
//@{
extern const int minimumSyntaxCheckingLevel;
extern const int maximumSyntaxCheckingLevel;
extern const int defaultSyntaxCheckingLevel;
extern const int customSyntaxCheckingLevel;

/// @brief Enumerates possible encoding modes used to decode SGF content when
/// it is loaded.
enum SgfEncodingMode
{
  /// @brief A single encoding is used to decode all game trees in the entire
  /// SGF content.
  SgfEncodingModeSingleEncoding,
  /// @brief Each game tree in the SGF content is decoded separately with the
  /// encoding specified in the game tree's CA property.
  SgfEncodingModeMultipleEncodings,
  ///< @brief An attempt is made to load the SGF content first with
  /// #SgfEncodingModeSingleEncoding. If that fails a second attempt is made
  /// with #SgfEncodingModeMultipleEncodings.
  SgfcEncodingModeBoth,
  SgfcEncodingModeDefault = SgfEncodingModeSingleEncoding
};

/// @brief Enumerates what types of messages are allowed in order for loading
/// of SGF content to be successful. Loading @e always fails when a fatal error
/// occurs.
enum SgfLoadSuccessType
{
  /// @brief Loading of the SGF content is successful only if loading generates
  /// no warnings and no errors whatsoever.
  SgfLoadSuccessTypeNoWarningsOrErrors,
  /// @brief Loading of the SGF content is successful only if loading generates
  /// no critical warnings and no critical errors.
  SgfLoadSuccessTypeNoCriticalWarningsOrErrors,
  /// @brief Loading of the SGF content is successful even if loading generates
  /// critical warnings and/or critical errors.
  SgfLoadSuccessTypeWithCriticalWarningsOrErrors,
  SgfLoadSuccessTypeDefault = SgfLoadSuccessTypeNoCriticalWarningsOrErrors
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
/// @name Constants related to UITableViewCell
// -----------------------------------------------------------------------------
//@{
/// @brief Enumerates types of table view cells that can be created by
/// TableViewCellFactory.
enum TableViewCellType
{
  DefaultCellType,       ///< @brief Cell with style @e UITableViewCellStyleDefault
  Value1CellType,        ///< @brief Cell with style @e UITableViewCellStyleValue1
  Value2CellType,        ///< @brief Cell with style @e UITableViewCellStyleValue2
  SubtitleCellType,      ///< @brief Cell with style @e UITableViewCellStyleSubtitle
  SwitchCellType,        ///< @brief Cell with a UISwitch in the accessory view
  SliderWithValueLabelCellType,        ///< @brief Similar to Value1CellType, but with a slider that allows to adjust the value. Displays the value label.
  SliderWithoutValueLabelCellType,     ///< @brief ditto, but does not display the value label.
  GridCellType,          ///< @brief Cell displays configurable number of columns; requires a delegate
  ActivityIndicatorCellType,  ///< @brief Cell with an activity indicator in the accessory view
  DeleteTextCellType,     ///< @brief Cell that displays a "delete" text. Style and color are similar to the delete cell in Apple's address book or calendar apps.
  VariableHeightCellType, ///< @brief Similar to Value1CellType, but the text label uses a variable number of lines.
  ActionTextCellType      ///< @brief Cell that displays a text that triggers an action. Style is similar to DeleteTextCellType, but not alarming.
};

/// @brief Enumerates all possible tags for subviews in custom table view cells
/// created by TableViewCellFactory.
enum TableViewCellSubViewTag
{
  UnusedSubviewTag = 0  ///< @brief Tag 0 must not be used, it is the default tag used for all framework-created views (e.g. the cell's content view)
};
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
extern NSString* SGFCLicenseDocumentResource;
extern NSString* MBProgressHUDLicenseDocumentResource;
extern NSString* lumberjackLicenseDocumentResource;
extern NSString* zipkitLicenseDocumentResource;
extern NSString* crashlyticsLicenseDocumentResource;
extern NSString* firebaseLicenseDocumentResource;
extern NSString* readmeDocumentResource;
extern NSString* manualDocumentResource;
extern NSString* creditsDocumentResource;
extern NSString* changelogDocumentResource;
extern NSString* registrationDomainDefaultsResource;
extern NSString* playStoneSoundFileResource;
extern NSString* uiAreaPlayIconResource;
extern NSString* uiAreaSettingsIconResource;
extern NSString* uiAreaArchiveIconResource;
extern NSString* uiAreaHelpIconResource;
extern NSString* uiAreaDiagnosticsIconResource;
extern NSString* uiAreaAboutIconResource;
extern NSString* uiAreaSourceCodeIconResource;
extern NSString* uiAreaLicensesIconResource;
extern NSString* uiAreaCreditsIconResource;
extern NSString* uiAreaChangelogIconResource;
extern NSString* computerPlayButtonIconResource;
extern NSString* computerSuggestMoveButtonIconResource;
extern NSString* passButtonIconResource;
extern NSString* discardButtonIconResource;
extern NSString* pauseButtonIconResource;
extern NSString* continueButtonIconResource;
extern NSString* gameInfoButtonIconResource;
extern NSString* interruptButtonIconResource;
extern NSString* scoringStartButtonIconResource;
extern NSString* playStartButtonIconResource;
extern NSString* stoneBlackButtonIconResource;
extern NSString* stonesOverlappingBlackButtonIconResource;
extern NSString* stoneWhiteButtonIconResource;
extern NSString* stonesOverlappingWhiteButtonIconResource;
extern NSString* stoneBlackAndWhiteButtonIconResource;
extern NSString* stonesOverlappingBlackAndWhiteButtonIconResource;
extern NSString* unclearButtonIconResource;
extern NSString* veryUnclearButtonIconResource;
extern NSString* goodButtonIconResource;
extern NSString* veryGoodButtonIconResource;
extern NSString* badButtonIconResource;
extern NSString* veryBadButtonIconResource;
extern NSString* interestingButtonIconResource;
extern NSString* doubtfulButtonIconResource;
extern NSString* noneButtonIconResource;
extern NSString* editButtonIconResource;
extern NSString* moreGameActionsButtonIconResource;
extern NSString* forwardButtonIconResource;
extern NSString* forwardToEndButtonIconResource;
extern NSString* backButtonIconResource;
extern NSString* rewindToStartButtonIconResource;
extern NSString* hotspotIconResource;
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
extern NSString* computerAssistanceTypeKey;
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
// SGF settings
extern NSString* sgfSettingsKey;
extern NSString* loadSuccessTypeKey;
extern NSString* enableRestrictiveCheckingKey;
extern NSString* disableAllWarningMessagesKey;
extern NSString* disabledMessagesKey;
extern NSString* encodingModeKey;
extern NSString* defaultEncodingKey;
extern NSString* forcedEncodingKey;
extern NSString* reverseVariationOrderingKey;
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
extern NSString* discardMyLastMoveKey;
// Logging settings
extern NSString* loggingEnabledKey;
// User interface settings
extern NSString* visibleUIAreaKey;
extern NSString* tabOrderKey;
extern NSString* uiAreaPlayModeKey;
extern NSString* visibleAnnotationViewPageKey;
// Magnifying glass settings
extern NSString* magnifyingGlassEnableModeKey;
extern NSString* magnifyingGlassAutoThresholdKey;
extern NSString* magnifyingGlassVeerDirectionKey;
extern NSString* magnifyingGlassDistanceFromMagnificationCenterKey;
// Game setup settings
extern NSString* boardSetupStoneColorKey;
extern NSString* doubleTapToZoomKey;
extern NSString* autoEnableBoardSetupModeKey;
extern NSString* changeHandicapAlertKey;
extern NSString* tryNotToPlaceIllegalStonesKey;
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
extern NSString* goGameNodeModelKey;
extern NSString* goGameStateKey;
extern NSString* goGameReasonForGameHasEndedKey;
extern NSString* goGameReasonForComputerIsThinking;
extern NSString* goGameBoardPositionKey;
extern NSString* goGameRulesKey;
extern NSString* goGameDocumentKey;
extern NSString* goGameScoreKey;
extern NSString* goGameBlackSetupPointsKey;
extern NSString* goGameWhiteSetupPointsKey;
extern NSString* goGameSetupFirstMoveColorKey;
// GoPlayer keys
extern NSString* goPlayerPlayerUUIDKey;
extern NSString* goPlayerIsBlackKey;
// GoMove keys
extern NSString* goMoveTypeKey;
extern NSString* goMovePlayerKey;
extern NSString* goMovePointKey;
extern NSString* goMoveCapturedStonesKey;
extern NSString* goMoveMoveNumberKey;
extern NSString* goMoveGoMoveValuationKey;
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
// GoNode keys
extern NSString* goNodeFirstChildKey;
extern NSString* goNodeNextSiblingKey;
extern NSString* goNodeParentKey;
extern NSString* goNodeGoMoveKey;
extern NSString* goNodeGoNodeAnnotationKey;
// GoNodeAnnotation keys
extern NSString* goNodeAnnotationShortDescriptionKey;
extern NSString* goNodeAnnotationLongDescriptionKey;
extern NSString* goNodeAnnotationGoBoardPositionValuationKey;
extern NSString* goNodeAnnotationGoBoardPositionHotspotDesignationKey;
extern NSString* goNodeAnnotationEstimatedScoreSummaryKey;
extern NSString* goNodeAnnotationEstimatedScoreValueKey;
// GoNodeModel keys
extern NSString* goNodeModelGameKey;
extern NSString* goNodeModelRootNodeKey;
extern NSString* goNodeModelNodeListKey;
extern NSString* goNodeModelNumberOfNodesKey;
extern NSString* goNodeModelNumberOfMovesKey;
// GoPoint keys
extern NSString* goPointVertexKey;
extern NSString* goPointBoardKey;
extern NSString* goPointIsStarPointKey;
extern NSString* goPointStoneStateKey;
extern NSString* goPointTerritoryStatisticsScoreKey;
extern NSString* goPointRegionKey;
// GoScore keys
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

// -----------------------------------------------------------------------------
/// @name Constants for UI testing / accessibility (a11y)
// -----------------------------------------------------------------------------
//@{
extern NSString* statusLabelAccessibilityIdentifier;
extern NSString* boardPositionCollectionViewAccessibilityIdentifier;
extern NSString* intersectionLabelBoardPositionAccessibilityIdentifier;
extern NSString* boardPositionLabelBoardPositionAccessibilityIdentifier;
extern NSString* capturedStonesLabelBoardPositionAccessibilityIdentifier;
extern NSString* blackStoneImageViewBoardPositionAccessibilityIdentifier;
extern NSString* whiteStoneImageViewBoardPositionAccessibilityIdentifier;
extern NSString* noStoneImageViewBoardPositionAccessibilityIdentifier;
extern NSString* unselectedBackgroundViewBoardPositionAccessibilityIdentifier;
extern NSString* selectedBackgroundViewBoardPositionAccessibilityIdentifier;
extern NSString* leftNavigationBarAccessibilityIdentifier;
extern NSString* centerNavigationBarAccessibilityIdentifier;
extern NSString* rightNavigationBarAccessibilityIdentifier;
extern NSString* gameActionButtonContainerAccessibilityIdentifier;
extern NSString* boardPositionNavigationButtonContainerAccessibilityIdentifier;
extern NSString* currentBoardPositionViewAccessibilityIdentifier;
extern NSString* currentBoardPositionTableViewAccessibilityIdentifier;
extern NSString* boardPositionTableViewAccessibilityIdentifier;
//@}

// -----------------------------------------------------------------------------
/// @name Other UI testing constants
// -----------------------------------------------------------------------------
//@{
extern NSString* uiTestModeLaunchArgument;
//@}
