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
#import "../sgf/LoadSgfCommand.h"
#import "../../archive/ArchiveViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameDocument.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpUtilities.h"
#import "../../main/ApplicationDelegate.h"
#import "../../newgame/NewGameModel.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../sgf/SgfSettingsModel.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/PathUtilities.h"

// Constants
static const int maxStepsForReplayMoves = 10;

/// @brief Enumerates possible results of parsing a move string provided by
/// Fuego.
enum ParseMoveStringResult
{
  ParseMoveStringResultSuccess,
  ParseMoveStringResultInvalidFormat,
  ParseMoveStringResultInvalidColor,
  ParseMoveStringResultInvalidVertex
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LoadGameCommand.
// -----------------------------------------------------------------------------
@interface LoadGameCommand()
@property(nonatomic, assign) enum GoBoardSize boardSize;
@property(nonatomic, retain) NSString* handicap;
@property(nonatomic, retain) NSString* setup;
@property(nonatomic, retain) NSString* setupPlayer;
@property(nonatomic, retain) NSString* komi;
@property(nonatomic, retain) NSString* moves;
@property(nonatomic, assign) int totalSteps;
@property(nonatomic, assign) float stepIncrease;
@property(nonatomic, assign) float progress;
@property(nonatomic, retain) SGFCGame* sgfGame;
@property(nonatomic, retain) NSArray* sgfMainVariationNodes;
@property(nonatomic, retain) SGFCNode* sgfGameInfoNode;
@property(nonatomic, retain) SGFCGoGameInfo* sgfGoGameInfo;
@property(nonatomic, retain) NSArray* handicapVertexStrings;
@end


@implementation LoadGameCommand

@synthesize asynchronousCommandDelegate;


// -----------------------------------------------------------------------------
/// @brief Initializes a LoadGameCommand object that will load the .sgf file
/// identified by the full file path @a filePath.
///
/// @note This is the designated initializer of LoadGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithFilePath:(NSString*)filePath
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.filePath = filePath;
  self.restoreMode = false;
  self.didTriggerComputerPlayer = false;
  self.boardSize = GoBoardSizeUndefined;
  self.handicap = nil;
  self.setup = nil;
  self.setupPlayer = nil;
  self.komi = nil;
  self.moves = nil;
  self.totalSteps = (6 + maxStepsForReplayMoves);  // 6 fixed steps for SGF parsing
  self.stepIncrease = 1.0 / self.totalSteps;
  self.progress = 0.0;
  self.sgfGame = nil;
  self.sgfMainVariationNodes = nil;
  self.sgfGameInfoNode = nil;
  self.sgfGoGameInfo = nil;
  self.handicapVertexStrings = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a LoadGameCommand object that will load the .sgf file
/// from the archive that is identified by @a gameName.
// -----------------------------------------------------------------------------
- (id) initWithGameName:(NSString*)gameName
{
  ArchiveViewModel* model = [ApplicationDelegate sharedDelegate].archiveViewModel;
  return [self initWithFilePath:[model filePathForGameWithName:gameName]];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a LoadGameCommand object that will load the game from
/// the SGF data referenced by @a sgfGameInfoNode.
// -----------------------------------------------------------------------------
- (id) initWithGameInfoNode:(SGFCNode*)sgfGameInfoNode goGameInfo:(SGFCGoGameInfo*)sgfGoGameInfo
{
  self = [self initWithFilePath:nil];
  if (! self)
    return nil;

  self.sgfGameInfoNode = sgfGameInfoNode;
  self.sgfGoGameInfo = sgfGoGameInfo;
  self.sgfMainVariationNodes = sgfGameInfoNode.mainVariationNodes;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LoadGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.filePath = nil;
  self.handicap = nil;
  self.setup = nil;
  self.setupPlayer = nil;
  self.komi = nil;
  self.moves = nil;
  self.sgfGame = nil;
  self.sgfMainVariationNodes = nil;
  self.sgfGameInfoNode = nil;
  self.sgfGoGameInfo = nil;
  self.handicapVertexStrings = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (self.filePath)
    DDLogVerbose(@"%@: Loading SGF file %@", [self shortDescription], self.filePath);
  else
    DDLogVerbose(@"%@: Loading SGF node", [self shortDescription]);

  bool runToCompletion = false;
  NSString* errorMessage = @"Internal error";
  @try
  {
    [[LongRunningActionCounter sharedCounter] increment];
    [self setupProgressHUD];
    [GtpUtilities stopPondering];
    bool success = [self loadAndParseSgf:&errorMessage];
    if (! success)
      return false;
    @try
    {
      [[ApplicationStateManager sharedManager] beginSavePoint];
      [self increaseProgressAndNotifyDelegate];
      [self setupGoGame];
      runToCompletion = true;
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
    if (! runToCompletion)
      [self handleCommandFailed:errorMessage];
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
- (bool) loadAndParseSgf:(NSString**)errorMessage
{
  bool success;
  if (self.filePath)
  {
    success = [self loadSgf:errorMessage];
    if (! success)
      return false;
  }
  [self increaseProgressAndNotifyDelegate];
  success = [self parseSgfDataForBoardSize:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self parseSgfDataForKomi:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self parseSgfDataForHandicap:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self parseSgfDataForSetup:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self parseSgfDataForSetupPlayer:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self parseSgfDataForMoves:errorMessage];
  if (! success)
    return false;
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) loadSgf:(NSString**)errorMessage
{
  LoadSgfCommand* loadSgfCommand = [[[LoadSgfCommand alloc] initWithSgfFilePath:self.filePath] autorelease];
  bool success = [loadSgfCommand submit];
  if (! success)
  {
    *errorMessage = @"An internal error occurred: Executing LoadSgfCommand failed for unknown reasons.";
    return false;
  }

  SgfSettingsModel* sgfSettingsModel = [ApplicationDelegate sharedDelegate].sgfSettingsModel;

  SGFCDocumentReadResult* readResult;
  if (sgfSettingsModel.encodingMode == SgfEncodingModeSingleEncoding)
    readResult = loadSgfCommand.sgfDocumentReadResultSingleEncoding;
  else if (sgfSettingsModel.encodingMode == SgfEncodingModeMultipleEncodings)
    readResult = loadSgfCommand.sgfDocumentReadResultMultipleEncodings;
  else if (loadSgfCommand.sgfDocumentReadResultMultipleEncodings != nil)
    readResult = loadSgfCommand.sgfDocumentReadResultMultipleEncodings;
  else
    readResult = loadSgfCommand.sgfDocumentReadResultSingleEncoding;

  if (readResult.isSgfDataValid)
  {
    enum SgfLoadSuccessType loadSuccessType = sgfSettingsModel.loadSuccessType;
    if (loadSuccessType == SgfLoadSuccessTypeWithCriticalWarningsOrErrors)
    {
      // It doesn't matter what kind of messages we have - all are acceptable
    }
    else
    {
      NSArray* parseResult = readResult.parseResult;

      if (loadSuccessType == SgfLoadSuccessTypeNoWarningsOrErrors)
      {
        if (parseResult.count > 0)
        {
          int numberOfWarnings = 0;
          int numberOfErrors = 0;
          for (SGFCMessage* message in parseResult)
          {
            if (message.messageType == SGFCMessageTypeWarning)
              numberOfWarnings++;
            else
              numberOfErrors++;
          }

          *errorMessage = [NSString stringWithFormat:@"The SGF data is not fully standard conformant. Parsing resulted in %d warning(s) and %d error(s).", numberOfWarnings, numberOfErrors];
          return false;
        }
      }
      else
      {
        for (SGFCMessage* message in parseResult)
        {
          if (message.isCriticalMessage)
          {
            switch (message.messageID)
            {
              case SGFCMessageIDGameIsNotGo:
                // Skip this message. If there are no other critical messages we
                // will detect non-Go games further down and abort there with a
                // tailored error message.
                continue;
              case SGFCMessageIDUnknownEncodingInSgfContent:
                *errorMessage = @"The SGF data is encoded with an unsupported or unknown/illegal text encoding.";
                break;
              case SGFCMessageIDEncodingErrorsDetected:
                *errorMessage = @"The SGF data encoding is faulty (illegal byte sequence according to the text encoding)";
                break;
              default:
                *errorMessage = [NSString stringWithFormat:@"A critical problem with the SGF data was found. The technical error message is:\n\n%@", message.formattedMessageText];
                break;
            }
            return false;
          }
        }
      }
    }
  }
  else
  {
    for (SGFCMessage* message in readResult.parseResult)
    {
      if (message.messageType == SGFCMessageTypeFatalError)
      {
        switch (message.messageID)
        {
          case SGFCMessageIDNoSgfData:
            *errorMessage = @"Unable to find any SGF data.";
            break;
          case SGFCMessageIDUnknownIconvError:
            *errorMessage = [NSString stringWithFormat:@"An unexpected text encoding error occurred in the iconv library. The technical error message is:\n\n%@", message.messageText];
            break;
          case SGFCMessageIDEncodingDetectionFailed:
            *errorMessage = @"Failed to detect the text encoding of the SGF data.";
            break;
          case SGFCMessageIDSgfContentHasDifferentEncodingsFatal:
            *errorMessage = @"The SGF data contains two or more text encodings.";
            break;
          default:
            *errorMessage = [NSString stringWithFormat:@"A fatal error occurred while reading the SGF data. The technical error message is:\n\n%@", message.formattedMessageText];
            break;
        }
        return false;
      }
    }

    *errorMessage = @"Reading of the SGF data failed. The SgfcKit library did not specify a reason for the failure.";
    return false;
  }

  SGFCGame* firstGame = readResult.document.game;
  if (firstGame && firstGame.hasRootNode)
  {
    self.sgfGame = firstGame;
    self.sgfMainVariationNodes = firstGame.rootNode.mainVariationNodes;
    // We can't be sure that the main variation actually has a game info node,
    // therefore we can't take the node from firstGame.gameInfoNodes - that
    // collection might consist of game info nodes that are all located in
    // variations that are not the main variation. To guarantee that we get the
    // correct game info node we have to start the search from the main
    // variation's last node.
    SGFCNode* lastNodeOfMainVariation = [self.sgfMainVariationNodes lastObject];
    self.sgfGameInfoNode = lastNodeOfMainVariation.gameInfoNode;
  }
  else
  {
    self.sgfGame = [SGFCGame game];
    self.sgfMainVariationNodes = [NSArray array];
    self.sgfGameInfoNode = nil;
  }

  if (self.sgfGame.gameType != SGFCGameTypeGo)
  {
    *errorMessage = [NSString stringWithFormat:@"The game is not a Go game. The SGF game number is %ld.", self.sgfGame.gameTypeAsNumber];
    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) parseSgfDataForBoardSize:(NSString**)errorMessage
{
  SGFCBoardSize boardSize;
  if (self.sgfGame)
    boardSize = self.sgfGame.boardSize;
  else
    boardSize = self.sgfGoGameInfo.boardSize;

  if (! SGFCBoardSizeIsSquare(boardSize))
  {
    *errorMessage = [NSString stringWithFormat:@"The board size is not square: %ld x %ld.", (long)boardSize.Columns, (long)boardSize.Rows];
    return false;
  }

  switch (boardSize.Columns)
  {
    case 7:
    case 9:
    case 11:
    case 13:
    case 15:
    case 17:
    case 19:
    {
      self.boardSize = (enum GoBoardSize)boardSize.Columns;
      return true;
    }
    default:
    {
      *errorMessage = [NSString stringWithFormat:@"The board size is not supported: %ld.", (long)boardSize.Columns];
      return false;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) parseSgfDataForKomi:(NSString**)errorMessage
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

  self.komi = @"";

  if (! self.sgfGameInfoNode)
    return true;

  SGFCProperty* komiProperty = [self.sgfGameInfoNode propertyWithType:SGFCPropertyTypeKM];
  if (! komiProperty)
    return true;

  self.komi = komiProperty.propertyValue.toSingleValue.rawValue;

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) parseSgfDataForHandicap:(NSString**)errorMessage
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

  /// Expected format by later processing is: "vertex vertex vertex[...]"
  self.handicap = @"";
  NSMutableArray* handicapVertexStrings = [NSMutableArray array];
  self.handicapVertexStrings = handicapVertexStrings;

  if (! self.sgfGameInfoNode)
    return true;

  SGFCProperty* handicapProperty = [self.sgfGameInfoNode propertyWithType:SGFCPropertyTypeHA];
  if (! handicapProperty)
    return true;

  SGFCNumber expectedNumberOfHandicapStones = handicapProperty.propertyValue.toSingleValue.toNumberValue.numberValue;
  if (expectedNumberOfHandicapStones == 0)
    return true;

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
      [handicapVertexStrings addObject:vertexString];
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

  self.handicap = [handicapVertexStrings componentsJoinedByString:@" "];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) parseSgfDataForSetup:(NSString**)errorMessage
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

  /// Expected format by later processing is: "color vertex, color vertex, color vertex[...]"
  self.setup = @"";

  NSMutableDictionary* setupPointDictionary = [NSMutableDictionary dictionary];
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
            *errorMessage = @"The SGF data contains stone setup instructions after the first move.";
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
          // Overwriting previous values works because key are compared for
          // equality, not for object identity
          setupPointDictionary[vertexString] = [NSNumber numberWithInt:goColor];
        }
      }
    }
  }

  // Make a copy so that the original remains the same
  NSMutableArray* handicapVertexStrings = [self.handicapVertexStrings mutableCopy];
  NSMutableArray* setupStrings = [NSMutableArray array];
  [setupPointDictionary enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSNumber* goColorAsNumber, BOOL* stop)
  {
    enum GoColor goColor = [goColorAsNumber intValue];
    if (goColor == GoColorNone)
      return;

    if (goColor == GoColorBlack)
    {
      // Works because containsObject: compares equality, not object identity
      if ([handicapVertexStrings containsObject:vertexString])
      {
        [handicapVertexStrings removeObject:vertexString];
        return;
      }
    }

    NSString* colorString = (goColor == GoColorBlack) ? @"B" : @"W";
    NSString* setupString = [NSString stringWithFormat:@"%@ %@", colorString, vertexString];
    [setupStrings addObject:setupString];
  }];

