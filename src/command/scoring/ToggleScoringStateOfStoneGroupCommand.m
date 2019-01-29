// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "ToggleScoringStateOfStoneGroupCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../play/model/ScoringModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// ToggleScoringStateOfStoneGroupCommand.
// -----------------------------------------------------------------------------
@interface ToggleScoringStateOfStoneGroupCommand()
@property(nonatomic, retain) GoPoint* point;
@end


@implementation ToggleScoringStateOfStoneGroupCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a ToggleScoringStateOfStoneGroupCommand object.
///
/// @note This is the designated initializer of
/// ToggleScoringStateOfStoneGroupCommand.
// -----------------------------------------------------------------------------
- (id) initWithPoint:(GoPoint*)point
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.point = point;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// ToggleScoringStateOfStoneGroupCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.point = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (! [self.point hasStone])
    return false;

  GoScore* score = [GoGame sharedGame].score;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  switch (appDelegate.scoringModel.scoreMarkMode)
  {
    case GoScoreMarkModeDead:
    {
      [score toggleDeadStateOfStoneGroup:self.point.region];
      break;
    }
    case GoScoreMarkModeSeki:
    {
      [score toggleSekiStateOfStoneGroup:self.point.region];
      break;
    }
    default:
    {
      assert(0);
      return false;
    }
  }

  [score calculateWaitUntilDone:false];

  return true;
}

@end
