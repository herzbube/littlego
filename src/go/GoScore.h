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


// Forward declarations
@class GoGame;
@class GoBoardRegion;


// -----------------------------------------------------------------------------
/// @brief The GoScore class collects scoring information from a GoGame object.
///
/// @ingroup go
///
/// A controller must initiate scoring by invoking calculateWaitUntilDone:().
/// Unless specified otherwise by the controller, scoring occurs asynchronously
/// in a secondary thread. When the new score has been calculated, GoScore
/// posts the notification #goScoreCalculationEnds to the default
/// NSNotificationCenter. Another notificaton #goScoreCalculationStarts is
/// posted right before calculation starts. Both notifications are delivered in
/// the main thread context.
///
/// A GoScore instance operates on the GoGame object that was specified during
/// construction. The GoGame object does not need to be in any particular state,
/// e.g. it is not necessary for the game to be in state #GameHasEnded.
///
/// Most of the scoring information is collected by simply inspecting the state
/// of GoGame and its associated objects:
/// - Komi is collected from GoGame
/// - The number of captured stones as well as move statistics are collected
///   from GoMove objects
///
/// Territory scoring is more complicated and a potentially time-consuming
/// operation. For this reason, when a client creates a new GoScore object the
/// client may optionally request that no territory scoring be performed.
///
/// @note GoScore currently only supports territory scoring without handling for
/// counting eyes in seki.
///
///
/// @par Territory scoring overview
///
/// The territory score can only be calculated after the status of all stones on
/// the board has been determined to be either dead or alive. Neither Little Go
/// nor the GTP engine are "clever" enough to find out which stone groups are
/// truly dead. This means that the user must help out by interactively marking
/// stones as dead or alive.
///
/// An updated score is calculated every time that the user marks a stone group
/// as dead or alive. This is the sequence of events:
/// # toggleDeadStoneStateOfGroup:() is invoked by the controller object that
///   handles user input
///   - toggleDeadStoneStateOfGroup:() stores the information whether stones are
///     dead or alive in GoBoardRegion objects' @e deadStoneGroup property.
///   - To remain consistent with Go rules, toggleDeadStoneStateOfGroup:()
///     changes the @e deadStoneGroup property not only of the GoBoardRegion
///     that is passed as a parameter, but also of adjacent GoBoardRegion
///     objects. See the "Guidelines" section below for details.
/// # calculateWaitUntilDone:() is invoked by the controller object that handles
///   user input. This initiates the actual scoring process which consists of
///   two more steps.
/// # updateTerritoryColor() (a private helper method invoked as part of the
///   scoring process) calculates the color that "owns" each GoBoardRegion
///   - updateTerritoryColor() stores the "owning" color in GoBoardRegion
///     objects' @e territoryColor property.
///   - Calculation of the territory color entirely depends on the
///     @e deadStoneGroup property of all GoBoardRegion objects having been
///     set up correctly before.
///   - See the "Guidelines" section below for details on how the calculation
///     works
/// # updateScoringProperties:() (a private helper method invoked as part of
///   the scoring process) finally adds up all the scores and statistics and
///   stores the values in GoScore's publicly accessible scoring and statistics
///   properties
///
/// @note When GoScore calculates a score for the first time, it asks the GTP
/// engine for an initial list of dead stones. It is expected that the GTP
/// engine at least detects dead stones surrounded by unconditionally alive
/// groups. This query can be suppressed by the user in the GUI.
///
///
/// @par Guidelines for territory scoring
///
/// toggleDeadStoneStateOfGroup:() is implemented to follow these guidelines:
/// - Marking a stone group as dead means that the owning color has conceded
///   that the group is in opposing territory.
/// - However, it is not possible to have two or more stone groups of the same
///   color in the same territory, but some of them are dead and some of them
///   are alive. They must either be all dead, or all alive.
/// - toggleDeadStoneStateOfGroup:() therefore looks not only at the single
///   stone group that is passed as a parameter, but also examines adjacent
///   GoBoardRegion objects. If it finds other stone groups that do not satisfy
///   the rule above, it toggles them to dead/alive as appropriate.
/// - For instance, if the user marks a black stone group to be dead, other
///   black stone groups in the same territory are also automatically marked
///   dead (if they are not dead already), and white stone groups in the same
///   territory are turned back to be alive (if they are dead).
/// - The overall effect might be a cascade of toggling operations that affects
///   the entire board.
///
/// Since updateTerritoryColor() can rely on toggleDeadStoneStateOfGroup:()
/// enforcing the guidelines above, its implementation becomes rather simple
/// and consists of two passes:
/// # Territory colors for stone groups can easily be determined by looking at
///   the stone group's color
///   - If the group is alive, the points in the group belong to the color
///     that has played the stones
///   - If the group is dead, the points in the group belong to the opposing
///     color
/// # Territory colors for empty regions are determined by looking at each empty
///   region's adjacent regions
///   - These must, of course, all be stone groups
///   - If all adjacent stone groups are alive and of the same color, the empty
///     region belongs to that color's territory. The empty region in this case
///     can be considered to be surrounded.
///   - If all adjacent stone groups are alive and have differents colors, the
///     empty region does not belong to any territory. This might indicate a
///     seki, but probably it's just a neutral region.
///   - If at least one adjacent stone group is dead, the empty region belongs
///     to the opposing color's territory.
///   - In the last case, updateTerritoryColor() makes a final check to see
///     that the guidelines outlined above for toggleDeadStoneStateOfGroup:()
///     are not violated. If they are violated unexpectedly,
///     updateTerritoryColor() aborts its calculation and reports an error to
///     the overall scoring process so that the problem can be made visible to
///     the user.
// -----------------------------------------------------------------------------
@interface GoScore : NSObject
{
}

+ (GoScore*) scoreForGame:(GoGame*)game withTerritoryScores:(bool)withTerritoryScores;
- (void) calculateWaitUntilDone:(bool)waitUntilDone;
- (void) toggleDeadStoneStateOfGroup:(GoBoardRegion*)stoneGroup;
- (NSString*) resultString;

// -----------------------------------------------------------------------------
/// @name General properties
// -----------------------------------------------------------------------------
//@{
@property bool territoryScoresAvailable;  ///< @brief Is true if territory scoring is enabled on this GoScore object.
@property bool scoringInProgress;         ///< @brief Is true if a scoring operation is currently in progress.
//@}
// -----------------------------------------------------------------------------
/// @name Scoring properties
// -----------------------------------------------------------------------------
//@{
@property double komi;
@property int capturedByBlack;       ///< @brief The number of stones captured by black
@property int capturedByWhite;       ///< @brief The number of stones captured by white
@property int deadBlack;             ///< @brief The number of dead black stones
@property int deadWhite;             ///< @brief The number of dead white stones
@property int territoryBlack;        ///< @brief Territory score for black
@property int territoryWhite;        ///< @brief Territory score for white
@property int totalScoreBlack;       ///< @brief The total score for black
@property double totalScoreWhite;    ///< @brief The total score for white
@property enum GoGameResult result;  ///< @brief The overall result of comparing @e totalScoreBlack and @e totalScoreWhite
//@}
// -----------------------------------------------------------------------------
/// @name Move statistics
// -----------------------------------------------------------------------------
//@{
@property int numberOfMoves;
@property int stonesPlayedByBlack;
@property int stonesPlayedByWhite;
@property int passesPlayedByBlack;
@property int passesPlayedByWhite;
//@}

@end
