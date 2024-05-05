// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameDocument.h"
#import "../../go/GoMove.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeAdditions.h"
#import "../../go/GoNodeAnnotation.h"
#import "../../go/GoNodeMarkup.h"
#import "../../go/GoNodeModel.h"
#import "../../go/GoNodeSetup.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpUtilities.h"
#import "../../main/ApplicationDelegate.h"
#import "../../newgame/NewGameModel.h"
#import "../../sgf/SgfUtilities.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/NSStringAdditions.h"

// Constants
static const int maxStepsForCreateNodes = 9;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LoadGameCommand.
// -----------------------------------------------------------------------------
@interface LoadGameCommand()
@property(nonatomic, retain) SGFCNode* sgfGameInfoNode;
@property(nonatomic, retain) SGFCGoGameInfo* sgfGoGameInfo;
@property(nonatomic, retain) SGFCGame* sgfGame;
@property(nonatomic, retain) SGFCNode* sgfRootNode;
@property(nonatomic, assign) int totalSteps;
@property(nonatomic, assign) float stepIncrease;
@property(nonatomic, assign) float progress;
@end


@implementation LoadGameCommand

@synthesize asynchronousCommandDelegate;
@synthesize showProgressHUD;


#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a LoadGameCommand object that will load the game from
/// the SGF data referenced by @a sgfGameInfoNode.
///
/// @note This is the designated initializer of LoadGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithGameInfoNode:(SGFCNode*)sgfGameInfoNode goGameInfo:(SGFCGoGameInfo*)sgfGoGameInfo game:(SGFCGame*)sgfGame
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.showProgressHUD = true;

  self.sgfGameInfoNode = sgfGameInfoNode;
  self.sgfGoGameInfo = sgfGoGameInfo;
  self.sgfGame = sgfGame;
  self.sgfRootNode = nil;

  self.restoreMode = false;
  self.didTriggerComputerPlayer = false;

  self.totalSteps = (6 + maxStepsForCreateNodes);  // 6 steps before node creation begins
  self.stepIncrease = 1.0 / self.totalSteps;
  self.progress = 0.0;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LoadGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.sgfGameInfoNode = nil;
  self.sgfGoGameInfo = nil;
  self.sgfGame = nil;
  self.sgfRootNode = nil;

  [super dealloc];
}

#pragma mark - CommandBase methods

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
          errorMessage = [@"Loading a game failed. Setting up a game with default values failed, too. The error message is:\n\n" stringByAppendingString:errorMessage];
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
  success = [self pruneNodeTreeAndSetRootNode:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self setupHandicap:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self setupKomi:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self setupNodes:errorMessage];
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

#pragma mark - Step 1: Start new game

// -----------------------------------------------------------------------------
/// @brief Starts the new game.
// -----------------------------------------------------------------------------
- (bool) startNewGame:(NSString**)errorMessage
{
  enum GoBoardSize goBoardSize = [SgfUtilities goBoardSizeForSgfBoardSize:self.sgfGoGameInfo.boardSize
                                                             errorMessage:errorMessage];
  if (goBoardSize == GoBoardSizeUndefined)
    return false;

  // Temporarily re-configure NewGameModel with the new board size from the
  // loaded game
  NewGameModel* model = [ApplicationDelegate sharedDelegate].theNewGameModel;
  enum GoBoardSize oldBoardSize = model.boardSize;
  model.boardSize = goBoardSize;

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
  // Handicap and komi will later be set up by SyncGTPEngineCommand
  command.shouldSetupGtpHandicapAndKomi = false;
  // We have to do this ourselves, after setting up handicap + moves
  command.shouldTriggerComputerPlayerIfItIsTheirTurn = false;
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

#pragma mark - Step 2: Prune node tree

// -----------------------------------------------------------------------------
/// @brief Prunes the tree of SGFCNode objects, i.e. removes unwanted SGFCNode
/// objects that are not related to the game info node with which
/// LoadGameCommand was initialized. After this method is invoked, the remainder
/// of LoadGameCommand can safely iterate depth-first over the tree of nodes,
/// starting with self.sgfRootNode. Sets self.sgfRootNode as a side-effect.
// -----------------------------------------------------------------------------
- (bool) pruneNodeTreeAndSetRootNode:(NSString**)errorMessage
{
  SGFCTreeBuilder* treeBuilder = self.sgfGame.treeBuilder;

  SGFCNode* node = self.sgfGameInfoNode;
  while (node.hasParent)
  {
    SGFCNode* parent = node.parent;

    for (SGFCNode* child in parent.children)
    {
      if ([child isEqualToNode:node])
        continue;

      [treeBuilder removeChild:child fromNode:parent];
    }

    node = parent;
  }

  self.sgfRootNode = node;

  return true;
}

#pragma mark - Step 3: Setup handicap

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
  // - If we find handicap stones in the game info node, as per above, then we
  //   treat the existence of any of the setup properties AB, AW and/or AE in a
  //   node before the game info node as an error. The reason is that, at the
  //   moment, the app stores handicap stones in GoGame, which can be seen as
  //   the same as storing them in the game's root node. This means that the
  //   app has no place to store setup stones that in the SGF appear before
  //   handicap stones (as there can't be nodes before the game's root node).

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
          GoPoint* point = [self goPointForSgfGoPoint:handicapStonesPropertyValue.toSingleValue.toStoneValue.toGoStoneValue.goStone.location
                                              onBoard:board
                                         errorMessage:errorMessage];
          if (! point)
          {
            *errorMessage = [@"SgfcKit interfacing error while determining the handicap: " stringByAppendingString:*errorMessage];
            return false;
          }

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
        *errorMessage = [NSString stringWithFormat:@"The handicap (%ld) is greater than the number of black setup stones (%lu).", expectedNumberOfHandicapStones, (unsigned long)actualNumberOfHandicapStones];
        return false;
      }
    }
  }

  if (handicapPoints.count > 0)
  {
    SGFCNode* node = self.sgfGameInfoNode.parent;
    while (node)
    {
      NSArray* setupProperties = [node propertiesWithCategory:SGFCPropertyCategorySetup];
      for (SGFCProperty* setupProperty in setupProperties)
      {
        SGFCPropertyType propertyType = setupProperty.propertyType;
        if (propertyType == SGFCPropertyTypeAB || propertyType == SGFCPropertyTypeAW || propertyType == SGFCPropertyTypeAE)
        {
          NSUInteger numberOfPropertyValues = setupProperty.propertyValues.count;
          if (numberOfPropertyValues > 0)
          {
            *errorMessage = [NSString stringWithFormat:@"Found property %@, which places or removes %lu setup stones, in a node before handicap stones were set up.", setupProperty.propertyName, (unsigned long)numberOfPropertyValues];
            return false;
          }
        }
      }

      node = node.parent;
    }
  }

  // NewGameCommand already has set up GoGame with a handicap. Here we overwrite
  // it with the new handicap from the SGF data. We do this even if the
  // handicapPoints array is empty.
  // Note: GoGame takes care to place black stones on the points
  game.handicapPoints = handicapPoints;

  return true;
}

#pragma mark - Step 4: Setup komi

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

#pragma mark - Step 5: Setup nodes + content (annotations, markup, setup, moves)