  // If at this point there are still handicap stones in the array this means
  // that all setup properties combined have manipulated the leftover points
  // so that they no longer contain a black handicap stone, but instead contain
  // either a white stone (AW), or are empty (AE). Because Little Go will
  // continue to use the handicap stones this opens up the possiblity that
  // certain moves in the SGF will be considered illegal by Little Go (e.g.
  // a move might attempt to place a stone on point that is now empty). To
  // avoid this situation we refuse to continue
  if (handicapVertexStrings.count > 0)
  {
    *errorMessage = [NSString stringWithFormat:@"One or more black handicap stones are removed or redefined to white stones after they are set up. Affected handicap stone(s):\n\n%@",
                     [handicapVertexStrings componentsJoinedByString:@", "]];
    return false;
  }

  self.setup = [setupStrings componentsJoinedByString:@", "];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) parseSgfDataForSetupPlayer:(NSString**)errorMessage
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

  /// Expected format by later processing is: "B" or "W"
  self.setupPlayer = @"";

  bool sgfSetupPlayerColorValueFound = false;
  SGFCColor sgfSetupPlayerColorValue = SGFCColorBlack;
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

      sgfSetupPlayerColorValueFound = true;
      sgfSetupPlayerColorValue = setupPlayerProperty.propertyValue.toSingleValue.toColorValue.colorValue;
    }
  }

  if (sgfSetupPlayerColorValueFound)
  {
    self.setupPlayer = (sgfSetupPlayerColorValue == SGFCColorBlack) ? @"B" : @"W";
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) parseSgfDataForMoves:(NSString**)errorMessage
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

  /// Expected format by later processing is: "color vertex, color vertex, color vertex[...]"
  self.moves = @"";

  NSMutableArray* moveStrings = [NSMutableArray array];
  for (SGFCNode* sgfNode in self.sgfMainVariationNodes)
  {
    NSArray* moveProperties = [sgfNode propertiesWithCategory:SGFCPropertyCategoryMove];
    for (SGFCProperty* moveProperty in moveProperties)
    {
      NSString* colorString;
      SGFCPropertyType propertyType = moveProperty.propertyType;
      if (propertyType == SGFCPropertyTypeB)
        colorString = @"B";
      else if (propertyType == SGFCPropertyTypeW)
        colorString = @"W";
      else
        continue;  // not interested in other move properties

      SGFCGoMove* goMove = moveProperty.propertyValue.toSingleValue.toMoveValue.toGoMoveValue.goMove;
      if (! goMove)
      {
        *errorMessage = @"SgfcKit interfacing error while determining moves: Missing SGFCGoMove object.";
        return false;
      }

      NSString* vertexString;
      if (goMove.isPassMove)
      {
        vertexString = @"pass";
      }
      else
      {
        SGFCGoPoint* goPoint = goMove.stone.location;
        if (! [goPoint hasPositionInGoPointNotation:SGFCGoPointNotationHybrid])
        {
          *errorMessage = @"SgfcKit interfacing error while determining moves: SGFCGoPoint not available in hybrid notation.";
          return false;
        }

        vertexString = [goPoint positionInGoPointNotation:SGFCGoPointNotationHybrid];
      }

      NSString* moveString = [NSString stringWithFormat:@"%@ %@", colorString, vertexString];
      [moveStrings addObject:moveString];
    }
  }

  self.moves = [moveStrings componentsJoinedByString:@", "];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (void) setupGoGame
{
  // The following sequence must always be run in its entirety. If an error
  // occurs it is handled right at the source and is never escalated to this
  // method. In practice, this can only happen when setupSetup:() encounters
  // an illegal setup or setupMoves:() encounters illegal moves. If an error
  // occurs, handleCommandFailed:() is invoked behind our back to set up a new
  // clean game. All game characteristics that have been set up to then are
  // discarded.
  [self startNewGameForSuccessfulCommand:true boardSize:self.boardSize];
  [self setupHandicap:self.handicap];
  [self setupSetup:self.setup];
  [self setupSetupPlayer:self.setupPlayer];
  [self setupKomi:self.komi];
  [self setupMoves:self.moves];
  [self syncGtpEngine];

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
}

