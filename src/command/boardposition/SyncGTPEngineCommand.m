// -----------------------------------------------------------------------------
// Copyright 2013-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "SyncGTPEngineCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeModel.h"
#import "../../go/GoNodeSetup.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SyncGTPEngineCommand
// -----------------------------------------------------------------------------
@interface SyncGTPEngineCommand()
@property(nonatomic, retain, readwrite) NSString* errorDescription;
@end

@implementation SyncGTPEngineCommand


// -----------------------------------------------------------------------------
/// @brief Initializes a SyncGTPEngineCommand object.
///
/// @note This is the designated initializer of SyncGTPEngineCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;
  
  self.syncBoardPositionType = SyncBoardPositionsUpToCurrentBoardPosition;
  self.errorDescription = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SyncGTPEngineCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.errorDescription = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  GoNode* syncUpToThisNode = [self findNodeUpToWhichToSync];
  GoNodeSetup* nodeSetupUpToWhichToSync = [self findeNodeSetupUpToWhichToSync:syncUpToThisNode];
  GoMove* syncUpToThisMove = [self findeMoveUpToWhichToSync:syncUpToThisNode];

  // This clears all board state related parameters (handicap, komi, setup
  // stones, setup player, moves) but leaves board size, game rules and player
  // configuration (e.g. UCT parameters) untouched
  if (! [self syncGTPEngineClearBoard])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineClearBoard failed: %@", [self shortDescription], self.errorDescription);
    return false;
  }

  if (! [self syncGTPEngineKomi])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineKomi failed: %@", [self shortDescription], self.errorDescription);
    return false;
  }

  if (! [self syncGTPEngineHandicapAndSetupStones:nodeSetupUpToWhichToSync])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineHandicapAndSetupStones failed: %@", [self shortDescription], self.errorDescription);
    return false;
  }

  if (! [self syncGTPEngineSetupPlayer:nodeSetupUpToWhichToSync])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineSetupPlayer failed: %@", [self shortDescription], self.errorDescription);
    return false;
  }

  if (! [self syncGTPEngineMoves:syncUpToThisMove])
  {
    DDLogError(@"%@: Aborting because syncGTPEngineMoves failed: %@", [self shortDescription], self.errorDescription);
    return false;
  }
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoNode object up to which the GTP engine should be
/// synchronized, based on the value of the property @e syncBoardPositionType.
/// The returned GoNode object is guaranteed to contain either a GoNodeSetup or
/// a GoMove object. May return @e nil if no GoNode object could be found, in
/// which case the GTP engine should be synchronized with the start of the game.
// -----------------------------------------------------------------------------
- (GoNode*) findNodeUpToWhichToSync
{
  GoGame* game = [GoGame sharedGame];

  if (SyncBoardPositionsUpToCurrentBoardPosition == self.syncBoardPositionType)
  {
    GoNode* currentNode = game.boardPosition.currentNode;
    GoNode* nodeWithMostRecentBoardStateChange = [GoUtilities nodeWithMostRecentBoardStateChange:currentNode];
    return nodeWithMostRecentBoardStateChange;
  }
  else
  {
    GoNode* nodeWithLastBoardStateChange = [GoUtilities nodeWithMostRecentBoardStateChange:game.nodeModel.leafNode];
    return nodeWithLastBoardStateChange;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoNodeSetup object up to which the GTP engine should be
/// synchronized with setup information, based on the value of
/// @a syncUpToThisNode. May return @e nil if no GoNodeSetup object could be
/// found, in which case the GTP engine should be synchronized with setup
/// information from the start of the game.
// -----------------------------------------------------------------------------
- (GoNodeSetup*) findeNodeSetupUpToWhichToSync:(GoNode*)syncUpToThisNode
{
  // We know that syncUpToThisNode is the result of findNodeUpToWhichToSync.
  // From the implementation of that method we know that if syncUpToThisNode
  // is not nil, it contains a board state change - meaning either a GoMove or
  // a GoNodeSetup

  if (syncUpToThisNode)
  {
    if (syncUpToThisNode.goMove)
    {
      GoGame* game = [GoGame sharedGame];
      GoNode* nodeWithMostRecentSetup = [GoUtilities nodeWithMostRecentSetup:syncUpToThisNode inCurrentGameVariation:game];
      return nodeWithMostRecentSetup ? nodeWithMostRecentSetup.goNodeSetup : nil;
    }
    else
    {
      return syncUpToThisNode.goNodeSetup;
    }
  }
  else
  {
    return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoMove object up to which the GTP engine should be
/// synchronized with move information, based on the value of
/// @a syncUpToThisNode. May return @e nil if no GoMove object could be found,
/// in which case the GTP engine should not be synchronized with any moves.
// -----------------------------------------------------------------------------
- (GoMove*) findeMoveUpToWhichToSync:(GoNode*)syncUpToThisNode
{
  // We know that syncUpToThisNode is the result of findNodeUpToWhichToSync.
  // From the implementation of that method we know that if syncUpToThisNode
  // is not nil, it contains a board state change - meaning either a GoMove or
  // a GoNodeSetup.

  return syncUpToThisNode ? syncUpToThisNode.goMove : nil;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineClearBoard
{
  GtpCommand* commandClearBoard = [GtpCommand command:@"clear_board"];
  [commandClearBoard submit];
  assert(commandClearBoard.response.status);
  if (commandClearBoard.response.status)
    self.errorDescription = commandClearBoard.response.parsedResponse;
  return commandClearBoard.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineKomi
{
  GoGame* game = [GoGame sharedGame];

  // The previously sent GTP command "clear_board" has caused Fuego to reset
  // komi to the last value that was explicitly set with the GTP command "komi"
  // (or to the built-in default komi value, in case no "komi" command was ever
  // sent). Therefore, unlike handicap we always have to setup komi.
  GtpCommand* command = [GtpCommand command:[NSString stringWithFormat:@"komi %.1f", game.komi]];
  [command submit];
  assert(command.response.status);
  if (! command.response.status)
    self.errorDescription = command.response.parsedResponse;
  return command.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
///
/// The "gogui-setup" command does not allow to clear stones, so we can't just
/// submit one "gogui-setup" command for each GoNodeSetup. Also we can't submit
/// the "set_free_handicap" command because GoNodeSetup might clear handicap
/// stones.
///
/// The solution is to find the last board state just before the first move was
/// played and submit a single "gogui-setup" command that contains only stones
/// that result from the aggregated board state.
///
/// As a consequence we never configure Fuego with a handicap, i.e. we never
/// submit the "set_free_handicap" command. Submitting "gogui-setup" instead
/// is sufficient to create the necessary board state, though, and code analysis
/// has shown that Fuego does not use the @e number of handicap stones for the
/// evaluation of the board position.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineHandicapAndSetupStones:(GoNodeSetup*)nodeSetupUpToWhichToSync
{
  NSMutableArray* blackSetupPoints = [NSMutableArray array];
  NSMutableArray* whiteSetupPoints = [NSMutableArray array];
  if (nodeSetupUpToWhichToSync)
  {
    // If any handicap stones were still left on the board when GoNodeSetup
    // captured the previous board state, they are now listed in the GoNodeSetup
    // property previousBlackSetupStones.
    [blackSetupPoints addObjectsFromArray:nodeSetupUpToWhichToSync.previousBlackSetupStones];
    [whiteSetupPoints addObjectsFromArray:nodeSetupUpToWhichToSync.previousWhiteSetupStones];

    // noSetupStones (SGF property AE) can affect only stones from the previous
    // board state, so let's clear these stones before we add new stones.
    // Because we don't know whether black or white stones are cleared, we need
    // to repeat the clear in both arrays.
    [blackSetupPoints removeObjectsInArray:nodeSetupUpToWhichToSync.noSetupStones];
    [whiteSetupPoints removeObjectsInArray:nodeSetupUpToWhichToSync.noSetupStones];

    [blackSetupPoints addObjectsFromArray:nodeSetupUpToWhichToSync.blackSetupStones];
    [whiteSetupPoints addObjectsFromArray:nodeSetupUpToWhichToSync.whiteSetupStones];
  }
  else
  {
    GoGame* game = [GoGame sharedGame];
    [blackSetupPoints addObjectsFromArray:game.handicapPoints];
  }

  if (blackSetupPoints.count == 0 || whiteSetupPoints.count == 0)
    return true;

  NSString* commandString = @"gogui-setup";
  for (NSNumber* stoneColorAsNumber in @[[NSNumber numberWithInt:GoColorBlack], [NSNumber numberWithInt:GoColorWhite]])
  {
    enum GoColor stoneColor = [stoneColorAsNumber intValue];

    NSArray* setupPoints;
    NSString* colorString;
    if (stoneColor == GoColorBlack)
    {
      setupPoints = blackSetupPoints;
      colorString = @"B";
    }
    else
    {
      setupPoints = whiteSetupPoints;
      colorString = @"W";
    }

    for (GoPoint* setupPoint in setupPoints)
    {
      NSString* setupStoneString = [NSString stringWithFormat:@" %@ %@", colorString, setupPoint.vertex.string];
      commandString = [commandString stringByAppendingString:setupStoneString];
    }
  }

  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
  assert(command.response.status);
  if (! command.response.status)
    self.errorDescription = command.response.parsedResponse;
  return command.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineSetupPlayer:(GoNodeSetup*)nodeSetupUpToWhichToSync
{
  if (! nodeSetupUpToWhichToSync)
    return true;

  enum GoColor setupFirstMoveColor = nodeSetupUpToWhichToSync.setupFirstMoveColor;
  if (setupFirstMoveColor == GoColorNone)
  {
    setupFirstMoveColor = nodeSetupUpToWhichToSync.previousSetupFirstMoveColor;
    if (setupFirstMoveColor == GoColorNone)
      return true;
  }

  NSString* colorString;
  if (setupFirstMoveColor == GoColorBlack)
    colorString = @"B";
  else
    colorString = @"W";

  NSString* commandString = [NSString stringWithFormat:@"gogui-setup_player %@", colorString];

  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
  assert(command.response.status);
  if (! command.response.status)
    self.errorDescription = command.response.parsedResponse;
  return command.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). Returns true on success, false on failure.
// -----------------------------------------------------------------------------
- (bool) syncGTPEngineMoves:(GoMove*)syncUpToThisMove
{
  if (! syncUpToThisMove)
    return true;

  GoNodeModel* nodeModel = [GoGame sharedGame].nodeModel;

  NSString* commandString = @"gogui-play_sequence";
  int numberOfNodes = nodeModel.numberOfNodes;
  for (int indexOfNode = 0; indexOfNode < numberOfNodes; ++indexOfNode)
  {
    GoNode* node = [nodeModel nodeAtIndex:indexOfNode];

    GoMove* move = node.goMove;
    if (move)
    {
      if (move.player.black)
        commandString = [commandString stringByAppendingString:@" B "];
      else
        commandString = [commandString stringByAppendingString:@" W "];
      switch (move.type)
      {
        case GoMoveTypePlay:
          commandString = [commandString stringByAppendingString:move.point.vertex.string];
          break;
        case GoMoveTypePass:
          commandString = [commandString stringByAppendingString:@" PASS"];
          break;
        default:
          DDLogError(@"%@: Unexpected move type %d", [self shortDescription], move.type);
          assert(0);
          return false;
      }

      if (move == syncUpToThisMove)
        break;
    }
  }

  GtpCommand* commandSetup = [GtpCommand command:commandString];
  [commandSetup submit];
  assert(commandSetup.response.status);
  if (! commandSetup.response.status)
    self.errorDescription = commandSetup.response.parsedResponse;
  return commandSetup.response.status;
}

@end