// -----------------------------------------------------------------------------
/// @brief Sets up the nodes for the new game.
///
/// The setup consists of three phases:
/// - Phase 1: Process SGFCNode objects and transfer the data found into GoNode
///   objects. In other words: Translate SGFCKit data structures into data
///   structures understood by the rest of this app. This phase already contains
///   some validation, such as are there any setup properties found after the
///   first move. For details see createNodes:().
/// - Phase 2: Validate setup information and moves to make sure that no board
///   positions are created that the app considers to be illegal. A by-product
///   of this phase is that, after the phase ends, the board state is set up
///   for the last node of the main game variation. For details see
///   validateSetupAndMoveNodes:errorMessage:().
/// - Phase 3: Fix the state of the remaining Go model objects so that
///   everything is set up for the app to display the last board position of the
///   main game variation. For details see fixStateOfGoModelObjects:().
///
/// Once all the phases have been gone through, a number of notifications are
/// posted to the default notification center to inform the rest of the
/// application about the final state of the Go model. For details see
/// notifyApplicationAboutFinalGoModelState:().
// -----------------------------------------------------------------------------
- (bool) setupNodes:(NSString**)errorMessage
{
  @try
  {
    int numberOfNodesInGameTree;
    bool success = [self createNodes:&numberOfNodesInGameTree errorMessage:errorMessage];
    if (! success)
      return false;

    success = [self validateSetupAndMoveNodes:numberOfNodesInGameTree errorMessage:errorMessage];
    if (! success)
      return false;

    success = [self fixStateOfGoModelObjects:errorMessage];
    if (! success)
      return false;

    return [self notifyApplicationAboutFinalGoModelState:errorMessage];
  }
  @catch (NSException* exception)
  {
    NSString* errorMessageFormat = @"An unexpected error occurred loading the game. To improve this app, please consider submitting a bug report with the game file attached.\n\nException name: %@.\n\nException reason: %@.";
    *errorMessage = [NSString stringWithFormat:errorMessageFormat, [exception name], [exception reason]];
    return false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates a new tree of GoNode objects whose structure and content
/// mostly corresponds to the tree of SGFCNode objects that starts with
/// @e self.sgfRootNode.
///
/// Iterates depth-first over the tree of nodes found in @e self.sgfRootNode.
/// Creates a GoNode object for every SGFCNode object encountered that contains
/// at least one SGF property recognized by the app. SGFCNode objects that do
/// not contain a property recognized by the app are skipped. The newly created
/// GoNode objects form a new tree with the same structure as the tree of
/// SGFCNode objects.
///
/// If the root SGFCNode contains a move property (B or W), an extra GoNode
/// object is created as a child node of the root GoNode to hold the values of
/// @b ALL properties listed below. One SGFCNode object in this case results in
/// @b TWO GoNode objects. This is important because the app is modeled to not
/// expect moves in board position 0. This is supported by the SGF
/// specification, according to which move properties in the root node are not
/// illegal but bad style.
///
/// @note If an extra GoNode object is created, @b ALL properties are shifted
/// to it, not just the move property that caused the extra GoNode object to
/// be created. The reason is that it is not possible to tell which of the
/// property values have a meaning that is related to the move, and which of the
/// values are unrelated. The assumption is that the property values form one
/// context that should not be split.
///
/// This is a helper function for setupNodes:().
// -----------------------------------------------------------------------------
- (bool) createNodes:(int*)numberOfNodesInGameTree errorMessage:(NSString**)errorMessage
{
  GoGame* game = [GoGame sharedGame];
  GoNodeModel* nodeModel = game.nodeModel;

  __block GoNode* goParentNode = nodeModel.rootNode;
  *numberOfNodesInGameTree = 1;  // start with 1 for the root node
  int numberOfMovesFoundBeforeCurrentNode = 0;
  GoMove* previousMove = nil;

  NSMutableArray* stack = [NSMutableArray array];
  NSNull* nullValue = [NSNull null];

  bool sgfCurrentNodeIsRootNode = true;
  SGFCNode* sgfCurrentNode = self.sgfRootNode;

  // Reusable local function. goParentNode needs to be marked with __block for
  // it to be accessible within the block.
  void (^addNewNodeToTree) (GoNode*, GoNode**) = ^(GoNode* goNewNode, GoNode** goMostRecentContentNode)
  {
    [goParentNode appendChild:goNewNode];
    (*numberOfNodesInGameTree)++;

    *goMostRecentContentNode = goNewNode;
  };

  while (true)
  {
    while (sgfCurrentNode)
    {
      GoNode* goNewNode = [GoNode node];
      bool success = [self populateGoNode:goNewNode
                withPropertiesFromSgfNode:sgfCurrentNode
                             previousMove:previousMove
                             errorMessage:errorMessage];
      if (! success)
        return false;

      GoNode* goMostRecentContentNode = nil;
      if (goNewNode.isEmpty)
      {
        // Skip nodes without content for us to keep. Typical examples are a
        // root node or a game info node without any other content than root
        // properties or game info properties.
        // Note: If the skipped node is a branching point in the tree, all of
        // its child nodes are added as child nodes to the skipped node's parent
        // in the skipped node's place.

        if (sgfCurrentNodeIsRootNode)
        {
          sgfCurrentNodeIsRootNode = false;

          // goParentNode is still == nodeModel.rootNode at this point
          goMostRecentContentNode = goParentNode;
          goParentNode = nil;

        }
        else
        {
          goMostRecentContentNode = goParentNode;
          goParentNode = goMostRecentContentNode.parent;
        }
      }
      else
      {
        if (sgfCurrentNodeIsRootNode)
        {
          sgfCurrentNodeIsRootNode = false;

          // If the SGF root node didn't contain a move, then we can keep the
          // SGF node's content in our own root node. Otherwise we have to push
          // the content into a new node because the app wants to display moves
          // as a separate board position.
          if (! goNewNode.goMove)
          {
            GoNode* rootNode = nodeModel.rootNode;

            rootNode.goNodeSetup = goNewNode.goNodeSetup;
            rootNode.goMove = goNewNode.goMove;
            rootNode.goNodeAnnotation = goNewNode.goNodeAnnotation;
            rootNode.goNodeMarkup = goNewNode.goNodeMarkup;

            goMostRecentContentNode = rootNode;
            goParentNode = nil;
          }
          else
          {
            addNewNodeToTree(goNewNode, &goMostRecentContentNode);
          }
        }
        else
        {
          addNewNodeToTree(goNewNode, &goMostRecentContentNode);
        }
      }

      // The stack not only remembers sgfCurrentNode (which is important for
      // driving the iteration) but also some context information that we need
      // to build our own model:
      // - The node that will be the parent of the next sibling
      // - The number of moves found so far in this branch of the tree
      // - The move that will be the parent move (or previous move) of the next
      //   move found in the next sibling branch
      [stack addObject:@[sgfCurrentNode, goParentNode ? goParentNode : nullValue, [NSNumber numberWithInt:numberOfMovesFoundBeforeCurrentNode], previousMove ? previousMove : nullValue]];

      goParentNode = goMostRecentContentNode;
      if (goMostRecentContentNode.goMove)
      {
        previousMove = goMostRecentContentNode.goMove;
        numberOfMovesFoundBeforeCurrentNode++;
        
        // If we don't perform this check here the game fails to load during the
        // GTP engine sync. However, the error message in that case is much less
        // nice. Also if the maximum is not exceeded on the main variation, the
        // sync failure does not occur immediately, it will occur only when the
        // user switches to the affected variation. We want to avoid such
        // surprises, so we refuse to load the game right at the start.
        if (numberOfMovesFoundBeforeCurrentNode > maximumNumberOfMoves)
        {
          *errorMessage = [NSString stringWithFormat:@"The SGF data contains a variation with %d or more moves. This is more than the maximum number of moves (%d) that the computer player Fuego can process.", numberOfMovesFoundBeforeCurrentNode, maximumNumberOfMoves];
          return false;
        }
      }

      sgfCurrentNode = sgfCurrentNode.firstChild;
    }

    if (stack.count > 0)
    {
      NSArray* tuple = stack.lastObject;
      [stack removeLastObject];

      sgfCurrentNode = [tuple objectAtIndex:0];
      goParentNode = [tuple objectAtIndex:1];
      if ((id)goParentNode == nullValue)
        goParentNode = nil;
      NSNumber* numberOfMovesFoundBeforeCurrentNodeAsNumber = [tuple objectAtIndex:2];
      numberOfMovesFoundBeforeCurrentNode = numberOfMovesFoundBeforeCurrentNodeAsNumber.intValue;
      previousMove = [tuple objectAtIndex:3];
      if ((id)previousMove == nullValue)
        previousMove = nil;

      sgfCurrentNode = sgfCurrentNode.nextSibling;
    }
    else
    {
      // We're done
      break;
    }
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Populates @a goNode with data found in @a sgfNode that comes from
/// SGF properties that are recognized by the app.
///
/// SGF properties recognized by the app:
/// - All setup properties: AB, AW, AE, PL.
/// - Move properties B and W. Properties KO and MN are currently ignored.
/// - All node annotation properties: C, N, GB, GW, DM, UC, V, HO.
/// - All move annotation properties: TE, DO, BM, IT.
/// - All markup properties: CR, SQ, TR, MA, SL, AR, LN, LB, DD
///
/// This is a helper function for createNodes:errorMessage:().
// -----------------------------------------------------------------------------
  - (bool) populateGoNode:(GoNode*)goNode
withPropertiesFromSgfNode:(SGFCNode*)sgfNode
             previousMove:(GoMove*)previousMove
             errorMessage:(NSString**)errorMessage
{
  GoGame* game = [GoGame sharedGame];
  bool sgfNodeIsGameInfoNode = [sgfNode isEqualToNode:self.sgfGameInfoNode];

  GoNodeSetup* goNodeSetup = [[[GoNodeSetup alloc] initWithGame:game] autorelease];
  GoMove* goMove = nil;
  enum GoMoveValuation goMoveValuation = GoMoveValuationNone;
  GoNodeAnnotation* goNodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  bool atLeastOneAnnotationPropertyWasFound = false;
  GoNodeMarkup* goNodeMarkup = [[[GoNodeMarkup alloc] init] autorelease];

  for (SGFCProperty* sgfProperty in sgfNode.properties)
  {
    SGFCPropertyType propertyType = sgfProperty.propertyType;

    if (sgfProperty.propertyCategory == SGFCPropertyCategorySetup)
    {
      bool success = [self populateGoNodeSetup:goNodeSetup
                             withSetupProperty:sgfProperty
                           foundInGameInfoNode:sgfNodeIsGameInfoNode
                                mostRecentMove:previousMove
                                  errorMessage:errorMessage];
      if (! success)
        return false;
    }
    else if (propertyType == SGFCPropertyTypeB || propertyType == SGFCPropertyTypeW)
    {
      // SGFC makes sure that the node never contains both SGFCPropertyTypeB and
      // SGFCPropertyTypeW at the same time
      goMove = [self createMoveWithProperty:sgfProperty withPreviousMove:previousMove errorMessage:errorMessage];
    }
    else if (propertyType == SGFCPropertyTypeN)
    {
      goNodeAnnotation.shortDescription = sgfProperty.propertyValue.toSingleValue.toSimpleTextValue.simpleTextValue;
      atLeastOneAnnotationPropertyWasFound = true;
    }
    else if (propertyType == SGFCPropertyTypeC)
    {
      goNodeAnnotation.longDescription = sgfProperty.propertyValue.toSingleValue.toTextValue.textValue;
      atLeastOneAnnotationPropertyWasFound = true;
    }
    else if (propertyType == SGFCPropertyTypeGB)
    {
      if (sgfProperty.propertyValue.toSingleValue.toDoubleValue.doubleValue == SGFCDoubleNormal)
        goNodeAnnotation.goBoardPositionValuation = GoBoardPositionValuationGoodForBlack;
      else
        goNodeAnnotation.goBoardPositionValuation = GoBoardPositionValuationVeryGoodForBlack;
      atLeastOneAnnotationPropertyWasFound = true;
    }
    else if (propertyType == SGFCPropertyTypeGW)
    {
      if (sgfProperty.propertyValue.toSingleValue.toDoubleValue.doubleValue == SGFCDoubleNormal)
        goNodeAnnotation.goBoardPositionValuation = GoBoardPositionValuationGoodForWhite;
      else
        goNodeAnnotation.goBoardPositionValuation = GoBoardPositionValuationVeryGoodForWhite;
      atLeastOneAnnotationPropertyWasFound = true;
    }
    else if (propertyType == SGFCPropertyTypeDM)
    {
      if (sgfProperty.propertyValue.toSingleValue.toDoubleValue.doubleValue == SGFCDoubleNormal)
        goNodeAnnotation.goBoardPositionValuation = GoBoardPositionValuationEven;
      else
        goNodeAnnotation.goBoardPositionValuation = GoBoardPositionValuationVeryEven;
      atLeastOneAnnotationPropertyWasFound = true;
    }
    else if (propertyType == SGFCPropertyTypeUC)
    {
      if (sgfProperty.propertyValue.toSingleValue.toDoubleValue.doubleValue == SGFCDoubleNormal)
        goNodeAnnotation.goBoardPositionValuation = GoBoardPositionValuationUnclear;
      else
        goNodeAnnotation.goBoardPositionValuation = GoBoardPositionValuationVeryUnclear;
      atLeastOneAnnotationPropertyWasFound = true;
    }
    else if (propertyType == SGFCPropertyTypeHO)
    {
      if (sgfProperty.propertyValue.toSingleValue.toDoubleValue.doubleValue == SGFCDoubleNormal)
        goNodeAnnotation.goBoardPositionHotspotDesignation = GoBoardPositionHotspotDesignationYes;
      else
        goNodeAnnotation.goBoardPositionHotspotDesignation = GoBoardPositionHotspotDesignationYesEmphasized;
      atLeastOneAnnotationPropertyWasFound = true;
    }
    else if (propertyType == SGFCPropertyTypeV)
    {
      SGFCReal estimatedScoreValue = sgfProperty.propertyValue.toSingleValue.toRealValue.realValue;
      enum GoScoreSummary estimatedScoreSummary;
      if (estimatedScoreValue > 0.0)
      {
        estimatedScoreSummary = GoScoreSummaryBlackWins;
      }
      else if (estimatedScoreValue < 0.0)
      {
        estimatedScoreSummary = GoScoreSummaryWhiteWins;
        estimatedScoreValue = -estimatedScoreValue;
      }
      else
      {
        estimatedScoreSummary = GoScoreSummaryTie;
      }
      [goNodeAnnotation setEstimatedScoreSummary:estimatedScoreSummary value:estimatedScoreValue];
      atLeastOneAnnotationPropertyWasFound = true;
    }
    else if (propertyType == SGFCPropertyTypeTE)
    {
      if (sgfProperty.propertyValue.toSingleValue.toDoubleValue.doubleValue == SGFCDoubleNormal)
        goMoveValuation = GoMoveValuationGood;
      else
        goMoveValuation = GoMoveValuationVeryGood;
    }
    else if (propertyType == SGFCPropertyTypeBM)
    {
      if (sgfProperty.propertyValue.toSingleValue.toDoubleValue.doubleValue == SGFCDoubleNormal)
        goMoveValuation = GoMoveValuationBad;
      else
        goMoveValuation = GoMoveValuationVeryBad;
    }
    else if (propertyType == SGFCPropertyTypeIT)
    {
      goMoveValuation = GoMoveValuationInteresting;
    }
    else if (propertyType == SGFCPropertyTypeDO)
    {
      goMoveValuation = GoMoveValuationDoubtful;
    }
    else if (propertyType == SGFCPropertyTypeCR)
    {
      bool success = [self setSymbols:GoMarkupSymbolCircle inMarkup:goNodeMarkup forPropertyValues:sgfProperty.propertyValues errorMessage:errorMessage];
      if (! success)
        return nil;
    }
    else if (propertyType == SGFCPropertyTypeSQ)
    {
      bool success = [self setSymbols:GoMarkupSymbolSquare inMarkup:goNodeMarkup forPropertyValues:sgfProperty.propertyValues errorMessage:errorMessage];
      if (! success)
        return nil;
    }
    else if (propertyType == SGFCPropertyTypeTR)
    {
      bool success = [self setSymbols:GoMarkupSymbolTriangle inMarkup:goNodeMarkup forPropertyValues:sgfProperty.propertyValues errorMessage:errorMessage];
      if (! success)
        return nil;
    }
    else if (propertyType == SGFCPropertyTypeMA)
    {
      bool success = [self setSymbols:GoMarkupSymbolX inMarkup:goNodeMarkup forPropertyValues:sgfProperty.propertyValues errorMessage:errorMessage];
      if (! success)
        return nil;
    }
    else if (propertyType == SGFCPropertyTypeSL)
    {
      bool success = [self setSymbols:GoMarkupSymbolSelected inMarkup:goNodeMarkup forPropertyValues:sgfProperty.propertyValues errorMessage:errorMessage];
      if (! success)
        return nil;
    }
    else if (propertyType == SGFCPropertyTypeAR)
    {
      bool success = [self setConnections:GoMarkupConnectionArrow inMarkup:goNodeMarkup forPropertyValues:sgfProperty.propertyValues errorMessage:errorMessage];
      if (! success)
        return nil;
    }
    else if (propertyType == SGFCPropertyTypeLN)
    {
      bool success = [self setConnections:GoMarkupConnectionLine inMarkup:goNodeMarkup forPropertyValues:sgfProperty.propertyValues errorMessage:errorMessage];
      if (! success)
        return nil;
    }
    else if (propertyType == SGFCPropertyTypeLB)
    {
      bool success = [self setLabelsInMarkup:goNodeMarkup forPropertyValues:sgfProperty.propertyValues errorMessage:errorMessage];
      if (! success)
        return nil;
    }
    else if (propertyType == SGFCPropertyTypeDD)
    {
      bool success = [self setDimmingsInMarkup:goNodeMarkup forPropertyValues:sgfProperty.propertyValues errorMessage:errorMessage];
      if (! success)
        return nil;
    }
  }

  if (goMoveValuation != GoMoveValuationNone)
  {
    if (goNode.goMove)
    {
      goNode.goMove.goMoveValuation = goMoveValuation;
    }
    else
    {
      // SGFC should have cleaned up the data so that this does not occur
      NSString* message = [NSString stringWithFormat:@"SGF Node contains move valuation %d without a move property", goMoveValuation];
      DDLogWarn(@"%@", message);
    }
  }

  if (! goNodeSetup.isEmpty)
    goNode.goNodeSetup = goNodeSetup;

  if (goMove)
    goNode.goMove = goMove;

  if (atLeastOneAnnotationPropertyWasFound)
    goNode.goNodeAnnotation = goNodeAnnotation;

  if (goNodeMarkup.hasMarkup)
    goNode.goNodeMarkup = goNodeMarkup;

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Populates @a goNodeSetup with data found in @a sgfSetupProperty.
/// @a sgfSetupPropertyWasFoundInGameInfoNode indicates whether or not
/// @a sgfSetupProperty was found in the game info node. @a mostRecentMove
/// refers to move that was most recently found in the branch of the game tree
/// that the iteration is currently in.
///
/// This is a helper function for
/// populateGoNode:withPropertiesFromSgfNode:mostRecentMove:errorMessage:().
// -----------------------------------------------------------------------------
- (bool) populateGoNodeSetup:(GoNodeSetup*)goNodeSetup
           withSetupProperty:(SGFCProperty*)sgfSetupProperty
         foundInGameInfoNode:(bool)sgfSetupPropertyWasFoundInGameInfoNode
              mostRecentMove:(GoMove*)mostRecentMove
                errorMessage:(NSString**)errorMessage
{
  // Implementation in Fuego of the "list_setup" GTP command
  // - Setup stones are all points that have a stone on them after AB, AW and AE
  //   properties in all nodes of the main variation have been evaluated, minus
  //   AB setup stones in the node that contains the HA property (to account for
  //   how the "list_handicap" GTP command evaluates the handicap).
  // - Setup properties that operate on the same point
  //   - Within the same node: Process properties in the order AB, AW, AE
  //   - Across nodes: The last setup property wins
  // Implementation in Fuego of the "list_setup_player" GTP command
  // - Examine nodes of the main variation up to the first node that contains
  //   a move property
  // - If a node contains the PL property its value is extracted and used
  // - If the PL property appears again in a later node its value overwrites
  //   the previous value
  //
  // SGFC behaviour for AB, AW and AE
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
  // SGFC behaviour for PL
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
  // - We are happy with all of these things that SGFC does for us, in fact we
  //   RELY on these things!
  // - We allow everything that is allowed by SGF, with the following
  //   exceptions:
  //   - We refuse to process the .sgf file if any setup property appears after
  //     the first move.
  //   - We refuse to process the .sgf file if the game info node contains
  //     handicap > 0 and any of the stone setup properties AB, AW or AE appear
  //     in nodes before the game info node. This check is not made in this
  //     method, it is made when handicap is set up.

  if (mostRecentMove)
  {
    *errorMessage = @"Game contains setup instructions after the first move.\n\nThis is not supported, all game setup must be made prior to the first move.";
    return false;
  }

  if (sgfSetupProperty.propertyType == SGFCPropertyTypePL)
  {
    enum GoColor color = sgfSetupProperty.propertyValue.toSingleValue.toColorValue.colorValue == SGFCColorBlack ? GoColorBlack : GoColorWhite;
    goNodeSetup.setupFirstMoveColor = color;
  }
  else
  {
    // We don't need to follow a particular order in how we process setup
    // properties. The pre-processing done by SGFC guarantees us that in the
    // same node the same point can appear only once.
    NSUInteger numberOfPointsToIgnore = 0;
    if (sgfSetupPropertyWasFoundInGameInfoNode && sgfSetupProperty.propertyType == SGFCPropertyTypeAB)
    {
      GoGame* game = [GoGame sharedGame];
      numberOfPointsToIgnore = game.handicapPoints.count;
    }
    bool success = [self populateGoNodeSetup:goNodeSetup
                      withValuesFromProperty:sgfSetupProperty
                      numberOfPointsToIgnore:numberOfPointsToIgnore
                                errorMessage:errorMessage];
    if (! success)
      return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Populates @a goNodeSetup with data found in @a sgfSetupProperty,
/// which is expected to be either the SGF property AB, AW or AE.
/// @a numberOfPointsToIgnore indicates how many point property values from
/// @a sgfSetupProperties should be ignored and @b not be used to populate
/// @a goNodeSetup.
///
/// The parameter @a numberOfPointsToIgnore is used to ignore handicap points
/// that are set up with the SGF property AB.
///
/// This is a helper function for
/// populateGoNodeSetup:withSetupProperty:foundInGameInfoNode:mostRecentMove:errorMessage:().
// -----------------------------------------------------------------------------
- (bool) populateGoNodeSetup:(GoNodeSetup*)goNodeSetup
      withValuesFromProperty:(SGFCProperty*)sgfSetupProperty
      numberOfPointsToIgnore:(NSUInteger)numberOfPointsToIgnore
                errorMessage:(NSString**)errorMessage
{
  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;
  SGFCPropertyType propertyType = sgfSetupProperty.propertyType;

  NSMutableArray* setupPoints = [NSMutableArray array];

  for (id<SGFCPropertyValue> setupPropertyValue in sgfSetupProperty.propertyValues)
  {
    if (numberOfPointsToIgnore > 0)
    {
      numberOfPointsToIgnore--;
      continue;
    }

    SGFCGoPoint* sgfGoPoint;
    if (propertyType == SGFCPropertyTypeAE)
      sgfGoPoint = setupPropertyValue.toSingleValue.toPointValue.toGoPointValue.goPoint;
    else
      sgfGoPoint = setupPropertyValue.toSingleValue.toStoneValue.toGoStoneValue.goStone.location;

    GoPoint* point = [self goPointForSgfGoPoint:sgfGoPoint
                                        onBoard:board
                                   errorMessage:errorMessage];
    if (! point)
    {
      *errorMessage = [@"SgfcKit interfacing error while determining board setup: " stringByAppendingString:*errorMessage];
      return false;
    }

    [setupPoints addObject:point];
  }

  if (propertyType == SGFCPropertyTypeAB)
  {
    [goNodeSetup setupValidatedBlackStones:setupPoints];
  }
  else if (propertyType == SGFCPropertyTypeAW)
  {
    [goNodeSetup setupValidatedWhiteStones:setupPoints];
  }
  else if (propertyType == SGFCPropertyTypeAE)
  {
    [goNodeSetup setupValidatedNoStones:setupPoints];
  }
  else
  {
    *errorMessage = [NSString stringWithFormat:@"SgfcKit interfacing error while determining board setup: Unexpected property type %lu with setup points %@", (unsigned long)propertyType, setupPoints];
    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a new GoMove object with data found in
/// @a sgfMoveProperty, which is expected to be either the SGF property B or W.
/// @a previousMove is the move that precedes the newly created GoMove object in
/// the branch of the game tree that the iteration is currently in.
/// @a previousMove is @e nil if the newly created GoMove is the first move in
/// the branch of the game tree that the iteration is currently in.
///
/// The GoMove object is created without validating it, and also without
/// creating a Zobrist hash for it.
///
/// This is a helper function for
/// populateGoNode:withPropertiesFromSgfNode:mostRecentMove:errorMessage:().
// -----------------------------------------------------------------------------
- (GoMove*) createMoveWithProperty:(SGFCProperty*)sgfMoveProperty
                  withPreviousMove:(GoMove*)previousMove
                      errorMessage:(NSString**)errorMessage
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
  // - In this phase we simply accept the move as it is. In a later phase the
  //   move is checked for its validity, i.e. whether it violates any of the
  //   app's game rules.

  GoGame* game = [GoGame sharedGame];

  SGFCGoMove* goMove = sgfMoveProperty.propertyValue.toSingleValue.toMoveValue.toGoMoveValue.goMove;
  if (! goMove)
  {
    *errorMessage = @"SgfcKit interfacing error while determining moves: Missing SGFCGoMove object.";
    return nil;
  }

  // Here we support if the .sgf contains moves by non-alternating colors,
  // anywhere in the game. Thus the user can ***VIEW*** almost any .sgf
  // game, even though the app itself is not capable of producing such
  // games.
  GoPlayer* player;
  SGFCPropertyType propertyType = sgfMoveProperty.propertyType;
  if (propertyType == SGFCPropertyTypeB)
    player = game.playerBlack;
  else
    player = game.playerWhite;

  GoMove* move;
  if (goMove.isPassMove)
  {
    move = [GoMove move:GoMoveTypePass by:player after:previousMove];
  }
  else
  {
    GoPoint* point = [self goPointForSgfGoPoint:goMove.stone.location onBoard:game.board errorMessage:errorMessage];
    if (! point)
    {
      *errorMessage = [@"SgfcKit interfacing error while determining moves: " stringByAppendingString:*errorMessage];
      return nil;
    }

    move = [GoMove move:GoMoveTypePlay by:player after:previousMove];
    move.point = point;
  }

  return move;
}

// -----------------------------------------------------------------------------
/// @brief Validates setup information and moves in all GoNode objects that were
/// previously generated by createNodes:errorMessage:(), to make sure that no
/// board positions are created that the app considers to be illegal.
///
/// Iterates depth-first over the tree of nodes found in the root node of the
/// current game's GoNodeModel. Branches of the game tree are iterated in
/// reverse order, i.e. the depth-first iteration does not start with the first
/// child of each node, but with the last child. This is an optimization that
/// is made so that when control returns to the caller, the board state is
/// already set up for the last node of the main game variation, which is what
/// the user wants to see when the app has finished loading a game. Without
/// this reverse-ordering of game tree branches the caller would have to perform
/// another iteration over the main game variation to set up the board, which
/// is the most expensive operation of LoadGameCommand.
///
/// The following validation is performed by this method when it encounters a
/// GoNode:
/// - If the GoNode contains a GoNodeSetup, the setup information is applied to
///   the game and board state, then a check is made whether to resulting board
///   position is valid. See validateSetup:withGame:errorMessage:() for details.
/// - If the GoNode contains a GoMove, the move is first checked to be valid.
///   If the move is valid it is played to update the board state.
/// - If the GoNode contains neither GoNodeSetup nor GoMove, no validation is
///   performed and the board state does not change.
///
/// Regardless of whether validation takes place or not, for each GoNode
/// encountered a Zobrist hash is calculated.
///
/// The asynchronous command delegate is updated continuously with progress
/// information as the nodes are validated, because applying setup information
/// and playing moves are relatively slow operations that take significant time.
/// In an ideal world we would have fine-grained progress updates with as many
/// steps as there are nodes. However, when there are many nodes to be created
/// this wastes a lot of precious CPU cycles for GUI updates, considerably
/// slowing down the process of loading a game - on older devices to an
/// intolerable level. In the real world, we therefore limit the number of
/// progress updates to a fixed, hard-coded number.
///
/// This is a helper function for setupNodes:().
// -----------------------------------------------------------------------------
- (bool) validateSetupAndMoveNodes:(int)numberOfNodesInGameTree errorMessage:(NSString**)errorMessage
{
  GoGame* game = [GoGame sharedGame];
  GoNodeModel* nodeModel = game.nodeModel;

  float nodesPerStep;
  NSUInteger remainingNumberOfSteps;
  if (numberOfNodesInGameTree <= maxStepsForCreateNodes)
  {
    nodesPerStep = 1;
    remainingNumberOfSteps = numberOfNodesInGameTree;
  }
  else
  {
    nodesPerStep = numberOfNodesInGameTree / maxStepsForCreateNodes;
    remainingNumberOfSteps = maxStepsForCreateNodes;
  }
  float remainingProgress = 1.0 - self.progress;
  // Adjust for increaseProgressAndNotifyDelegate()
  self.stepIncrease = remainingProgress / remainingNumberOfSteps;

  bool parentNodeIsOnMainVariation = true;
  bool currentNodeIsOnMainVariation = true;

  NSMutableArray* stack = [NSMutableArray array];

  GoNode* currentNode = nodeModel.rootNode;

  int numberOfNodesProcessed = 0;
  float nextProgressUpdate = nodesPerStep;  // use float in case nodesPerStep has fractions

  while (true)
  {
    while (currentNode)
    {
      if (currentNode.goNodeSetup)
      {
        // Setup validation requires the board to be already in the new state
        [currentNode modifyBoard];
        [currentNode calculateZobristHash:game];
        bool success = [self validateBoardSetupWithGame:game errorMessage:errorMessage];
        if (! success)
          return false;
      }
      else if (currentNode.goMove)
      {
        // Move validation requires the board to be still in the state before
        // the move was played
        bool success = [self validateMove:currentNode withGame:game errorMessage:errorMessage];
        if (! success)
          return false;
        [currentNode modifyBoard];
        [currentNode calculateZobristHash:game];
      }
      else
      {
        // Calculates the correct Zobrist hash based on the parent node
        [currentNode calculateZobristHash:game];
      }

      ++numberOfNodesProcessed;
      if (numberOfNodesProcessed >= nextProgressUpdate)
      {
        nextProgressUpdate += nodesPerStep;
        [self increaseProgressAndNotifyDelegate];
      }

      [stack addObject:@[currentNode, [NSNumber numberWithBool:currentNodeIsOnMainVariation], [NSNumber numberWithBool:parentNodeIsOnMainVariation]]];

      // currentNode becomes parent node
      GoNode* newCurrentNode = currentNode.lastChild;
      parentNodeIsOnMainVariation = currentNodeIsOnMainVariation;
      if (parentNodeIsOnMainVariation)
        currentNodeIsOnMainVariation = (newCurrentNode == currentNode.firstChild);
      currentNode = newCurrentNode;
    }

    if (stack.count > 0)
    {
      NSArray* tuple = stack.lastObject;
      [stack removeLastObject];

      currentNode = [tuple objectAtIndex:0];
      NSNumber* currentNodeIsOnMainVariationAsNumber = [tuple objectAtIndex:1];
      currentNodeIsOnMainVariation = currentNodeIsOnMainVariationAsNumber.boolValue;
      NSNumber* parentNodeIsOnMainVariationAsNumber = [tuple objectAtIndex:2];
      parentNodeIsOnMainVariation = parentNodeIsOnMainVariationAsNumber.boolValue;

      if (currentNodeIsOnMainVariation)
      {
        // When we get here for the first time after popping the stack, we have
        // reached the maximum depth of the main variation and from now on are
        // going to ascend the tree back to the root node without encountering
        // any further branches. This has the following consequences:
        // - We don't want to revert the board anymore. We want to keep the
        //   board and everything else in the state that was applied by the main
        //   variation's leaf node when its modifyBoard() method was invoked.
        //   Reason: This is the state that what we want to display after the
        //   game has finished loading.
        // - We don't need to look anymore for previousSibling => nodes on the
        //   main variation can't have a previousSibling. So we can simply set
        //   currentNode to nil.
        currentNode = nil;
      }
      else
      {
        // Prepare the board for the data in the previous sibling. After this
        // the board has the state generated by the parent of currentNode.
        [currentNode revertBoard];

        // Try to change the variation
        currentNode = currentNode.previousSibling;

        // After we changed the variation the new currentNode may now be on the
        // main variation, so we need to adjust currentNodeIsOnMainVariation.
        // No adjustment is necessary in the following cases:
        // - If there was no previous sibling, i.e. we didn't change the
        //   variation. The next iteration will pop the stack and will assign
        //   a new value to currentNodeIsOnMainVariation from the stack.
        // - If there was a previous sibling, i.e. we did change the variation,
        //   but the parent node is not on the main variation. If the parent
        //   node is not on the main variation, the new variation that we
        //   changed to cannot suddenly be the main variation, so we can simply
        //   keep the value for currentNodeIsOnMainVariation that we popped
        //   from the stack.
        if (currentNode && parentNodeIsOnMainVariation)
          currentNodeIsOnMainVariation = (currentNode == currentNode.parent.firstChild);
      }
    }
    else
    {
      // We're done
      break;
    }
  }

  // At this point the tree of nodes has been fully created, and the board state
  // matches the leaf node of the main variation. Now the state in the remaining
  // Go model objects must be updated as well.

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Checks with the help of @a game whether the board state as it is
/// currently set up is valid. Returns @e true if the board state is valid,
/// returns @e false if the board state is not valid.
///
/// This is a helper function for validateSetupAndMoveNodes:errorMessage:().
// -----------------------------------------------------------------------------
- (bool) validateBoardSetupWithGame:(GoGame*)game errorMessage:(NSString**)errorMessage
{
  // We have to evaluate the board state after the entire setup information in
  // a GoNodeSetup was applied to the board. It is not possible to invoke the
  // GoGame method
  // isLegalBoardSetupAt:withStoneState:isIllegalReason:createsIllegalStoneOrGroup:()
  // separately for each point in GoNodeSetup, because an intermediate board
  // state, before all setup stones are placed ore removed, might well be
  // illegal.
  NSString* suicidalIntersectionsString;
  bool isLegalBoardSetup = [game isLegalBoardSetup:&suicidalIntersectionsString];

  if (! isLegalBoardSetup)
  {
    *errorMessage = [NSString stringWithFormat:@"Game contains an invalid board setup prior to the first move.\n\nSetup attempts to place stones with 0 (zero) liberties on the following intersections: %@.", suicidalIntersectionsString];
    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Checks with the help of @a game whether the GoMove found in @a node
/// is a legal move. Returns @e true if the move is legal, returns @e false if
/// the move is not legal.
///
/// This is a helper function for validateSetupAndMoveNodes:errorMessage:().
// -----------------------------------------------------------------------------
- (bool) validateMove:(GoNode*)node withGame:(GoGame*)game errorMessage:(NSString**)errorMessage
{
  GoMove* move = node.goMove;
  GoNode* predecessorNode = node.parent;

  // Here we support if the SGF file contains moves by non-alternating colors,
  // anywhere in the game. Thus the user can ***VIEW*** almost any game from an
  // SGF file, even though the app itself is not capable of producing such
  // games.
  enum GoColor moveColor = (move.player == game.playerBlack) ? GoColorBlack : GoColorWhite;

  bool isLegalMove;
  enum GoMoveIsIllegalReason illegalReason;
  if (move.type == GoMoveTypePlay)
  {
    isLegalMove = [game isLegalMove:move.point
                            byColor:moveColor
                          afterNode:predecessorNode
                    isIllegalReason:&illegalReason];
  }
  else
  {
    isLegalMove = [game isLegalPassMoveByColor:moveColor
                                     afterNode:predecessorNode
                                 illegalReason:&illegalReason];
  }

  if (! isLegalMove)
  {
    NSString* colorName = [NSString stringWithGoColor:moveColor];
    NSString* illegalReasonString = [NSString stringWithMoveIsIllegalReason:illegalReason];
    if (move.type == GoMoveTypePlay)
    {
      NSString* errorMessageFormat = @"Game contains an illegal move: Move %d, played by %@, on intersection %@. Reason: %@.";
      *errorMessage = [NSString stringWithFormat:errorMessageFormat, move.moveNumber, colorName, move.point.vertex.string, illegalReasonString];
    }
    else
    {
      NSString* errorMessageFormat = @"Game contains an illegal move: Pass move %d, played by %@. Reason: %@.";
      *errorMessage = [NSString stringWithFormat:errorMessageFormat, move.moveNumber, colorName, illegalReasonString];
    }
    return false;
  }
  
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Adjusts the state of various model objects so that everything is set
/// up for the app to display the last board position of the main game
/// variation.
///
/// This is a helper function for setupNodes:().
// -----------------------------------------------------------------------------
- (bool) fixStateOfGoModelObjects:(NSString**)errorMessage
{
  // IMPORTANT: The order in which things are executed in this method matters!

  GoGame* game = [GoGame sharedGame];

  // GoNodeModel must be updated first - the variation configured here is the
  // basis for many of the subsequent operations. Also, the following GoGame
  // properties are calculated based on the variation configured in GoNodeModel:
  // - firstMove
  // - lastMove
  [game.nodeModel changeToMainVariation];

  // GoBoardPosition must now be sync'ed with the content of GoNodeModel. This
  // updates the numberOfBoardPosition and currentBoardPosition values (the
  // latter via changeToLastBoardPositionWithoutUpdatingGoObjects).
  game.boardPosition.numberOfBoardPositions = game.nodeModel.numberOfNodes;
  [game.boardPosition changeToLastBoardPositionWithoutUpdatingGoObjects];

  // Configure nextMoveColor. No need to check GoGame's property alternatingPlay
  // because after loading a game from SGF we always start out with alternating
  // play. The following properties base their values on nextMoveColor:
  // - nextMovePlayer
  // - nextMovePlayerIsComputerPlayer
  GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:game.nodeModel.leafNode];
  GoMove* mostRecentMove = nodeWithMostRecentMove ? nodeWithMostRecentMove.goMove : nil;
  game.nextMoveColor = [GoUtilities playerAfter:mostRecentMove inCurrentGameVariation:game].color;

  // Possibly set the GoGame properties state and reasonForGameHasEnded. Note
  // that this may be overridden later if the SGF file contains a SGFCGameResult
  // that can be mapped to one of the app's recognized game endings
  // (e.g. resignation).
  [game endGameDueToPassMovesIfGameRulesRequireIt];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Posts a number of notifications to the default notification center to
/// inform the rest of the application about the final state of the Go model.
///
/// This is a helper function for setupNodes:().
// -----------------------------------------------------------------------------
- (bool) notifyApplicationAboutFinalGoModelState:(NSString**)errorMessage
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  GoGame* game = [GoGame sharedGame];
  GoNodeModel* nodeModel = game.nodeModel;
  GoBoardPosition* boardPosition = game.boardPosition;

  // If the loaded game does not have any other nodes besides the root node,
  // then we don't have to post any notifications
  if (! nodeModel.rootNode.hasChildren)
    return true;

  // A new game consists of only the root node and therefore has exactly one
  // board position, and the current board position is the one that refers to
  // the root node
  int oldNumberOfBoardPositions = 1;
  int oldCurrentBoardPosition = 0;
  // These new values refer to whichever game variation has been set up by the
  // rest of this command to be the current game variation
  int newNumberOfBoardPositions = boardPosition.numberOfBoardPositions;
  int newCurrentBoardPosition = boardPosition.currentBoardPosition;

  // Needs to be posted because the node tree does not consist of only the root
  // node
  [center postNotificationName:goNodeTreeLayoutDidChange object:nil];

  if (oldNumberOfBoardPositions != newNumberOfBoardPositions)
    [center postNotificationName:numberOfBoardPositionsDidChange object:@[[NSNumber numberWithInt:oldNumberOfBoardPositions], [NSNumber numberWithInt:newNumberOfBoardPositions]]];

  if (oldCurrentBoardPosition != newCurrentBoardPosition)
    [center postNotificationName:currentBoardPositionDidChange object:@[[NSNumber numberWithInt:oldCurrentBoardPosition], [NSNumber numberWithInt:newCurrentBoardPosition]]];

  return true;
}

#pragma mark - Step 6: Setup game result

// -----------------------------------------------------------------------------
/// @brief Sets up the result for the new game. Does nothing if the SGF file
/// does not contain a game result, or if the game result cannot be mapped to a
/// result supported by the app.
///
/// GoGame may already be in state #GoGameStateGameHasEnded due to moves played
/// in the current variation. An explicit game result in the SGF file overrides
/// the implicit game ending.
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

#pragma mark - Step 7: Sync GTP engine

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
  SyncGTPEngineCommand* syncCommand = [[[SyncGTPEngineCommand alloc] init] autorelease];
  bool syncSuccess = [syncCommand submit];
  if (syncSuccess)
  {
    return true;
  }
  else
  {
    *errorMessage = [NSString stringWithFormat:@"Failed to synchronize the GTP engine state with the current GoGame state. GTP engine error message:\n\n%@", syncCommand.errorDescription];
    return false;
  }
}

#pragma mark - Helper methods to complete game setup and handle errors

// -----------------------------------------------------------------------------
/// @brief Notifies the GoGameDocument associated with the new game that the
/// game was loaded.
// -----------------------------------------------------------------------------
- (void) notifyGoGameDocument
{
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
  [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:@"Failed to load game" message:message];
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

  NewGameModel* model = [ApplicationDelegate sharedDelegate].theNewGameModel;

  self.sgfGame = [SGFCGame game];
  self.sgfGameInfoNode = self.sgfGame.rootNode;
  self.sgfRootNode = nil;  // will be set as a side-effect

  // Setup board size before creating an SGFCGoGameInfo object, because that
  // object will be initialized with the board size from the game info node
  enum GoBoardSize goBoardSize = model.boardSize;
  SGFCBoardSize sgfBoardSize = SGFCBoardSizeMake(goBoardSize, goBoardSize);
  SGFCNumberPropertyValue* szPropertyValue = [SGFCNumberPropertyValue numberPropertyValueWithNumberValue:goBoardSize];
  SGFCBoardSizeProperty* szProperty = [SGFCBoardSizeProperty boardSizePropertyWithNumberPropertyValue:szPropertyValue];
  [self.sgfGameInfoNode setProperty:szProperty];

  SGFCProperty* abProperty = [SGFCProperty propertyWithType:SGFCPropertyTypeAB];
  for (NSString* handicapVertex in [GoUtilities verticesForHandicap:model.handicap boardSize:goBoardSize])
  {
    SGFCGoStonePropertyValue* abPropertyValue = [SGFCGoStonePropertyValue goStonePropertyValueWithGoStoneValue:handicapVertex
                                                                                                     boardSize:sgfBoardSize
                                                                                                         color:SGFCColorBlack];
    [abProperty appendPropertyValue:abPropertyValue];
  }
  [self.sgfGameInfoNode setProperty:abProperty];

  self.sgfGoGameInfo = self.sgfGameInfoNode.gameInfo.toGoGameInfo;

  // It's less code for us to write if we let SGFCGoGameInfo write the data
  // back to the game info node
  self.sgfGoGameInfo.numberOfHandicapStones = model.handicap;
  self.sgfGoGameInfo.komi = model.komi;
  [self.sgfGameInfoNode writeGameInfo:self.sgfGoGameInfo];

  // Alert must be shown on main thread, otherwise there is the possibility of
  // a crash (it's real, I've seen the crash reports!)
  [self performSelectorOnMainThread:@selector(showAlert:) withObject:message waitUntilDone:YES];
  DDLogError(@"%@", message);
}

#pragma mark - Markup helper methods

// -----------------------------------------------------------------------------
/// @brief Invokes setSymbol:atVertex:() on @a nodeMarkup once for every value
/// in @a propertyValues, using the symbol type @a symbol. Returns true if no
/// error was encountered. Returns false if an error was encountered and sets
/// @a errorMessage with a string that describes the error encountered.
// -----------------------------------------------------------------------------
- (bool) setSymbols:(enum GoMarkupSymbol)symbol inMarkup:(GoNodeMarkup*)nodeMarkup forPropertyValues:(NSArray*)propertyValues errorMessage:(NSString**)errorMessage
{
  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  for (id<SGFCPropertyValue> propertyValue in propertyValues)
  {
    NSString* vertexString = [self vertexForSgfGoPoint:propertyValue.toSingleValue.toPointValue.toGoPointValue.goPoint onBoard:board errorMessage:errorMessage];
    if (! vertexString)
    {
      *errorMessage = [@"SgfcKit interfacing error while determining markup: " stringByAppendingString:*errorMessage];
      return false;
    }

    [nodeMarkup setSymbol:symbol atVertex:vertexString];
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Invokes setConnection:fromVertex:toVertex:() on @a nodeMarkup once
/// for every value in @a propertyValues, using the connection type
/// @a connection. Returns true if no error was encountered. Returns false if
/// an error was encountered and sets @a errorMessage with a string that
/// describes the error encountered.
// -----------------------------------------------------------------------------
- (bool) setConnections:(enum GoMarkupConnection)connection inMarkup:(GoNodeMarkup*)nodeMarkup forPropertyValues:(NSArray*)propertyValues errorMessage:(NSString**)errorMessage
{
  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  // According to the SGF standard, the same pair of points legally can appear
  // only once. However, SGFC does not enforce this, so here we may encounter
  // the same pair multiple times. We don't care, though, because GoNodeMarkup
  // simply overwrites a previous pair when we set it again.
  for (id<SGFCPropertyValue> propertyValue in propertyValues)
  {
    NSString* fromVertexString = [self vertexForSgfGoPoint:propertyValue.toComposedValue.value1.toSingleValue.toPointValue.toGoPointValue.goPoint onBoard:board errorMessage:errorMessage];
    if (! fromVertexString)
    {
      *errorMessage = [@"SgfcKit interfacing error while determining markup: " stringByAppendingString:*errorMessage];
      return false;
    }

    NSString* toVertexString = [self vertexForSgfGoPoint:propertyValue.toComposedValue.value2.toSingleValue.toPointValue.toGoPointValue.goPoint onBoard:board errorMessage:errorMessage];
    if (! toVertexString)
    {
      *errorMessage = [@"SgfcKit interfacing error while determining markup: " stringByAppendingString:*errorMessage];
      return false;
    }

    // SgfcKit / SGFC should delete values with same start/end point, but we
    // make the check anyway to guard against unexpected data because
    // GoNodeMarkup raises an exception (which crashes the app) if the vertices
    // are the same.
    if ([fromVertexString isEqualToString:toVertexString])
      continue;

    [nodeMarkup setConnection:connection fromVertex:fromVertexString toVertex:toVertexString];
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Invokes setLabel:labelText:atVertex:() on @a nodeMarkup once for
/// every value in @a propertyValues. Returns true if no error was encountered.
/// Returns false if an error was encountered and sets @a errorMessage with a
/// string that describes the error encountered.
// -----------------------------------------------------------------------------
- (bool) setLabelsInMarkup:(GoNodeMarkup*)nodeMarkup forPropertyValues:(NSArray*)propertyValues errorMessage:(NSString**)errorMessage
{
  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  for (id<SGFCPropertyValue> propertyValue in propertyValues)
  {
    NSString* vertexString = [self vertexForSgfGoPoint:propertyValue.toComposedValue.value1.toSingleValue.toPointValue.toGoPointValue.goPoint onBoard:board errorMessage:errorMessage];
    if (! vertexString)
    {
      *errorMessage = [@"SgfcKit interfacing error while determining markup: " stringByAppendingString:*errorMessage];
      return false;
    }

    NSString* labelText = propertyValue.toComposedValue.value2.toSingleValue.toSimpleTextValue.simpleTextValue;

    // SgfcKit / SGFC should trim trailing (not leading!) whitespace from label
    // texts, replace newline characters with space characters, and delete
    // property values that contain an empty label text (after trimming and
    // replacing), but we make the check anyway to guard against unexpected data
    // because GoNodeMarkup raises an exception (which crashes the app) if the
    // cleaned up label text is empty.
    labelText = [GoNodeMarkup removeNewlinesAndTrimLabel:labelText];
    if (labelText.length == 0)
      continue;

    // This app categorizes labels into number/letter marker labels and regular
    // labels. Markers are drawn differently than regular labels, and there is
    // also special logic when placing new markers on the board.
    enum GoMarkupLabel labelType = [GoNodeMarkup labelTypeOfLabel:labelText];
    [nodeMarkup setLabel:labelType labelText:labelText atVertex:vertexString];
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Invokes setDimmingAtVertex:() on @a nodeMarkup once for every value
/// in @a propertyValues. Returns true if no error was encountered. Returns
/// false if an error was encountered and sets @a errorMessage with a string
/// that describes the error encountered.
// -----------------------------------------------------------------------------
- (bool) setDimmingsInMarkup:(GoNodeMarkup*)nodeMarkup forPropertyValues:(NSArray*)propertyValues errorMessage:(NSString**)errorMessage
{
  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  for (id<SGFCPropertyValue> propertyValue in propertyValues)
  {
    NSString* vertexString = [self vertexForSgfGoPoint:propertyValue.toSingleValue.toPointValue.toGoPointValue.goPoint onBoard:board errorMessage:errorMessage];
    if (! vertexString)
    {
      *errorMessage = [@"SgfcKit interfacing error while determining markup: " stringByAppendingString:*errorMessage];
      return false;
    }

    [nodeMarkup setDimmingAtVertex:vertexString];
  }

  return true;
}

#pragma mark - Helper methods

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object on the board @a board that corresponds to
/// the intersection referred to by @a sgfGoPoint. Returns @e nil if an error
/// was encountered and sets @a errorMessage with a string that describes the
/// error encountered.
// -----------------------------------------------------------------------------
- (GoPoint*) goPointForSgfGoPoint:(SGFCGoPoint*)sgfGoPoint onBoard:(GoBoard*)board errorMessage:(NSString**)errorMessage
{
  NSString* vertexString = [self vertexForSgfGoPoint:sgfGoPoint errorMessage:errorMessage];
  GoPoint* goPoint = [board pointAtVertex:vertexString];
  if (! goPoint)
  {
    *errorMessage = [NSString stringWithFormat:@"Invalid intersection.\n\n%@", vertexString];
    return nil;
  }

  return goPoint;
}

// -----------------------------------------------------------------------------
/// @brief Returns the vertex string that corresponds to the intersection
/// referred to by @a sgfGoPoint. The vertex is in the hybrid notation (e.g.
/// "A1") used throughout this project. A chheck is made that @a board contains
/// a GoPoint object for the vertex string. Returns @e nil if an error was
/// encountered and sets @a errorMessage with a string that describes the
/// error encountered.
// -----------------------------------------------------------------------------
- (NSString*) vertexForSgfGoPoint:(SGFCGoPoint*)sgfGoPoint onBoard:(GoBoard*)board errorMessage:(NSString**)errorMessage
{
  NSString* vertexString = [self vertexForSgfGoPoint:sgfGoPoint errorMessage:errorMessage];
  GoPoint* goPoint = [board pointAtVertex:vertexString];
  if (! goPoint)
  {
    *errorMessage = [NSString stringWithFormat:@"Invalid intersection.\n\n%@", vertexString];
    return nil;
  }

  return vertexString;
}

// -----------------------------------------------------------------------------
/// @brief Returns the vertex string that corresponds to the intersection
/// referred to by @a sgfGoPoint. The vertex is in the hybrid notation (e.g.
/// "A1") used throughout this project. Returns @e nil if an error was
/// encountered and sets @a errorMessage with a string that describes the
/// error encountered.
// -----------------------------------------------------------------------------
- (NSString*) vertexForSgfGoPoint:(SGFCGoPoint*)sgfGoPoint errorMessage:(NSString**)errorMessage
{
  if (! sgfGoPoint)
  {
    *errorMessage = @"Missing SGFCGoPoint object.";
    return nil;
  }

  if (! [sgfGoPoint hasPositionInGoPointNotation:SGFCGoPointNotationHybrid])
  {
    *errorMessage = @"SGFCGoPoint not available in hybrid notation.";
    return nil;
  }

  NSString* vertexString = [sgfGoPoint positionInGoPointNotation:SGFCGoPointNotationHybrid];
  return vertexString;
}

@end