// -----------------------------------------------------------------------------
/// @brief Starts the new game.
// -----------------------------------------------------------------------------
- (void) startNewGameForSuccessfulCommand:(bool)success boardSize:(enum GoBoardSize)boardSize
{
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
  [command submit];

  // Restore the original board size (is a user preference which should should
  // not be overwritten by the loaded game's setting)
  model.boardSize = oldBoardSize;
}

// -----------------------------------------------------------------------------
/// @brief Sets up handicap for the new game, using the information in
/// @a handicapString.
///
/// Expected format for @a handicapString is: "vertex vertex vertex[...]"
///
/// @a handicapString may be empty to indicate that there is no handicap.
// -----------------------------------------------------------------------------
- (void) setupHandicap:(NSString*)handicapString
{
  GoGame* game = [GoGame sharedGame];
  NSMutableArray* handicapPoints = [NSMutableArray arrayWithCapacity:0];
  if (0 == handicapString.length)
  {
    // do nothing, just leave the empty array to be applied to the GoGame
    // instance; this is important because the GoGame instance might have been
    // set up by NewGameCommand with a different default handicap
  }
  else
  {
    GoBoard* board = game.board;
    NSArray* handicapVertices = [handicapString componentsSeparatedByString:@" "];
    for (NSString* vertex in handicapVertices)
    {
      GoPoint* point = [board pointAtVertex:vertex];
      [handicapPoints addObject:point];
    }
  }
  // GoGame takes care to place black stones on the points
  game.handicapPoints = handicapPoints;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the setup stones prior to the first move of the game, using
/// the information in @a setupString.
///
/// Expected format for @a setupString:
///   "color vertex, color vertex, color vertex[...]"
///
/// @a setupString may be empty to indicate that there are no stones to set up.
///
/// @note If an error occurs while this method runs, handleCommandFailed:() is
/// invoked with an appropriate error message.
// -----------------------------------------------------------------------------
- (void) setupSetup:(NSString*)setupString
{
  if (setupString.length == 0)
    return;

  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;
  NSArray* handicapPoints = game.handicapPoints;

  NSMutableArray* blackSetupPoints = [NSMutableArray arrayWithCapacity:0];
  NSMutableArray* whiteSetupPoints = [NSMutableArray arrayWithCapacity:0];
  NSMutableArray* setupVertexes = [NSMutableArray arrayWithCapacity:0];
  NSArray* setupStoneStrings = [setupString componentsSeparatedByString:@", "];

  for (NSString* setupStoneString in setupStoneStrings)
  {
    NSArray* setupStoneStringComponents = [setupStoneString componentsSeparatedByString:@" "];

    NSString* colorString = [setupStoneStringComponents objectAtIndex:0];
    NSString* vertexString = [setupStoneStringComponents objectAtIndex:1];

    enum GoColor stoneColor;
    bool success = [self parseColorString:colorString
                                    color:&stoneColor];
    if (! success)
    {
      NSString* errorMessageFormat = @"Game contains an invalid board setup prior to the first move.\n\nThe stone at intersection %@ has an invalid color. Invalid color designation: %@. Supported are 'B' for black and 'W' for white.";
      NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, vertexString, colorString];
      [self handleCommandFailed:errorMessage];
      return;
    }

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
      NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, vertexString];
      [self handleCommandFailed:errorMessage];
      return;
    }

    // Fuego should not list stones twice - if two different SGF setup
    // properties set up the same intersection Fuego should only list the
    // last setup. We perform the check anyway, to be on the safe side.
    if ([setupVertexes containsObject:point.vertex.string])
    {
      NSString* errorMessageFormat = @"Game contains an invalid board setup prior to the first move.\n\nAn intersection must be set up with a stone only once, but intersection %@ is set up with a stone at least twice.";
      NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, vertexString];
      [self handleCommandFailed:errorMessage];
      return;
    }
    [setupVertexes addObject:point.vertex.string];

    if ([handicapPoints containsObject:point])
    {
      NSString* colorName = [[NSString stringWithGoColor:stoneColor] lowercaseString];
      NSString* errorMessageFormat = @"Game contains an invalid board setup prior to the first move.\n\nThe intersection %@ is set up with a %@ stone although it is already occupied by a black handicap stone.";
      NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, vertexString, colorName];
      [self handleCommandFailed:errorMessage];
      return;
    }

    if (stoneColor == GoColorBlack)
      [blackSetupPoints addObject:point];
    else
      [whiteSetupPoints addObject:point];
  }

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
    NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, exception.reason];
    [self handleCommandFailed:errorMessage];
    return;
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets up the player to play first for the new game, using the
/// information in @a setupPlayerString.
///
/// Expected format for @a setupPlayerString is: "B" or "W"
///
/// @a setupPlayerString may be empty to indicate that no player is set up to
/// play first. In that case, since there is no explicit setup, the game logic
/// determines the player who plays first (e.g. in a normal game with no
/// handicap, black plays first).
///
/// @note If an error occurs while this method runs, handleCommandFailed:() is
/// invoked with an appropriate error message.
// -----------------------------------------------------------------------------
- (void) setupSetupPlayer:(NSString*)setupPlayerString
{
  enum GoColor setupFirstMoveColor;
  if (0 == setupPlayerString.length)
  {
    setupFirstMoveColor = GoColorNone;
  }
  else
  {
    bool success = [self parseColorString:setupPlayerString
                                    color:&setupFirstMoveColor];
    if (! success)
    {
      NSString* errorMessageFormat = @"Game attempts to set up an invalid player to play the first move. Invalid player designation: %@. Supported are 'B' for black and 'W' for white.";
      NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, setupPlayerString];
      [self handleCommandFailed:errorMessage];
      return;
    }
  }

  GoGame* game = [GoGame sharedGame];
  game.setupFirstMoveColor = setupFirstMoveColor;
}

