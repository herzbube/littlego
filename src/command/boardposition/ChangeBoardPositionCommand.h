// -----------------------------------------------------------------------------
// Copyright 2013-2021 Patrick Näf (herzbube@herzbube.ch)
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


// Project includes
#import "CommandBase.h"


// -----------------------------------------------------------------------------
/// @brief The ChangeBoardPositionCommand class is responsible for changing the
/// current board position to a new value within the current game variation.
/// Use ChangeNodeSelectionCommand to change the current board position @b and
/// also the current game variation.
///
/// ChangeBoardPositionCommand is executed synchronously if the new board
/// position is not more than a given maximum number of positions away from
/// the current board position. The limit is returned by
/// synchronousExecutionThreshold().  ChangeBoardPositionCommand is executed
/// asynchronously (unless the executor is another asynchronous command) if the
/// new board position is more than this limit away from the current board
/// position. To achieve this effect, the various initializers will sometimes
/// return an object that is an instance of a private subclass of
/// ChangeBoardPositionCommand.
///
/// @note initSynchronousExecutionWithBoardPosition:() can be used to enforce
/// synchronous execution.
///
/// initWithBoardPosition:() and initSynchronousExecutionWithBoardPosition:()
/// must be invoked with a valid board position, otherwise command execution
/// will fail.
///
/// initWithOffset:() is more permissive and can be invoked with an offset that
/// would result in an invalid board position (i.e. a position before the first,
/// or after the last position of the game). Such an offset is adjusted so that
/// the result is a valid board position (i.e. either the first or the last
/// board position of the game).
///
/// After it has changed the board position, ChangeBoardPositionCommand performs
/// the following additional operations:
/// - Posts #currentBoardPositionDidChange to the default notification center
/// - Synchronizes the GTP engine with the new board position
/// - Recalculates the score for the new board position if scoring mode is
///   currently enabled
/// - Marks the application state as having changed, so that the board position
///   can be restored when the application launches the next time. Whoever
///   executes ChangeBoardPositionCommand is responsible for actually saving the
///   application state to disk.
// -----------------------------------------------------------------------------
@interface ChangeBoardPositionCommand : CommandBase
{
}

+ (int) synchronousExecutionThreshold;

- (id) initWithBoardPosition:(int)boardPosition;
- (id) initSynchronousExecutionWithBoardPosition:(int)boardPosition;
- (id) initWithFirstBoardPosition;
- (id) initWithLastBoardPosition;
- (id) initWithOffset:(int)offset;

@end
