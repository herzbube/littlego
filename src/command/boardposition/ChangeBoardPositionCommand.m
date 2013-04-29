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
#import "../AsynchronousCommand.h"
#import "../backup/BackupGameCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../play/model/ScoringModel.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// ChangeBoardPositionCommand.
// -----------------------------------------------------------------------------
@interface ChangeBoardPositionCommand()
@property(nonatomic, assign) int newBoardPosition;
@end


// -----------------------------------------------------------------------------
/// @brief Private subclass that supports asynchronous execution.
// -----------------------------------------------------------------------------
@interface AsynchronousChangeBoardPositionCommand : ChangeBoardPositionCommand <AsynchronousCommand>
{
}

- (id) initWithBoardPosition:(int)boardPosition;

@property(nonatomic, assign) float stepIncrease;
@property(nonatomic, assign) float progress;
@property(nonatomic, assign) float boardPositionChangesPerStep;
@property(nonatomic, assign) float nextProgressUpdate;
@property(nonatomic, assign) int numberOfBoardPositionChanges;

@end



@implementation ChangeBoardPositionCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeBoardPositionCommand object that will change the
/// current board position to @a aBoardPosition.
///
/// @a asynchronous is ignored. The argument exists only to distinguish the
/// selector of this initializer from the basic initWithBoardPosition:().
///
/// @note This is the designated initializer of ChangeBoardPositionCommand.
// -----------------------------------------------------------------------------
- (id) initWithBoardPosition:(int)aBoardPosition isAsynchronous:(bool)asynchronous
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;
  self.newBoardPosition = aBoardPosition;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeBoardPositionCommand object that will change the
/// current board position to @a aBoardPosition.
// -----------------------------------------------------------------------------
- (id) initWithBoardPosition:(int)aBoardPosition
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  int numberOfBoardPositions = abs(aBoardPosition - boardPosition.currentBoardPosition);
  if (numberOfBoardPositions <= 10)
  {
    self = [self initWithBoardPosition:aBoardPosition isAsynchronous:false];
  }
  else
  {
    [self release];
    self = [[AsynchronousChangeBoardPositionCommand alloc] initWithBoardPosition:aBoardPosition];
  }
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
  DDLogVerbose(@"%@: newBoardPosition = %d, currentBoardPosition = %d, numberOfBoardPositions = %d",
               [self shortDescription],
               self.newBoardPosition,
               boardPosition.currentBoardPosition,
               boardPosition.numberOfBoardPositions);

  if (self.newBoardPosition < 0 || self.newBoardPosition >= boardPosition.numberOfBoardPositions)
    return false;

  if (self.newBoardPosition == boardPosition.currentBoardPosition)
    return true;

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[LongRunningActionCounter sharedCounter] increment];

    ScoringModel* scoringModel = [ApplicationDelegate sharedDelegate].scoringModel;
    if (scoringModel.scoringMode)
      [scoringModel.score reinitialize];  // disable GoBoardRegion caching

    boardPosition.currentBoardPosition = self.newBoardPosition;

    [[[[SyncGTPEngineCommand alloc] init] autorelease] submit];

    if (scoringModel.scoringMode)
      [scoringModel.score calculateWaitUntilDone:false];

    return true;
  }
  @finally
  {
    [[ApplicationStateManager sharedManager] commitSavePoint];
    [[LongRunningActionCounter sharedCounter] decrement];
  }
}

@end


@implementation AsynchronousChangeBoardPositionCommand

@synthesize asynchronousCommandDelegate;

// -----------------------------------------------------------------------------
/// @brief Initializes an AsynchronousChangeBoardPositionCommand object that
/// will change the current board position to @a aBoardPosition.
///
/// @note This is the designated initializer of
/// AsynchronousChangeBoardPositionCommand.
// -----------------------------------------------------------------------------
- (id) initWithBoardPosition:(int)aBoardPosition
{
  // Call designated initializer of superclass (ChangeBoardPositionCommand)
  self = [super initWithBoardPosition:aBoardPosition isAsynchronous:true];
  if (! self)
    return nil;
  self.stepIncrease = 0.0;
  self.progress = 0.0;
  self.boardPositionChangesPerStep = 0.0;
  self.nextProgressUpdate = 0.0;
  self.numberOfBoardPositionChanges = 0;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  [self.asynchronousCommandDelegate asynchronousCommand:self
                                            didProgress:0.0
                                        nextStepMessage:@"Changing board position..."];
  [self setupProgressParameters];
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(boardPositionChangeProgress:) name:boardPositionChangeProgress object:nil];
  bool result = [super doIt];
  [center removeObserver:self];
  return result;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (void) setupProgressParameters
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  int numberOfBoardPositions = abs(self.newBoardPosition - boardPosition.currentBoardPosition);
  static const int maximumNumberOfSteps = 5;
  int numberOfSteps;
  if (numberOfBoardPositions <= maximumNumberOfSteps)
    numberOfSteps = numberOfBoardPositions;
  else
    numberOfSteps = maximumNumberOfSteps;
  self.stepIncrease = 1.0 / numberOfSteps;
  self.boardPositionChangesPerStep = numberOfBoardPositions / numberOfSteps;
  self.nextProgressUpdate = self.boardPositionChangesPerStep;
  self.numberOfBoardPositionChanges = 0;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardPositionChangeProgress notification.
// -----------------------------------------------------------------------------
- (void) boardPositionChangeProgress:(NSNotification*)notification
{
  self.numberOfBoardPositionChanges++;
  if (self.numberOfBoardPositionChanges >= self.nextProgressUpdate)
  {
    self.nextProgressUpdate += self.boardPositionChangesPerStep;
    self.progress += self.stepIncrease;
    [self.asynchronousCommandDelegate asynchronousCommand:self didProgress:self.progress nextStepMessage:nil];
  }
}

@end