// -----------------------------------------------------------------------------
/// @brief Sets up komi for the new game, using the information in
/// @a komiString.
///
/// Expected format for @a komiString is a fractional number (e.g. "6.5").
///
/// @a komiString may be empty to indicate that there is no komi.
// -----------------------------------------------------------------------------
- (void) setupKomi:(NSString*)komiString
{
  double komi;
  if (0 == komiString.length)
    komi = 0;
  else
    komi = [komiString doubleValue];

  GoGame* game = [GoGame sharedGame];
  game.komi = komi;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the moves for the new game, using the information in
/// @a movesString.
///
/// Expected format for @a movesString:
///   "color vertex, color vertex, color vertex[...]"
///
/// @a movesString may be empty to indicate that there are no moves.
///
/// @note If an error occurs while this method runs, handleCommandFailed:() is
/// invoked with an appropriate error message.
// -----------------------------------------------------------------------------
- (void) setupMoves:(NSString*)movesString
{
  NSArray* moveList;
  if (0 == movesString.length)
    moveList = [NSArray array];
  else
    moveList = [movesString componentsSeparatedByString:@", "];
  [self replayMoves:moveList];
}

// -----------------------------------------------------------------------------
/// @brief Replays the moves in @a moveList.
///
/// @a moveList is expected to contain NSString objects, each having the format
/// "color vertex" (e.g. "W C13").
///
/// The asynchronous command delegate is updated continuously with progress
/// information as the moves are replayed. In an ideal world we would have
/// fine-grained progress updates with as many steps as there are moves.
/// However, when there are many moves to be replayed this wastes a lot of
/// precious CPU cycles for GUI updates, considerably slowing down the process
/// of loading a game - on older devices to an intolerable level. In the real
/// world, we therefore limit the number of progress updates to a fixed,
/// hard-coded number.
///
/// @note If an error occurs while this method runs, handleCommandFailed:() is
/// invoked with an appropriate error message.
// -----------------------------------------------------------------------------
- (void) replayMoves:(NSArray*)moveList
{
  GoGame* game = [GoGame sharedGame];

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
    for (NSString* moveString in moveList)
    {
      enum GoColor moveColor;
      bool isResignMove;
      enum GoMoveType moveType;
      GoPoint* point;
      enum ParseMoveStringResult result = [self parseMoveString:moveString
                                                      moveColor:&moveColor
                                           isResignMove:&isResignMove
                                                       moveType:&moveType
                                                          point:&point];
      if (ParseMoveStringResultSuccess != result)
      {
        [self handleInvalidMoveString:moveString parseMoveStringResult:result];
        return;
      }

      // Here we support if the .sgf contains moves by non-alternating colors,
      // anywhere in the game. Thus the user can ***VIEW*** almost any .sgf
      // game, even though the app itself is not capable of producing such
      // games.
      game.nextMoveColor = moveColor;

      NSString* colorName = [NSString stringWithGoColor:moveColor];
      if (isResignMove)
      {
        if (GoGameStateGameHasEnded == game.state)
        {
          NSString* errorMessageFormat = @"Game contains a resignation after the game has already ended (%@): Move %d, played by %@.";
          NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, [self gameHasEndedReasonDescription:game.reasonForGameHasEnded], (movesReplayed + 1), colorName];
          [self handleCommandFailed:errorMessage];
          return;
        }
        [game resign];
      }
      else
      {
        if (GoGameStateGameHasEnded == game.state)
        {
          if (GoGameHasEndedReasonTwoPasses != game.reasonForGameHasEnded)
          {
            NSString* errorMessage;
            if (GoMoveTypePass == moveType)
            {
              errorMessage = [NSString stringWithFormat:@"Game contains a pass move after the game has already ended (%@): Move %d, played by %@.",
                              [self gameHasEndedReasonDescription:game.reasonForGameHasEnded], (movesReplayed + 1), colorName];
            }
            else
            {
              errorMessage = [NSString stringWithFormat:@"Game contains a move after the game has already ended (%@): Move %d, played by %@, on intersection %@.",
                              [self gameHasEndedReasonDescription:game.reasonForGameHasEnded], (movesReplayed + 1), colorName, point.vertex.string];
            }
            [self handleCommandFailed:errorMessage];
            return;
          }
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
            NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, (movesReplayed + 1), colorName, point.vertex.string, illegalReasonString];
            [self handleCommandFailed:errorMessage];
            return;
          }
          [game play:point];
        }
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
    NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, [exception name], [exception reason]];
    [self handleCommandFailed:errorMessage];
    return;
  }
}

