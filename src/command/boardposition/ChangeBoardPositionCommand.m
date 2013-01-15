// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "ChangeBoardPositionCommand.h"
#import "SyncGTPEngineCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../play/ScoringModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ChangeBoardPositionCommand.
// -----------------------------------------------------------------------------
@interface ChangeBoardPositionCommand()
/// @name Private properties
//@{
@property(nonatomic, assign) int newBoardPosition;
//@}
@end


@implementation ChangeBoardPositionCommand

@synthesize newBoardPosition;


// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeBoardPositionCommand object that will change the
/// current board position to @a boardPosition.
///
/// @a boardPosition must be a valid position, otherwise command execution will
/// fail.
///
/// @note This is the designated initializer of ChangeBoardPositionCommand.
// -----------------------------------------------------------------------------
- (id) initWithBoardPosition:(int)boardPosition
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;
  self.newBoardPosition = boardPosition;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeBoardPositionCommand object that will change the
/// current board position to the first board position.
// -----------------------------------------------------------------------------
- (id) initWithFirstBoardPosition
{
  return [self initWithBoardPosition:0];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeBoardPositionCommand object that will change the
/// current board position to the last board position.
// -----------------------------------------------------------------------------
- (id) initWithLastBoardPosition;
{
  int boardPosition = [GoGame sharedGame].boardPosition.numberOfBoardPositions - 1;
  return [self initWithBoardPosition:boardPosition];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeBoardPositionCommand object that will change the
/// current board position by adding @a offset to the current board position.
///
/// A negative/positive offset is used to go to a board position before/after
/// the current board position.
///
/// If @a offset results in an invalid board position (i.e. a position before
/// the first, or after the last position of the game), the offset is adjusted
/// so that the result is a valid board position (i.e. either the first or the
/// last board position of the game).
// -----------------------------------------------------------------------------
- (id) initWithOffset:(int)offset
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  int boardPositionOffset = boardPosition.currentBoardPosition + offset;
  if (boardPositionOffset < 0)
    boardPositionOffset = 0;
  else if (boardPositionOffset >= boardPosition.numberOfBoardPositions)
    boardPositionOffset = boardPosition.numberOfBoardPositions - 1;
  return [self initWithBoardPosition:boardPositionOffset];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  if (self.newBoardPosition < 0 || self.newBoardPosition >= boardPosition.numberOfBoardPositions)
    return false;

  if (self.newBoardPosition == boardPosition.currentBoardPosition)
    return true;

  ScoringModel* scoringModel = [ApplicationDelegate sharedDelegate].scoringModel;
  if (scoringModel.scoringMode)
    [scoringModel.score reinitialize];  // disable GoBoardRegion caching

  boardPosition.currentBoardPosition = self.newBoardPosition;

  [[[SyncGTPEngineCommand alloc] init] submit];

  if (scoringModel.scoringMode)
    [scoringModel.score calculateWaitUntilDone:false];

  return true;
}

@end
