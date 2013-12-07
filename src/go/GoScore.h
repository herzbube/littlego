// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The GoScore class collects scoring information and move statistics
/// from the GoGame object that is specified during initialization. Scoring
/// information is collected for the current board position, while the move
/// statistics refer to the entire game.
///
/// @ingroup go
///
/// GoScore does not automatically collect any information, nor does it
/// automatically update previously collected information.
/// calculateWaitUntilDone:() must be invoked for the initial information
/// collection, and also every time that the information needs to be updated.
/// - If invoked with argument false, calculateWaitUntilDone:() initiates the
///   information collection process in a secondary thread, then returns control
///   immediately to the caller before the desired information is actually
///   available.
/// - If invoked with argument true, calculateWaitUntilDone:() performs the
///   information collection process synchronously, i.e. when it returns control
///   to the caller the desired information is already available.
///
/// Regardless of whether information is collected synchronously or
/// asynchronously, GoScore posts the following notifications to the default
/// NSNotificationCenter: #goScoreCalculationStarts right before calculation
/// starts, and #goScoreCalculationEnds after calculation ends and the desired
/// information is available. Both notifications are delivered in the context
/// of the main thread.
///
/// By default GoScore does not collect scoring information because this is a
/// potentially time-consuming operation. A controller may enable the collection
/// of scoring information by setting the @e scoringEnabled property to true. In
/// this case the controller should invoke calculateWaitUntilDone:() with
/// argument false so that the time-consuming operation is performed in a
/// secondary thread.
///
/// GoScore posts notifications to the default NSNotificationCenter when
/// scoring is enabled (#goScoreScoringEnabled) or disabled
/// (#goScoreScoringDisabled).
///
///
/// @par Scoring overview
///
/// Score calculation depends on the scoring system in effect for the current
/// game. The score can only be calculated after the status of all stones on the
/// board has been determined to be either dead or alive. Neither Little Go nor
/// the GTP engine are "clever" enough to find out which stone groups are truly
/// dead. This means that the user must help out by interactively marking stones
/// as dead or alive.
///
/// An updated score is calculated every time that the user marks a stone group
/// as dead or alive. This is the sequence of events:
/// # toggleDeadStoneStateOfGroup:() is invoked by the controller object that
///   handles user input
///   - toggleDeadStoneStateOfGroup:() stores the information whether stones are
///     dead or alive in GoBoardRegion objects' @e deadStoneGroup property.
///   - If the user has turned the "mark stones intelligently" feature on in
///     the user preferences, toggleDeadStoneStateOfGroup:() assists the user
///     by changing the @e deadStoneGroup property not only of the GoBoardRegion
///     that is passed as a parameter, but also of adjacent GoBoardRegion
///     objects. See the "Mark dead stones intelligently" section below for
///     details.
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
///   - See the section "Determining territory color" below for details on how
///     the calculation works
/// # updateScoringProperties:() (a private helper method invoked as part of
///   the scoring process) finally adds up all the scores and statistics and
///   stores the values in GoScore's publicly accessible scoring and statistics
///   properties
///
/// @note When GoScore calculates a score for the first time, it asks the GTP
/// engine for an initial list of dead stones. It is expected that the GTP
/// engine at least detects dead stones surrounded by unconditionally alive
/// groups. This query can be suppressed by the user in the user preferences.
///
///
/// @par Mark dead stones intelligently
///
/// If the user has turned this feature on in the user preferences,
/// toggleDeadStoneStateOfGroup:() changes the @e deadStoneGroup property not
/// only of the GoBoardRegion that is passed as a parameter, but also of
/// adjacent GoBoardRegion objects. The reasoning is this:
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
///   dead (if they are not dead already)
/// - The original implementation of this feature would also examine white stone
///   groups in the same territory and turn them back to be alive if they were
///   dead. The result of this, however, was a cascade of toggling operations
///   that, after a few repetitions, would affect the entire board. The feature
///   effectively became unusable, so toggleDeadStoneStateOfGroup:() was limited
///   to look only at groups of the same color as the group that is passed as
///   a parameter.
///
///
/// @par Determining territory color
///
/// The implementation of updateTerritoryColor() is rather simple and consists
/// of two passes:
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
///     seki, but probably it's just dame (a neutral region).
///   - If at least one adjacent stone group is dead, the empty region belongs
///     to the opposing color's territory.
///   - In the last case, updateTerritoryColor() makes a final check to see
///     if there are any inconsistencies (stone groups of the same color that
///     are alive, or stones groups of the opposing color that are also dead).
///   - If inconsistencies are found the empty region is marked accordingly so
///     that the problem can be made visible to user. For scoring purposes, the
///     empty region is considered to be neutral.
// -----------------------------------------------------------------------------
@interface GoScore : NSObject <NSCoding>
{
}

- (id) initWithGame:(GoGame*)game;
- (void) calculateWaitUntilDone:(bool)waitUntilDone;
- (void) toggleDeadStoneStateOfGroup:(GoBoardRegion*)stoneGroup;
- (NSString*) resultString;
- (void) willChangeBoardPosition;
- (void) didChangeBoardPosition;

// -----------------------------------------------------------------------------
/// @name General properties
// -----------------------------------------------------------------------------
//@{
/// @brief Is true if scoring is enabled on this GoScore object.
///
/// Setting this property to true puts all GoBoardRegion objects that currently
/// exist into scoring mode (see the GoBoardRegion class documentation for
/// details) and initializes them to belong to no territory. Also, when
/// calculateWaitUntilDone:() is invoked the next time, the GTP engine will be
/// queried for an initial set of dead stones (unless suppressed by the user
/// preference).
///
/// Setting this property to false puts all GoBoardRegion objects that currently
/// exist into normal mode, i.e. "not scoring" mode.
@property(nonatomic, assign) bool scoringEnabled;
@property(nonatomic, assign) bool scoringInProgress;         ///< @brief Is true if a scoring operation is currently in progress.
@property(nonatomic, assign) bool askGtpEngineForDeadStonesInProgress; ///< @brief Is true if the GTP engine is currently being queried for dead stones.
//@}
// -----------------------------------------------------------------------------
/// @name Scoring properties (for the current board position)
// -----------------------------------------------------------------------------
//@{
@property(nonatomic, assign) double komi;
@property(nonatomic, assign) int capturedByBlack;       ///< @brief The number of stones captured by black
@property(nonatomic, assign) int capturedByWhite;       ///< @brief The number of stones captured by white
@property(nonatomic, assign) int deadBlack;             ///< @brief The number of dead black stones
@property(nonatomic, assign) int deadWhite;             ///< @brief The number of dead white stones
@property(nonatomic, assign) int territoryBlack;        ///< @brief Territory score for black
@property(nonatomic, assign) int territoryWhite;        ///< @brief Territory score for white
@property(nonatomic, assign) int totalScoreBlack;       ///< @brief The total score for black
@property(nonatomic, assign) double totalScoreWhite;    ///< @brief The total score for white
@property(nonatomic, assign) enum GoGameResult result;  ///< @brief The overall result of comparing @e totalScoreBlack and @e totalScoreWhite
//@}
// -----------------------------------------------------------------------------
/// @name Move statistics (for the entire game)
// -----------------------------------------------------------------------------
//@{
@property(nonatomic, assign) int numberOfMoves;
@property(nonatomic, assign) int stonesPlayedByBlack;
@property(nonatomic, assign) int stonesPlayedByWhite;
@property(nonatomic, assign) int passesPlayedByBlack;
@property(nonatomic, assign) int passesPlayedByWhite;
//@}

@end