// -----------------------------------------------------------------------------
/// @brief Attempts to parse @a moveString. If the parse attempt succeeds,
/// returns #ParseMoveStringResultSuccess and fills the out parameters with the
/// result. If the parse attempt fails, returns one of the remaining values from
/// the #ParseMoveStringResult enumeration. The content of the out parameters is
/// undefined in this case.
///
/// If parsing is successful, the out parameters are filled as follows:
/// - @a moveColor is always filled
/// - If @a isResignMove is true, the content of the remaining parameters is
///   undefined
/// - If @a isResignMove is false, @a moveType is either #GoMoveTypePass or
///   #GoMoveTypePlay
/// - If @a moveType is #GoMoveTypePass, the content of @a point is undefined
///
/// This is a private helper for replayMoves:().
// -----------------------------------------------------------------------------
- (enum ParseMoveStringResult) parseMoveString:(NSString*)moveString
                                     moveColor:(enum GoColor*)moveColor
                                  isResignMove:(bool*)isResignMove
                                      moveType:(enum GoMoveType*)moveType
                                         point:(GoPoint**)point
{
  NSArray* moveStringComponents = [moveString componentsSeparatedByString:@" "];
  if (moveStringComponents.count != 2)
    return ParseMoveStringResultInvalidFormat;

  bool success = [self parseColorString:[moveStringComponents objectAtIndex:0]
                                  color:moveColor];
  if (! success)
    return ParseMoveStringResultInvalidColor;

  NSString* vertexString = [[moveStringComponents objectAtIndex:1] lowercaseString];
  if ([vertexString isEqualToString:@"resign"])  // not sure if this is ever sent
  {
    *isResignMove = true;
    return ParseMoveStringResultSuccess;
  }
  else if ([vertexString isEqualToString:@"pass"])
  {
    *isResignMove = false;
    *moveType = GoMoveTypePass;
    return ParseMoveStringResultSuccess;
  }
  else
  {
    *isResignMove = false;
    *moveType = GoMoveTypePlay;
    @try
    {
      *point = [[GoGame sharedGame].board pointAtVertex:vertexString];
      return ParseMoveStringResultSuccess;
    }
    @catch (NSException* exception)
    {
      // If the vertex is not legal an exception is raised:
      // - NSInvalidArgumentException if vertex is malformed
      // - NSRangeException if vertex compounds are out of range
      // For our purposes, both exception types are the same.
      return ParseMoveStringResultInvalidVertex;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs all steps required to handle the case that a move string
/// provided by Fuego could not be parsed.
///
/// This is a private helper for replayMoves:().
// -----------------------------------------------------------------------------
- (void) handleInvalidMoveString:(NSString*)moveString parseMoveStringResult:(enum ParseMoveStringResult)parseMoveStringResult
{
  NSString* errorMessage;
  switch (parseMoveStringResult)
  {
    case ParseMoveStringResultInvalidFormat:
    {
      errorMessage = @"Move string has invalid format";
      break;
    }
    case ParseMoveStringResultInvalidColor:
    {
      errorMessage = @"Move string contains unsupported player color";
      break;
    }
    case ParseMoveStringResultInvalidVertex:
    {
      errorMessage = @"Move string contains invalid intersection";
      break;
    }
    default:
    {
      errorMessage = @"Unknown error";
      assert(0);
      break;
    }
  }
  errorMessage = [NSString stringWithFormat:@"Internal error: %@. Move string = %@", errorMessage, moveString];
  [self handleCommandFailed:errorMessage];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for @a gameHasEndedReason that can be
/// incorporated into an error message.
///
/// This is a private helper for replayMoves:().
// -----------------------------------------------------------------------------
- (NSString*) gameHasEndedReasonDescription:(enum GoGameHasEndedReason)gameHasEndedReason
{
  switch (gameHasEndedReason)
  {
    case GoGameHasEndedReasonTwoPasses:
      return @"by two pass moves";
    case GoGameHasEndedReasonThreePasses:
      return @"by three pass moves";
    case GoGameHasEndedReasonFourPasses:
      return @"by four pass moves";
    case GoGameHasEndedReasonResigned:
      return @"by resignation";
    default:
      return @"by an unkown reason";
  }
}

// -----------------------------------------------------------------------------
/// @brief Attempts to parse @a colorString. If the parse attempt succeeds,
/// returns true and fills the out parameter with the result. If the parse
/// attempt fails, returns false. The content of the out parameters is
/// undefined in this case.
///
/// This is a private helper.
// -----------------------------------------------------------------------------
- (bool) parseColorString:(NSString*)colorString
                    color:(enum GoColor*)color
{
  colorString = [colorString lowercaseString];

  if ([colorString isEqualToString:@"b"])
  {
    *color = GoColorBlack;
    return true;
  }
  else if ([colorString isEqualToString:@"w"])
  {
    *color = GoColorWhite;
    return true;
  }
  else
  {
    return false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Synchronizes the state of the GTP engine with the state of the
/// current GoGame.
///
/// This method invokes SyncGTPEngineCommand. It expects that NewGameCommand
/// has set up the GTP engine with a number of other things, notably the board
/// size and the game rules.
///
/// @note If an error occurs while this method runs, handleCommandFailed:() is
/// invoked with an appropriate error message.
// -----------------------------------------------------------------------------
- (void) syncGtpEngine
{
  bool syncSuccess = [[[[SyncGTPEngineCommand alloc] init] autorelease] submit];
  if (! syncSuccess)
  {
    NSString* errorMessage = @"Failed to synchronize the GTP engine state with the current GoGame state";
    [self handleCommandFailed:errorMessage];
  }
}

// -----------------------------------------------------------------------------
/// @brief Notifies the GoGameDocument associated with the new game that the
/// game was loaded.
// -----------------------------------------------------------------------------
- (void) notifyGoGameDocument
{
  NSString* gameName = [[self.filePath lastPathComponent] stringByDeletingPathExtension];
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
  // Start a new game anyway, with the goal to bring the app into a controlled
  // state that matches the state of the GTP engine.
  [self startNewGameForSuccessfulCommand:false boardSize:gDefaultBoardSize];

  // Alert must be shown on main thread, otherwise there is the possibility of
  // a crash (it's real, I've seen the crash reports!)
  [self performSelectorOnMainThread:@selector(showAlert:) withObject:message waitUntilDone:YES];
  DDLogError(@"%@", message);
}

@end
