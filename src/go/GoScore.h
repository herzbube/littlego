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
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The GoScore class collects scoring information from a GoGame object.
/// A controller must initiate scoring by invoking calculate(). Scoring occurs
/// asynchronously in a secondary thread - when the new score has been
/// calculated, GoScore posts the notification #goScoreCalculationEnds to the
/// default NSNotificationCenter.
///
/// @ingroup go
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
/// client may request that no territory scoring be performed.
///
///
/// @par Territory scoring
///
/// Territory can be scored only after the status of all stones on the board has
/// been determined to be either dead or alive. Neither Little Go nor the GTP
/// engine are "clever" enough to find out which stone groups are truly dead.
/// This means that the user must help out by interactively marking stones as
/// dead or alive.
///
/// GoScore stores the information whether a stone is dead or alive in the
/// GoPoint objects associated with the GoGame instance it operates on. The
/// general approach is this:
/// - When GoScore calculates its initial score, it first asks the GTP engine
///   for a list of dead stones. It is expected that the GTP engine at least
///   detects dead stones surrounded by unconditionally alive groups.
/// - All GoPoint objects that have dead stones on them are marked accordingly
/// - All other GoPoint objects with stones are marked as alive
/// - Using this information, GoScore calculates its initial score
/// - When the user changes a stone group's dead or alive status, GoScore
///   records the new information in the appropriate GoPoint objects and
///   calculates the new score
///
/// A controller is required to inform GoScore when the dead or alive status of
/// a stone group changes. The controller does this by invoking togglePoint:().
/// Afterwards the controller needs to invoke calculate() to get the new score.
///
/// @note GoScore currently only supports territory scoring without handling for
/// counting eyes in seki.
// -----------------------------------------------------------------------------
@interface GoScore : NSObject
{
}

+ (GoScore*) scoreForGame:(GoGame*)game withTerritoryScores:(bool)withTerritoryScores;
- (void) calculateWaitUntilDone:(bool)waitUntilDone;
- (void) togglePoint:(GoPoint*)point;
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
