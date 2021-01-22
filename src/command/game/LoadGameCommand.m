// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "LoadGameCommand.h"
#import "NewGameCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../backup/CleanBackupSgfCommand.h"
#import "../boardposition/SyncGTPEngineCommand.h"
#import "../move/ComputerPlayMoveCommand.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameDocument.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpUtilities.h"
#import "../../main/ApplicationDelegate.h"
#import "../../newgame/NewGameModel.h"
#import "../../sgf/SgfUtilities.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../utility/NSStringAdditions.h"

// Constants
static const int maxStepsForReplayMoves = 10;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LoadGameCommand.
// -----------------------------------------------------------------------------
@interface LoadGameCommand()
@property(nonatomic, retain) NSArray* sgfMainVariationNodes;
@property(nonatomic, retain) SGFCNode* sgfGameInfoNode;
@property(nonatomic, retain) SGFCGoGameInfo* sgfGoGameInfo;
@property(nonatomic, assign) int totalSteps;
@property(nonatomic, assign) float stepIncrease;
@property(nonatomic, assign) float progress;
@end


@implementation LoadGameCommand

@synthesize asynchronousCommandDelegate;

// -----------------------------------------------------------------------------
/// @brief Initializes a LoadGameCommand object that will load the game from
/// the SGF data referenced by @a sgfGameInfoNode.
///
/// @note This is the designated initializer of LoadGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithGameInfoNode:(SGFCNode*)sgfGameInfoNode goGameInfo:(SGFCGoGameInfo*)sgfGoGameInfo
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.sgfGameInfoNode = sgfGameInfoNode;
  self.sgfGoGameInfo = sgfGoGameInfo;
  self.sgfMainVariationNodes = sgfGameInfoNode.mainVariationNodes;

  self.restoreMode = false;
  self.didTriggerComputerPlayer = false;

  self.totalSteps = (6 + maxStepsForReplayMoves);  // 6 steps before move replay begins
  self.stepIncrease = 1.0 / self.totalSteps;
  self.progress = 0.0;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LoadGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.sgfMainVariationNodes = nil;
  self.sgfGameInfoNode = nil;
  self.sgfGoGameInfo = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  @try
  {
    [[LongRunningActionCounter sharedCounter] increment];
    [self setupProgressHUD];
    [GtpUtilities stopPondering];
    @try
    {
      [[ApplicationStateManager sharedManager] beginSavePoint];
      [self increaseProgressAndNotifyDelegate];
      NSString* errorMessage;
      bool success = [self setupGoGame:&errorMessage];
      if (! success)
      {
        [self handleCommandFailed:errorMessage];
        success = [self setupGoGame:&errorMessage];
        if (! success)
        {
          errorMessage = @"Loading a game failed. Setting up a game with default values failed, too.";
          DDLogError(@"%@: %@", self, errorMessage);
          NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                           reason:errorMessage
                                                         userInfo:nil];
          @throw exception;
        }
      }
      return true;
    }
    @finally
    {
      [[ApplicationStateManager sharedManager] applicationStateDidChange];
      [[ApplicationStateManager sharedManager] commitSavePoint];
    }
  }
  @finally
  {
    [[LongRunningActionCounter sharedCounter] decrement];
  }

  // We should never get here - unless an exception occurs, all paths in the
  // @try block above should return either true or false
  assert(0);
  return false;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (void) setupProgressHUD
{
  NSString* message;
  if (self.restoreMode)
    message = @"Restoring game...";
  else
    message = @"Loading game...";
  [self.asynchronousCommandDelegate asynchronousCommand:self
                                            didProgress:0.0
                                        nextStepMessage:message];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) setupGoGame:(NSString**)errorMessage
{
  // The following sequence must always be run in its entirety to arrive at an
  // operational GoGame object tree and application state. If an error occurs we
  // abort the sequence, but expect to be invoked again after an alert has been
  // displayed to the user. Before the second invocation the erroneous SGF data
  // must have been discarded and replaced with default data that is guaranteed
  // to let the sequence complete successfully.
  bool success = [self startNewGame:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self setupHandicap:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self setupSetup:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self setupSetupPlayer:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self setupKomi:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self setupMoves:errorMessage];
  if (! success)
    return false;
  success = [self setupGameResult:errorMessage];
  if (! success)
    return false;
  success = [self syncGtpEngine:errorMessage];
  if (! success)
    return false;

  if (self.restoreMode)
  {
    // Can't invoke notifyGoGameDocument 1) because we are not loading from the
    // archive so we don't have an archive game name; and 2) because we don't
    // know whether the restored game has previously been saved, so we also
    // cannot save the document dirty flag. The consequences: The document dirty
    // flag remains set (which will cause a warning when the next new game is
    // started), and the document name remains uninitialized (which will make
    // it appear to anybody who evaluates the document name as if the game has
    // has never been saved before).

    // No need to create a backup, we already have the one we are restoring from
  }
  else
  {
    [self notifyGoGameDocument];
    [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
  }
  [GtpUtilities setupComputerPlayer];
  [self performSelector:@selector(triggerComputerPlayerOnMainThread)
               onThread:[NSThread mainThread]
             withObject:nil
          waitUntilDone:YES];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Starts the new game.
// -----------------------------------------------------------------------------
- (bool) startNewGame:(NSString**)errorMessage
{
  SGFCBoardSize sgfBoardSize = self.sgfGoGameInfo.boardSize;
  if (! SGFCBoardSizeIsSquare(sgfBoardSize))
  {
    *errorMessage = [NSString stringWithFormat:@"The board size is not square: %ld x %ld.", (long)sgfBoardSize.Columns, (long)sgfBoardSize.Rows];
    return false;
  }

  enum GoBoardSize boardSize;
  switch (sgfBoardSize.Columns)
  {
    case 7:
    case 9:
    case 11:
    case 13:
    case 15:
    case 17:
    case 19:
    {
      boardSize = (enum GoBoardSize)sgfBoardSize.Columns;
      break;
    }
    default:
    {
      *errorMessage = [NSString stringWithFormat:@"The board size is not supported: %ld.", (long)sgfBoardSize.Columns];
      return false;
    }
  }

  // Temporarily re-configure NewGameModel with the new board size from the
  // loaded game
  NewGameModel* model = [ApplicationDelegate sharedDelegate].theNewGameModel;
  enum GoBoardSize oldBoardSize = model.boardSize;
  model.boardSize = boardSize;

  if (self.restoreMode)
  {
    // Since we are restoring from a backup we want to keep it
  }
  else
  {
    // Delete the current backup, a new backup with the moves from the archive
    // we are currently loading will be made later on
    [[[[CleanBackupSgfCommand alloc] init] autorelease] submit];
  }

  NewGameCommand* command = [[[NewGameCommand alloc] init] autorelease];
  // We can't let NewGameCommand honor the "auto-enable board setup mode"
  // user preference because LoadGameCommand (i.e. this command) performs all
  // sorts of intricate actions that were designed to happen during play mode.
  // If in the future the user preference should also be honored for new games
  // started by loading an .sgf, then the handling must happen here in
  // LoadGameCommand where we know when it is the appropriate time to switch
  // to board setup mode. Things that immediately come to mind: Switch to board
  // setup mode only after we know that the .sgf contains no moves, and if we
  // switch we must prevent the computer player from being triggered.
  command.shouldHonorAutoEnableBoardSetupMode = false;
  // It used to be unnecessary to set up the GTP board because it was already
  // set up by the "loadsgf" GTP command. Now that we load and parse the .sgf
  // file ourselves this setup has become necessary at all times.
  command.shouldSetupGtpBoard = true;
  // Handicap and komi will later be set up by SyncGTPEngineCommand
  command.shouldSetupGtpHandicapAndKomi = false;
  // We have to do this ourselves, after setting up handicap + moves
  command.shouldTriggerComputerPlayer = false;
  // We want the load game command to proceed as quickly as possible, therefore
  // we set up the computer player ourselves, at the very end just before we
  // trigger the computer player. If we would allow the computer player to be
  // set up earlier, it might start pondering, taking away precious CPU cycles
  // from the already slow load game command.
  command.shouldSetupComputerPlayer = false;
  bool success = [command submit];
  if (! success)
  {
    assert(0);
    *errorMessage = @"Internal error: Starting a new game failed";
  }

  // Restore the original board size (is a user preference which should should
  // not be overwritten by the loaded game's setting)
  model.boardSize = oldBoardSize;

  return success;
}

// -----------------------------------------------------------------------------
/// @brief Sets up handicap for the new game.
// -----------------------------------------------------------------------------
- (bool) setupHandicap:(NSString**)errorMessage
{
  // Implementation in Fuego of the "list_handicap" GTP command
  // - Find the node that contains the HA property. Searching is started in the
  //   last node of the main variation. The search then continues backwards
  //   until the root node is reached. The first node that contains a HA
  //   property is used.
  // - List all values of the AB property that is in the same node (if there is
  //   any)
  // - A difference between the HA value and the number of AB values is ignored,
  //   in fact the HA value is ignored entirely
  //
  // SGFC behaviour
  // - The first node that contains a game info property is considered to be
  //   a game info node. If another node further down the tree contains
  //   another game info property SGFC warns about this with error 44 and
  //   deletes the later game info property.
  // - If the node that contains the handicap property contains no AB property
  //   this is not warned about.
  //
  // Our handling
  // - Differently than Fuego, we expect the HA property in the game info node
  // - Also differently than Fuego the HA property value actually matters
  // - If a HA property exists and it has a value > 0, then the same node
  //   must contain an AB property that sets up at least as many black stones
  //   as the HA property value requires. If there are less setup stones we
  //   refuse to process the .sgf file. Extraneous setup stones are not
  //   treated as handicap stones.

  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  NSMutableArray* handicapPoints = [NSMutableArray array];

  SGFCProperty* handicapProperty = [self.sgfGameInfoNode propertyWithType:SGFCPropertyTypeHA];
  if (handicapProperty)
  {
    SGFCNumber expectedNumberOfHandicapStones = handicapProperty.propertyValue.toSingleValue.toNumberValue.numberValue;
    if (expectedNumberOfHandicapStones > 0)
    {
      NSUInteger actualNumberOfHandicapStones = 0;
      SGFCProperty* handicapStonesProperty = [self.sgfGameInfoNode propertyWithType:SGFCPropertyTypeAB];
      if (handicapStonesProperty)
      {
        NSArray* handicapStonesPropertyValues = handicapStonesProperty.propertyValues;
        for (id<SGFCPropertyValue> handicapStonesPropertyValue in handicapStonesPropertyValues)
        {
          SGFCGoPoint* goPoint = handicapStonesPropertyValue.toSingleValue.toStoneValue.toGoStoneValue.goStone.location;
          if (! goPoint)
          {
            *errorMessage = @"SgfcKit interfacing error while determining the handicap: Missing SGFCGoPoint object.";
            return false;
          }

          if (! [goPoint hasPositionInGoPointNotation:SGFCGoPointNotationHybrid])
          {
            *errorMessage = @"SgfcKit interfacing error while determining the handicap: SGFCGoPoint not available in hybrid notation.";
            return false;
          }

          NSString* vertexString = [goPoint positionInGoPointNotation:SGFCGoPointNotationHybrid];
          GoPoint* point = [board pointAtVertex:vertexString];
          [handicapPoints addObject:point];

          actualNumberOfHandicapStones++;

          // There may be more setup stones than the handicap indicates. We don't
          // treat these extraneous setup stones as handicap stones.
          if (actualNumberOfHandicapStones == expectedNumberOfHandicapStones)
            break;
        }
      }

      if (actualNumberOfHandicapStones != expectedNumberOfHandicapStones)
      {
        *errorMessage = [NSString stringWithFormat:@"The handicap (%ld) is greater than the number of black setup stones (%ld).", expectedNumberOfHandicapStones, actualNumberOfHandicapStones];
        return false;
      }
    }
  }

  // NewGameCommand already has set up GoGame with a handicap. Here we overwrite
  // it with the new handicap from the SGF data. We do this even if the
  // handicapPoints array is empty.
  // Note: GoGame takes care to place black stones on the points
  game.handicapPoints = handicapPoints;

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the setup stones prior to the first move of the game.
// -----------------------------------------------------------------------------
- (bool) setupSetup:(NSString**)errorMessage
{
  // Implementation in Fuego of the "list_setup" GTP command
  // - Setup stones are all points that have a stone on them after AB, AW and AE
  //   properties in all nodes of the main variation have been evaluated, minus
  //   AB setup stones in the node that contains the HA property (to account for
  //   how the "list_handicap" GTP command evaluates the handicap).
  // - Setup properties that operate on the same point
  //   - Within the same node: Process properties in the order AB, AW, AE
  //   - Across nodes: The last setup property wins
  //
  // SGFC behaviour
  // - Setup properties are not restricted to the root node or a game info
  //   node. They can appear in the root node, in a game info node, before or
  //   after a game info node, before or after nodes that contain move nodes
  // - Setup and move properties cannot appear in the same node; SGFC issues
  //   error 30 and splits the properties into two nodes: the setup properties
  //   are moved to the first node, the move property to the second node
  //   (regardless of how they appear in the original SGF content); the order
  //   of the setup properties (if there are several of them) is preserved.
  // - A move property that places a stone on a point that is already occupied
  //   (regardless of whether the stone was placed by another move or by a setup
  //   property) is warned about with warning 58, but the move property is
  //   retained
  // - A setup property that places a stone on a point that is already occupied
  //   with a stone of the same color, or empties an already empty point, is
  //   warned about with warning 39 and the property value is deleted (because
  //   it takes no effect)
  // - Setup properties in different nodes can operate on the same point as
  //   long as they change something about the point; they overwrite previous
  //   values, e.g. it's not necessary to remove a stone with AE before placing
  //   a stone with a different color
  // - If the same point appears more than once in the same node in one or more
  //   setup properties, SGFC issues warning 38 and deletes the duplicate
  //   values; if the same values appears multiple times in the same property
  //   SGFC deletes the first value; if the same value appears multiple times
  //   in different properties SGFC retains the value that appears first and
  //   deletes all values that appear later.
  // - If the same setup property appears multiple times in the same node
  //   SGFC issues warning 28 and merges the values of the two properties
  //   (assuming they don't overlap).
  // - Black and white moves cannot appear in the same node; SGFC issues
  //   error 37 and splits the properties into two nodes. the order of the
  //   properties is preserved.
  // - Several black or white moves in the same node are an error (a property
  //   can appear only once per node); SGFC issues error 28 and deletes all
  //   duplicate properties, only the property that appears first is retained.
  //
  // Our handling
  // - We are happy with all of these things that SGFC does for us, in fact we
  //   RELY on these things!
  // - We basically follow the same algorithm as Fuego does, with only two
  //   differences:
  //   - We refuse to process the .sgf file if setup properties appear after
  //     the first move.
  //   - SGF allows an AE or AW property in a node beyond the one with the HA
  //     property to clear a handicap stone or change its color. Fuego ignored
  //     this, we actively check this and refuse to process such an .sgf file.

  // Step 1: Collect the points that are touched by SGF setup properties.
  // Cumulative setups in different nodes are taken into account.
  NSMutableDictionary* setupPointsDictionary = [NSMutableDictionary dictionary];
  bool firstMoveFound = false;
  for (SGFCNode* sgfNode in self.sgfMainVariationNodes)
  {
    if (firstMoveFound)
    {
      NSArray* setupProperties = [sgfNode propertiesWithCategory:SGFCPropertyCategorySetup];
      for (SGFCProperty* setupProperty in setupProperties)
      {
        switch (setupProperty.propertyType)
        {
          case SGFCPropertyTypeAB:
          case SGFCPropertyTypeAW:
          case SGFCPropertyTypeAE:
          {
            *errorMessage = @"Game contains stone setup instructions after the first move.\n\nThis is not supported, all board setup must be made prior to the first move.";
            return false;
          }
          default:
          {
            // We are not interested in other setup properties
            continue;
          }
        }
      }
    }
    else
    {
      NSArray* moveProperties = [sgfNode propertiesWithCategory:SGFCPropertyCategoryMove];
      if (moveProperties.count > 0)
      {
        firstMoveFound = true;
        continue;
      }

      // We don't need to follow a particular order in how we process setup
      // properties. The pre-processing done by SGFC guarantees us that in the
      // same node the same point can only appear once.
      NSArray* setupProperties = [sgfNode propertiesWithCategory:SGFCPropertyCategorySetup];
      for (SGFCProperty* setupProperty in setupProperties)
      {
        enum GoColor goColor;
        SGFCPropertyType propertyType = setupProperty.propertyType;
        if (propertyType == SGFCPropertyTypeAB)
          goColor = GoColorBlack;
        else if (propertyType == SGFCPropertyTypeAW)
          goColor = GoColorWhite;
        else if (propertyType == SGFCPropertyTypeAE)
          goColor = GoColorNone;
        else
          continue;  // We are not interested in other setup properties

        NSArray* setupPropertyValues = setupProperty.propertyValues;
        for (id<SGFCPropertyValue> setupPropertyValue in setupPropertyValues)
        {
          SGFCGoPoint* goPoint;
          if (propertyType == SGFCPropertyTypeAE)
            goPoint = setupPropertyValue.toSingleValue.toPointValue.toGoPointValue.goPoint;
          else
            goPoint = setupPropertyValue.toSingleValue.toStoneValue.toGoStoneValue.goStone.location;

          if (! goPoint)
          {
            *errorMessage = @"SgfcKit interfacing error while determining setup stones: Missing SGFCGoPoint object.";
            return false;
          }
          if (! [goPoint hasPositionInGoPointNotation:SGFCGoPointNotationHybrid])
          {
            *errorMessage = @"SgfcKit interfacing error while determining setup stones: SGFCGoPoint not available in hybrid notation.";
            return false;
          }

          NSString* vertexString = [goPoint positionInGoPointNotation:SGFCGoPointNotationHybrid];
          // Overwriting previous values works because keys are compared for
          // equality, not for object identity
          setupPointsDictionary[vertexString] = [NSNumber numberWithInt:goColor];
        }
      }
    }
  }

  // Step 2: Filter out empty points and validate that handicap stones set up
  // in the game info node are not manipulated by setup properties in later
  // nodes.
  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;
  NSMutableArray* blackSetupPoints = [NSMutableArray arrayWithCapacity:0];
  NSMutableArray* whiteSetupPoints = [NSMutableArray arrayWithCapacity:0];
  NSMutableArray* handicapPoints = [game.handicapPoints mutableCopy];
  __block bool success = true;
  [setupPointsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSNumber* goColorAsNumber, BOOL* stop)
  {
    enum GoColor goColor = [goColorAsNumber intValue];
    if (goColor == GoColorNone)
      return;

    GoPoint* point;
    @try
    {
      point = [board pointAtVertex:vertexString];
    }
    @catch (NSException* exception)
    {
      // If the vertex is not legal an exception is raised:
      // - NSInvalidArgumentException if vertex is malformed
      // - NSRangeException if vertex compounds are out of range
      // For our purposes, both exception types are the same.
      NSString* errorMessageFormat = @"Game contains an invalid board setup prior to the first move.\n\nThe intersection %@ is invalid.";
      *errorMessage = [NSString stringWithFormat:errorMessageFormat, vertexString];
      *stop = YES;
      success = false;
      return;
    }

    if (goColor == GoColorBlack)
    {
      if ([handicapPoints containsObject:point])
      {
        [handicapPoints removeObject:point];
        return;
      }

      [blackSetupPoints addObject:point];
    }
    else
    {
      [whiteSetupPoints addObject:point];
    }
  }];

  if (! success)
    return false;

  // If at this point there are still handicap stones in the array this means
  // that all setup properties combined have manipulated the leftover points
  // so that they no longer contain a black handicap stone, but instead contain
  // either a white stone (AW), or are empty (AE). Because Little Go will
  // continue to use the handicap stones this opens up the possiblity that
  // certain moves in the SGF will be considered illegal by Little Go (e.g.
  // a move might attempt to place a stone on a point that is now empty). To
  // avoid this situation we refuse to continue.
  if (handicapPoints.count > 0)
  {
    NSMutableArray* handicapVertexStrings = [NSMutableArray array];
    for (GoPoint* handicapPoint in handicapPoints)
      [handicapVertexStrings addObject:handicapPoint.vertex.string];

    *errorMessage = [NSString stringWithFormat:@"One or more black handicap stones are removed or redefined to white stones after they are set up. Affected handicap stone(s):\n\n%@",
                     [handicapVertexStrings componentsJoinedByString:@", "]];
    return false;
  }

  // Step 3: Apply to GoGame
  @try
  {
    // GoGame takes care to place black and white stones on the points
    game.blackSetupPoints = blackSetupPoints;
    game.whiteSetupPoints = whiteSetupPoints;
  }
  @catch (NSException* exception)
  {
    // This can happen if the setup results in a position where a stone has
    // 0 (zero) liberties
    NSString* errorMessageFormat = @"Game contains an invalid board setup prior to the first move.\n\n%@";
    *errorMessage = [NSString stringWithFormat:errorMessageFormat, exception.reason];
    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the player to play first for the new game.
///
/// If no player is set up to play first explicitly, the game logic determines
/// the player who plays first (e.g. in a normal game with no handicap, black
/// plays first).
// -----------------------------------------------------------------------------
- (bool) setupSetupPlayer:(NSString**)errorMessage
{
  // Implementation in Fuego of the "list_setup_player" GTP command
  // - Examine nodes of the main variation up to the first node that contains
  //   a move property
  // - If a node contains the PL property its value is extracted and used
  // - If the PL property appears again in a later node its value overwrites
  //   the previous value
  //
  // SGFC behaviour
  // - The PL property is not restricted to the root node or a game info
  //   node. It can appear in the root node, in a game info node, before or
  //   after a game info node, before or after nodes that contain move nodes
  // - Setup and move properties cannot appear in the same node; SGFC issues
  //   error 30 and deletes the PL property (unlike with AB, AW and AE where it
  //   retains those properties and splits them off into a newly created node).
  // - If the PL property contains an illegal value the property is deleted and
  //   error 14 is issued
  // - If the PL property contains a lowercase color value it is converted to
  //   the proper uppercase value and error 15 is issued
  //
  // Our handling
  // - Same as Fuego, the only difference being that we refuse to process the
  //   .sgf file if the PL property appears after the first move.

  enum GoColor setupFirstMoveColor = GoColorNone;

  bool firstMoveFound = false;
  for (SGFCNode* sgfNode in self.sgfMainVariationNodes)
  {
    if (firstMoveFound)
    {
      SGFCProperty* setupPlayerProperty = [sgfNode propertyWithType:SGFCPropertyTypePL];
      if (setupPlayerProperty)
      {
        *errorMessage = @"The SGF data contains player setup instructions after the first move.";
        return false;
      }
    }
    else
    {
      NSArray* moveProperties = [sgfNode propertiesWithCategory:SGFCPropertyCategoryMove];
      if (moveProperties.count > 0)
      {
        firstMoveFound = true;
        continue;
      }

      SGFCProperty* setupPlayerProperty = [sgfNode propertyWithType:SGFCPropertyTypePL];
      if (! setupPlayerProperty)
        continue;

      SGFCColor sgfSetupPlayerColorValue = setupPlayerProperty.propertyValue.toSingleValue.toColorValue.colorValue;
      setupFirstMoveColor = (sgfSetupPlayerColorValue == SGFCColorBlack) ? GoColorBlack : GoColorWhite;
    }
  }

  GoGame* game = [GoGame sharedGame];
  game.setupFirstMoveColor = setupFirstMoveColor;

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Sets up komi for the new game.
// -----------------------------------------------------------------------------
- (bool) setupKomi:(NSString**)errorMessage
{
  // Implementation in Fuego of the "get_komi" GTP command
  // - Returns the komi that is set in the game's rules
  // - The komi in the game's rules is set immediately when the "loadsgf"
  //   GTP command is executed from the node that contains the KM property.
  // - Searching for the KM property is started in the last node of the main
  //   variation. The search then continues backwards until the root node is
  //   reached. The first node that contains a KM property is used.
  //
  // SGFC behaviour
  // - The first node that contains a game info property is considered to be
  //   a game info node. If another node further down the tree contains
  //   another game info property SGFC warns about this with error 44 and
  //   deletes the later game info property.
  //
  // Our handling
  // - Differently than Fuego, we expect the KM property in the game info node

  double komi = 0.0;

  SGFCProperty* komiProperty = [self.sgfGameInfoNode propertyWithType:SGFCPropertyTypeKM];
  if (komiProperty)
  {
    NSString* komiString = komiProperty.propertyValue.toSingleValue.rawValue;
    if (0 == komiString.length)
      komi = 0.0;
    else
      komi = [komiString doubleValue];
  }

  GoGame* game = [GoGame sharedGame];
  game.komi = komi;

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the moves for the new game.
// -----------------------------------------------------------------------------
- (bool) setupMoves:(NSString**)errorMessage
{
  // Implementation in Fuego of the "list_moves" GTP command
  // - Examine all nodes of the main variation
  // - If the node contains a move property, list it
  // - Pass moves are listed as "pass", a resignation is listed as "resign"
  //
  // SGFC behaviour
  // - A move that plays a stone on an occupied intersection is warned about
  //   with warning 58, but SGFC does nothing about it
  //
  // Our handling
  // - Same as Fuego, the only difference being that we don't have a "resign"
  //   move

  NSMutableArray* moveProperties = [NSMutableArray array];

  for (SGFCNode* sgfNode in self.sgfMainVariationNodes)
  {
    NSArray* moveCategoryProperties = [sgfNode propertiesWithCategory:SGFCPropertyCategoryMove];
    for (SGFCProperty* moveCategoryProperty in moveCategoryProperties)
    {
      SGFCPropertyType propertyType = moveCategoryProperty.propertyType;
      if (propertyType != SGFCPropertyTypeB && propertyType != SGFCPropertyTypeW)
        continue;  // not interested in other move properties

      [moveProperties addObject:moveCategoryProperty];
    }
  }

  return [self replayMoves:moveProperties errorMessage:errorMessage];
}

// -----------------------------------------------------------------------------
/// @brief Replays the moves in @a moveList.
///
/// @a moveList is expected to contain SGFCProperty objects of type
/// #SGFCPropertyTypeB and #SGFCPropertyTypeW.
///
/// The asynchronous command delegate is updated continuously with progress
/// information as the moves are replayed. In an ideal world we would have
/// fine-grained progress updates with as many steps as there are moves.
/// However, when there are many moves to be replayed this wastes a lot of
/// precious CPU cycles for GUI updates, considerably slowing down the process
/// of loading a game - on older devices to an intolerable level. In the real
/// world, we therefore limit the number of progress updates to a fixed,
/// hard-coded number.
// -----------------------------------------------------------------------------
- (bool) replayMoves:(NSArray*)moveList errorMessage:(NSString**)errorMessage
{
  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  float movesPerStep;
  NSUInteger remainingNumberOfSteps;
  if (moveList.count <= maxStepsForReplayMoves)
  {
    movesPerStep = 1;
    remainingNumberOfSteps = moveList.count;
  }
  else
  {
    movesPerStep = moveList.count / maxStepsForReplayMoves;
    remainingNumberOfSteps = maxStepsForReplayMoves;
  }
  float remainingProgress = 1.0 - self.progress;
  // Adjust for increaseProgressAndNotifyDelegate()
  self.stepIncrease = remainingProgress / remainingNumberOfSteps;

  @try
  {
    int movesReplayed = 0;
    float nextProgressUpdate = movesPerStep;  // use float in case movesPerStep has fractions
    for (SGFCProperty* moveProperty in moveList)
    {
      SGFCGoMove* goMove = moveProperty.propertyValue.toSingleValue.toMoveValue.toGoMoveValue.goMove;
      if (! goMove)
      {
        *errorMessage = @"SgfcKit interfacing error while determining moves: Missing SGFCGoMove object.";
        return false;
      }

      enum GoColor moveColor;
      SGFCPropertyType propertyType = moveProperty.propertyType;
      if (propertyType == SGFCPropertyTypeB)
        moveColor = GoColorBlack;
      else if (propertyType == SGFCPropertyTypeW)
        moveColor = GoColorWhite;

      enum GoMoveType moveType;
      GoPoint* point;
      if (goMove.isPassMove)
      {
        moveType = GoMoveTypePass;
        point = nil;
      }
      else
      {
        moveType = GoMoveTypePlay;

        SGFCGoPoint* goPoint = goMove.stone.location;
        if (! [goPoint hasPositionInGoPointNotation:SGFCGoPointNotationHybrid])
        {
          *errorMessage = @"SgfcKit interfacing error while determining moves: SGFCGoPoint not available in hybrid notation.";
          return false;
        }

        NSString* vertexString = [goPoint positionInGoPointNotation:SGFCGoPointNotationHybrid];
        @try
        {
          point = [board pointAtVertex:vertexString];
        }
        @catch (NSException* exception)
        {
          // If the vertex is not legal an exception is raised:
          // - NSInvalidArgumentException if vertex is malformed
          // - NSRangeException if vertex compounds are out of range
          // For our purposes, both exception types are the same.
          NSString* errorMessageFormat = @"Move string contains invalid intersection.\n\n%@";
          *errorMessage = [NSString stringWithFormat:errorMessageFormat, exception.reason];
          return false;
        }
      }

      // Here we support if the .sgf contains moves by non-alternating colors,
      // anywhere in the game. Thus the user can ***VIEW*** almost any .sgf
      // game, even though the app itself is not capable of producing such
      // games.
      game.nextMoveColor = moveColor;

      NSString* colorName = [NSString stringWithGoColor:moveColor];
      if (GoGameStateGameHasEnded == game.state)
      {
        [game revertStateFromEndedToInProgress];
      }
      if (GoMoveTypePass == moveType)
      {
        [game pass];
      }
      else
      {
        enum GoMoveIsIllegalReason illegalReason;
        if (! [game isLegalMove:point byColor:moveColor isIllegalReason:&illegalReason])
        {
          NSString* errorMessageFormat = @"Game contains an illegal move: Move %d, played by %@, on intersection %@. Reason: %@.";
          NSString* illegalReasonString = [NSString stringWithMoveIsIllegalReason:illegalReason];
          *errorMessage = [NSString stringWithFormat:errorMessageFormat, (movesReplayed + 1), colorName, point.vertex.string, illegalReasonString];
          return false;
        }
        [game play:point];
      }

      ++movesReplayed;
      if (movesReplayed >= nextProgressUpdate)
      {
        nextProgressUpdate += movesPerStep;
        [self increaseProgressAndNotifyDelegate];
      }
    }
  }
  @catch (NSException* exception)
  {
    NSString* errorMessageFormat = @"An unexpected error occurred loading the game. To improve this app, please consider submitting a bug report with the game file attached.\n\nException name: %@.\n\nException reason: %@.";
    *errorMessage = [NSString stringWithFormat:errorMessageFormat, [exception name], [exception reason]];
    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the result for the new game.
// -----------------------------------------------------------------------------
- (bool) setupGameResult:(NSString**)errorMessage
{
  GoGame* game = [GoGame sharedGame];

  SGFCGameResult sgfGameResult = self.sgfGoGameInfo.gameResult;
  if (sgfGameResult.IsValid)
  {
    enum GoGameHasEndedReason reasonForGameHasEnded = [SgfUtilities goGameHasEndedReasonForGameResult:sgfGameResult];
    
    // Some SGFCGameResult values actually cannot be mapped to a corresponding
    // GoGameHasEndedReason value
    if (reasonForGameHasEnded != GoGameHasEndedReasonNotYetEnded)
    {
      if (game.state == GoGameStateGameHasEnded)
        [game revertStateFromEndedToInProgress];
      game.reasonForGameHasEnded = reasonForGameHasEnded;
      game.state = GoGameStateGameHasEnded;
    }
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Synchronizes the state of the GTP engine with the state of the
/// current GoGame.
///
/// This method invokes SyncGTPEngineCommand. It expects that NewGameCommand
/// has set up the GTP engine with a number of other things, notably the board
/// size and the game rules.
// -----------------------------------------------------------------------------
- (bool) syncGtpEngine:(NSString**)errorMessage
{
  bool syncSuccess = [[[[SyncGTPEngineCommand alloc] init] autorelease] submit];
  if (syncSuccess)
  {
    return true;
  }
  else
  {
    *errorMessage = @"Failed to synchronize the GTP engine state with the current GoGame state";
    return false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Notifies the GoGameDocument associated with the new game that the
/// game was loaded.
// -----------------------------------------------------------------------------
- (void) notifyGoGameDocument
{
  // TODO xxx fix. Possibly change and attach the SgfcKit objects
  NSString* gameName = @"dummy document name";
  [[GoGame sharedGame].document load:gameName];
}

// -----------------------------------------------------------------------------
/// @brief Triggers the computer player to make a move, if it is his turn.
///
/// This method, and with it ComputerPlayMoveCommand, must be executed on the
/// main thread. Reason:
/// - When ComputerPlayMoveCommand receives the GTP response with the computer
///   player's move, it triggers various UIKit updates
/// - These updates must happen on the main thread because UIKit drawing must
///   happen on the main thread
/// - ComputerPlayMoveCommand receives the GTP response in the same thread
///   context that it is executed in. So for the GTP response to be received
///   on the main thread, ComputerPlayMoveCommand itself must also be executed
///   on the main thread.
///
/// LoadGameCommand's long-running action cannot help us delay UIKit updates in
/// this scenario, because by the time that ComputerPlayMoveCommand receives its
/// GTP response, LoadGameCommand has long since terminated its long-running
/// action.
// -----------------------------------------------------------------------------
- (void) triggerComputerPlayerOnMainThread
{
  GoGame* game = [GoGame sharedGame];
  if (game.nextMovePlayerIsComputerPlayer)
  {
    if (self.restoreMode)
    {
      if (GoGameTypeComputerVsComputer == game.type)
      {
        // The game may already have ended, in which case there is no need to
        // pause (in fact, we must not pause, otherwise we trigger an exception)
        if (GoGameStateGameHasEnded != game.state)
          [game pause];
      }
    }
    else
    {
      [[[[ComputerPlayMoveCommand alloc] init] autorelease] submit];
      self.didTriggerComputerPlayer = true;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Displays "failed to load game" alert with the error details stored
/// in @a message.
// -----------------------------------------------------------------------------
- (void) showAlert:(NSString*)message
{
  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Failed to load game"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction* action) {}];
  [alertController addAction:okAction];

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for various methods.
// -----------------------------------------------------------------------------
- (void) increaseProgressAndNotifyDelegate
{
  self.progress += self.stepIncrease;
  [self.asynchronousCommandDelegate asynchronousCommand:self didProgress:self.progress nextStepMessage:nil];
}

// -----------------------------------------------------------------------------
/// @brief Performs all steps required to handle failed command execution.
///
/// Failure may occur during any of the steps in this command. An alert with
/// @a message is displayed to notify the user of the problem. In addition, the
/// message is written to the application log.
// -----------------------------------------------------------------------------
- (void) handleCommandFailed:(NSString*)message
{
  // The SGF data was erroneous. Setup new data with default values that lets
  // the command start a new game anyway. The default values are guaranteed to
  // work, which allows to bring the app back into a controlled state.
  // Notes:
  // - An empty SGFCNode without properties provides us with a game with
  //   no komi, no handicap, no setup and no moves.
  // - The SGFCGameInfo object is guaranteed to be a SGFCGoGameInfo object
  //   because the default game type is Go.
  // - The default board size is 19x19.
  // TODO xxx possibly setup up the node with data from NewGameModel?
  self.sgfGameInfoNode = [SGFCNode node];
  self.sgfGoGameInfo = self.sgfGameInfoNode.gameInfo.toGoGameInfo;
  self.sgfMainVariationNodes = self.sgfGameInfoNode.mainVariationNodes;

  // Alert must be shown on main thread, otherwise there is the possibility of
  // a crash (it's real, I've seen the crash reports!)
  [self performSelectorOnMainThread:@selector(showAlert:) withObject:message waitUntilDone:YES];
  DDLogError(@"%@", message);
}

@end
