// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "SaveSgfCommand.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoMoveInfo.h"
#import "../../go/GoMoveModel.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../player/Player.h"
#import "../../sgf/SgfUtilities.h"
#import "../../utility/PathUtilities.h"


@implementation SaveSgfCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a SaveSgfCommand object.
///
/// @note This is the designated initializer of SaveSgfCommand.
// -----------------------------------------------------------------------------
- (id) initWithSgfFilePath:(NSString*)sgfFilePath sgfFileAlreadyExists:(bool)sgfFileAlreadyExists
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.sgfFilePath = sgfFilePath;
  self.sgfFileAlreadyExists = sgfFileAlreadyExists;
  self.destinationFolderWasTouched = false;
  self.errorMessage = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SaveSgfCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.sgfFilePath = nil;
  self.errorMessage = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  SGFCDocument* sgfDocument;
  NSString* errorMessage = @"Internal error";
  bool success = [self createSgfDocument:&sgfDocument
                            errorMessage:&errorMessage];

  if (success)
  {
    success = [self validateSgfDocument:sgfDocument
                         errorMessage:&errorMessage];

    if (success)
    {
      success = [self saveSgfDocument:sgfDocument
                         errorMessage:&errorMessage];
    }
  }

  if (! success)
    self.errorMessage = errorMessage;

  return success;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) createSgfDocument:(SGFCDocument**)sgfDocument
              errorMessage:(NSString**)errorMessage
{
  *sgfDocument = [SGFCDocument document];
  SGFCGame* sgfGame = (*sgfDocument).game;
  SGFCNode* rootNode = sgfGame.rootNode;
  SGFCNode* gameInfoNode = rootNode;
  SGFCTreeBuilder* treeBuilder = sgfGame.treeBuilder;

  GoGame* goGame = [GoGame sharedGame];
  SGFCBoardSize boardSize = SGFCBoardSizeMakeSquare(goGame.board.size);

  [self addRootPropertiesToRootNode:rootNode
               withValuesFromGoGame:goGame
                          boardSize:boardSize];

  [self addKomiAndHandicapPropertiesToGameInfoNode:gameInfoNode
                              withValuesFromGoGame:goGame
                                         boardSize:boardSize];
  [self addPlayerNamesToGameInfoNode:gameInfoNode
                withValuesFromGoGame:goGame];

  SGFCNode* setupNode = [self addSetupNodeAfterGameInfoNode:gameInfoNode
                                       withValuesFromGoGame:goGame
                                                  boardSize:boardSize
                                                treeBuilder:treeBuilder];

  SGFCNode* previousNode = (setupNode != nil) ? setupNode : gameInfoNode;
  [self addMoveNodesAfterNode:previousNode
         withValuesFromGoGame:goGame
                    boardSize:boardSize
                  treeBuilder:treeBuilder];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createSgfDocument:errorMessage:()
// -----------------------------------------------------------------------------
- (void) addRootPropertiesToRootNode:(SGFCNode*)rootNode
                withValuesFromGoGame:(GoGame*)goGame
                           boardSize:(SGFCBoardSize)boardSize
{
  SGFCGameType gameType = SGFCGameTypeGo;
  SGFCNumberPropertyValue* gmPropertyValue = [SGFCPropertyValueFactory propertyValueWithGameType:gameType];
  SGFCGameTypeProperty* gmProperty = [SGFCPropertyFactory gameTypePropertyWithNumberPropertyValue:gmPropertyValue];
  [rootNode setProperty:gmProperty];

  SGFCNumberPropertyValue* szPropertyValue = [[[SGFCPropertyValueFactory propertyValueWithBoardSize:boardSize gameType:gameType] toSingleValue] toNumberValue];
  SGFCBoardSizeProperty* szProperty = [SGFCPropertyFactory boardSizePropertyWithNumberPropertyValue:szPropertyValue];
  [rootNode setProperty:szProperty];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createSgfDocument:errorMessage:()
// -----------------------------------------------------------------------------
- (void) addKomiAndHandicapPropertiesToGameInfoNode:(SGFCNode*)gameInfoNode
                               withValuesFromGoGame:(GoGame*)goGame
                                          boardSize:(SGFCBoardSize)boardSize
{
  // We set the komi explicitly even if it's 0.0
  SGFCRealPropertyValue* kmPropertyValue = [SGFCPropertyValueFactory propertyValueWithReal:goGame.komi];
  SGFCProperty* kmProperty = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeKM value:kmPropertyValue];
  [gameInfoNode setProperty:kmProperty];

  // We set the number of handicap stones explicitly even if it's 0
  NSArray* handicapPoints = goGame.handicapPoints;
  SGFCNumberPropertyValue* haPropertyValue = [SGFCPropertyValueFactory propertyValueWithNumber:handicapPoints.count];
  SGFCProperty* haProperty = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeHA value:haPropertyValue];
  [gameInfoNode setProperty:haProperty];

  if (handicapPoints.count > 0)
  {
    [self addSgfPropertyWithType:SGFCPropertyTypeAB
                          toNode:gameInfoNode
          withValuesFromGoPoints:handicapPoints
                       boardSize:boardSize];
  }

  if (goGame.state == GoGameStateGameHasEnded)
  {
    SGFCGameResult gameResult = [SgfUtilities gameResultForGoGameHasEndedReason:goGame.reasonForGameHasEnded];

    // Some GoGameHasEndedReason values actually cannot be mapped to
    // SGFCGameResult
    if (gameResult.IsValid)
    {
      NSString* gameResultAsString = SGFCGameResultToPropertyValue(gameResult);

      SGFCSimpleTextPropertyValue* rePropertyValue = [SGFCPropertyValueFactory propertyValueWithSimpleText:gameResultAsString];
      SGFCProperty* reProperty = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeRE value:rePropertyValue];
      [gameInfoNode setProperty:reProperty];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createSgfDocument:errorMessage:()
// -----------------------------------------------------------------------------
- (void) addPlayerNamesToGameInfoNode:(SGFCNode*)gameInfoNode
                 withValuesFromGoGame:(GoGame*)goGame
{
  SGFCSimpleTextPropertyValue* pbPropertyValue = [SGFCPropertyValueFactory propertyValueWithSimpleText:goGame.playerBlack.player.name];
  SGFCProperty* pbProperty = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypePB value:pbPropertyValue];
  [gameInfoNode setProperty:pbProperty];

  SGFCSimpleTextPropertyValue* pwPropertyValue = [SGFCPropertyValueFactory propertyValueWithSimpleText:goGame.playerWhite.player.name];
  SGFCProperty* pwProperty = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypePW value:pwPropertyValue];
  [gameInfoNode setProperty:pwProperty];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createSgfDocument:errorMessage:()
// -----------------------------------------------------------------------------
- (SGFCNode*) addSetupNodeAfterGameInfoNode:(SGFCNode*)gameInfoNode
                       withValuesFromGoGame:(GoGame*)goGame
                                  boardSize:(SGFCBoardSize)boardSize
                                treeBuilder:(SGFCTreeBuilder*)treeBuilder
{
  NSArray* blackSetupPoints = goGame.blackSetupPoints;
  NSArray* whiteSetupPoints = goGame.whiteSetupPoints;
  enum GoColor setupFirstMoveColor = goGame.setupFirstMoveColor;
  if (blackSetupPoints.count == 0 && whiteSetupPoints.count == 0 && setupFirstMoveColor == GoColorNone)
    return nil;

  SGFCNode* setupNode = [SGFCNode node];
  [treeBuilder setFirstChild:setupNode ofNode:gameInfoNode];

  if (blackSetupPoints.count > 0)
  {
    [self addSgfPropertyWithType:SGFCPropertyTypeAB
                          toNode:setupNode
          withValuesFromGoPoints:blackSetupPoints
                       boardSize:boardSize];
  }

  if (whiteSetupPoints.count > 0)
  {
    [self addSgfPropertyWithType:SGFCPropertyTypeAW
                          toNode:setupNode
          withValuesFromGoPoints:whiteSetupPoints
                       boardSize:boardSize];
  }

  if (setupFirstMoveColor != GoColorNone)
  {
    SGFCColor color = (setupFirstMoveColor == GoColorBlack) ? SGFCColorBlack : SGFCColorWhite;
    SGFCColorPropertyValue* plPropertyValue = [SGFCPropertyValueFactory propertyValueWithColor:color];
    SGFCProperty* plProperty = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypePL value:plPropertyValue];
    [setupNode setProperty:plProperty];
  }

  return setupNode;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createSgfDocument:errorMessage:()
// -----------------------------------------------------------------------------
- (void) addMoveNodesAfterNode:(SGFCNode*)previousNode
          withValuesFromGoGame:(GoGame*)goGame
                     boardSize:(SGFCBoardSize)boardSize
                   treeBuilder:(SGFCTreeBuilder*)treeBuilder
{
  GoMove* goMove = goGame.moveModel.firstMove;
  while (goMove != nil)
  {
    SGFCNode* moveNode = [SGFCNode node];
    [treeBuilder setFirstChild:moveNode ofNode:previousNode];

    [self addSgfPropertyToNode:moveNode
             withValueFromMove:goMove
                     boardSize:boardSize];

    previousNode = moveNode;
    goMove = goMove.next;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// addKomiAndHandicapPropertiesToGameInfoNode:withValuesFromGoGame:boardSize:()
/// and
/// addSetupNodeAfterGameInfoNode:withValuesFromGoGame:boardSize:treeBuilder:().
// -----------------------------------------------------------------------------
- (void) addSgfPropertyWithType:(SGFCPropertyType)propertyType
                         toNode:(SGFCNode*)node
         withValuesFromGoPoints:(NSArray*)goPoints
                      boardSize:(SGFCBoardSize)boardSize
{
  NSMutableArray* propertyValues = [NSMutableArray array];
  for (GoPoint* goPoint in goPoints)
  {
    SGFCColor color = (propertyType == SGFCPropertyTypeAB) ? SGFCColorBlack : SGFCColorWhite;
    SGFCStonePropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithGoStone:goPoint.vertex.string
                                                                                     boardSize:boardSize
                                                                                         color:color];
    [propertyValues addObject:propertyValue];
  }

  SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                          values:propertyValues];
  [node setProperty:property];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// addMoveNodesAfterNode:withValuesFromGoGame:boardSize:treeBuilder:()
// -----------------------------------------------------------------------------
- (void) addSgfPropertyToNode:(SGFCNode*)node
            withValueFromMove:(GoMove*)goMove
                    boardSize:(SGFCBoardSize)boardSize
{
  SGFCColor playerColor;
  SGFCPropertyType propertyType;
  if (goMove.player.black)
  {
    playerColor = SGFCColorBlack;
    propertyType = SGFCPropertyTypeB;
  }
  else
  {
    playerColor = SGFCColorWhite;
    propertyType = SGFCPropertyTypeW;
  }

  SGFCGoMovePropertyValue* movePropertyValue;
  if (goMove.type == GoMoveTypePlay)
  {
    movePropertyValue = [SGFCPropertyValueFactory propertyValueWithGoMove:goMove.point.vertex.string
                                                                boardSize:boardSize
                                                                    color:playerColor];
  }
  else
  {
    movePropertyValue = [SGFCPropertyValueFactory propertyValueWithGoMovePlayedByColor:playerColor];
  }

  SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                           value:movePropertyValue];
  [node setProperty:property];

  if (goMove.moveInfo)
  {
    [self addSgfPropertiesToNode:node
          withValuesFromMoveInfo:goMove.moveInfo];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// addSgfPropertyToNode:withValueFromMove:boardSize
// -----------------------------------------------------------------------------
- (void) addSgfPropertiesToNode:(SGFCNode*)node
         withValuesFromMoveInfo:(GoMoveInfo*)moveInfo
{
  if (moveInfo.shortDescription != nil)
  {
    SGFCPropertyType propertyType = SGFCPropertyTypeN;
    SGFCSimpleTextPropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithSimpleText:moveInfo.shortDescription];
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                             value:propertyValue];
    [node setProperty:property];
  }

  if (moveInfo.longDescription != nil)
  {
    SGFCPropertyType propertyType = SGFCPropertyTypeC;
    SGFCTextPropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithText:moveInfo.longDescription];
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                             value:propertyValue];
    [node setProperty:property];
  }

  if (moveInfo.goBoardPositionValuation != GoBoardPositionValuationNone)
  {
    SGFCPropertyType propertyType;
    SGFCDouble doubleValue;
    switch (moveInfo.goBoardPositionValuation)
    {
      case GoBoardPositionValuationGoodForBlack:
        propertyType = SGFCPropertyTypeGB;
        doubleValue = SGFCDoubleNormal;
        break;
      case GoBoardPositionValuationVeryGoodForBlack:
        propertyType = SGFCPropertyTypeGB;
        doubleValue = SGFCDoubleEmphasized;
        break;
      case GoBoardPositionValuationGoodForWhite:
        propertyType = SGFCPropertyTypeGW;
        doubleValue = SGFCDoubleNormal;
        break;
      case GoBoardPositionValuationVeryGoodForWhite:
        propertyType = SGFCPropertyTypeGW;
        doubleValue = SGFCDoubleEmphasized;
        break;
      case GoBoardPositionValuationEven:
        propertyType = SGFCPropertyTypeDM;
        doubleValue = SGFCDoubleNormal;
        break;
      case GoBoardPositionValuationVeryEven:
        propertyType = SGFCPropertyTypeDM;
        doubleValue = SGFCDoubleEmphasized;
        break;
      case GoBoardPositionValuationUnclear:
        propertyType = SGFCPropertyTypeUC;
        doubleValue = SGFCDoubleNormal;
        break;
      case GoBoardPositionValuationVeryUnclear:
        propertyType = SGFCPropertyTypeUC;
        doubleValue = SGFCDoubleEmphasized;
        break;
      default:
        assert(0);
        DDLogError(@"%@: Unexpected GoBoardPositionValuation value %d", self, (int)moveInfo.goBoardPositionValuation);
        return;
    }
    SGFCDoublePropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithDouble:doubleValue];
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                             value:propertyValue];
    [node setProperty:property];
  }

  if (moveInfo.goBoardPositionHotspotDesignation != GoBoardPositionHotspotDesignationNone)
  {
    SGFCPropertyType propertyType = SGFCPropertyTypeHO;
    SGFCDouble doubleValue;
    if (moveInfo.goBoardPositionHotspotDesignation == GoBoardPositionHotspotDesignationYes)
      doubleValue = SGFCDoubleNormal;
    else
      doubleValue = SGFCDoubleEmphasized;
    SGFCDoublePropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithDouble:doubleValue];
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                             value:propertyValue];
    [node setProperty:property];
  }

  if (moveInfo.estimatedScoreSummary != GoScoreSummaryNone)
  {
    SGFCPropertyType propertyType = SGFCPropertyTypeV;
    SGFCReal realValue;
    switch (moveInfo.estimatedScoreSummary)
    {
      case GoScoreSummaryBlackWins:
        realValue = moveInfo.estimatedScoreValue;
        break;
      case GoScoreSummaryWhiteWins:
        realValue = -moveInfo.estimatedScoreValue;
        break;
      case GoScoreSummaryTie:
        realValue = 0.0;
        break;
      default:
        assert(0);
        DDLogError(@"%@: Unexpected GoScoreSummary value %d", self, (int)moveInfo.estimatedScoreSummary);
        return;
    }
    SGFCRealPropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithReal:realValue];
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                             value:propertyValue];
    [node setProperty:property];
  }

  if (moveInfo.goMoveValuation != GoMoveValuationNone)
  {
    SGFCPropertyType propertyType;
    SGFCDouble doubleValue;
    switch (moveInfo.goMoveValuation)
    {
      case GoMoveValuationGood:
        propertyType = SGFCPropertyTypeTE;
        doubleValue = SGFCDoubleNormal;
        break;
      case GoMoveValuationVeryGood:
        propertyType = SGFCPropertyTypeTE;
        doubleValue = SGFCDoubleEmphasized;
        break;
      case GoMoveValuationBad:
        propertyType = SGFCPropertyTypeBM;
        doubleValue = SGFCDoubleNormal;
        break;
      case GoMoveValuationVeryBad:
        propertyType = SGFCPropertyTypeBM;
        doubleValue = SGFCDoubleEmphasized;
        break;
      case GoMoveValuationInteresting:
        propertyType = SGFCPropertyTypeIT;
        doubleValue = SGFCDoubleNormal;
        break;
      case GoMoveValuationVeryInteresting:
        propertyType = SGFCPropertyTypeIT;
        doubleValue = SGFCDoubleEmphasized;
        break;
      case GoMoveValuationDoubtful:
        propertyType = SGFCPropertyTypeDO;
        doubleValue = SGFCDoubleNormal;
        break;
      case GoMoveValuationVeryDoubtful:
        propertyType = SGFCPropertyTypeDO;
        doubleValue = SGFCDoubleEmphasized;
        break;
      default:
        assert(0);
        DDLogError(@"%@: Unexpected GoMoveValuation value %d", self, (int)moveInfo.goMoveValuation);
        return;
    }
    SGFCDoublePropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithDouble:doubleValue];
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                             value:propertyValue];
    [node setProperty:property];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) validateSgfDocument:(SGFCDocument*)sgfDocument
                errorMessage:(NSString**)errorMessage
{
  NSString* errorMessageContextString = @"validating the game data to write";

  SGFCDocumentWriter* documentWriter = [SGFCDocumentWriter documentWriter];
  SGFCDocumentWriteResult* result;
  @try
  {
    result = [documentWriter validateDocument:sgfDocument];
  }
  @catch (NSException* exception)
  {
    *errorMessage = [self errorMessageWithException:exception
                                 usingContextString:errorMessageContextString];
    return false;
  }

  return [self evaluateDocumentWriteResult:result
                        usingContextString:errorMessageContextString
                              errorMessage:errorMessage];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) saveSgfDocument:(SGFCDocument*)sgfDocument
            errorMessage:(NSString**)errorMessage
{
  NSString* temporaryDirectory = NSTemporaryDirectory();
  NSString* temporaryFilePath = [temporaryDirectory stringByAppendingPathComponent:sgfTemporaryFileName];

  bool saveSuccess = [self saveSgfDocument:sgfDocument
                       toTemporaryFilePath:temporaryFilePath
                              errorMessage:errorMessage];
  if (! saveSuccess)
    return false;

  self.destinationFolderWasTouched = true;

  bool moveSuccess = [self moveTemporaryFilePathToArchiveFilePath:temporaryFilePath
                                                     errorMessage:errorMessage];
  return moveSuccess;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for saveSgfDocument:errorMessage:()
// -----------------------------------------------------------------------------
- (bool) saveSgfDocument:(SGFCDocument*)sgfDocument
     toTemporaryFilePath:(NSString*)temporaryFilePath
            errorMessage:(NSString**)errorMessage
{
  NSString* errorMessageContextString = @"writing the game data to a temporary file";

  SGFCDocumentWriter* documentWriter = [SGFCDocumentWriter documentWriter];
  SGFCDocumentWriteResult* result;
  @try
  {
    result = [documentWriter writeSgfContent:sgfDocument toFile:temporaryFilePath];
  }
  @catch (NSException* exception)
  {
    // Validation in a previous step should have caught any document object
    // tree errors, there is no reason why this should occur
    *errorMessage = [self errorMessageWithException:exception
                                 usingContextString:errorMessageContextString];
    return false;
  }

  // Validation in a previous step should have caught any errors related to the
  // SGF data. This should fail only in the unlikely case that there is a
  // problem with filesystem interaction.
  bool success = [self evaluateDocumentWriteResult:result
                                usingContextString:errorMessageContextString
                                      errorMessage:errorMessage];
  if (! success)
  {
    // We can't be sure if the file was written or not. Remove it if it exists.
    [PathUtilities deleteItemIfExists:temporaryFilePath];
    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for saveSgfDocument:errorMessage:()
// -----------------------------------------------------------------------------
- (bool) moveTemporaryFilePathToArchiveFilePath:(NSString*)temporaryFilePath
                                   errorMessage:(NSString**)errorMessage
{
  NSError* error;
  BOOL success = [PathUtilities moveItemAtPath:temporaryFilePath
                                 overwritePath:self.sgfFilePath
                                         error:&error];

  if (! success)
  {
    [PathUtilities deleteItemIfExists:temporaryFilePath];

    if (self.sgfFileAlreadyExists)
      *errorMessage = [NSString stringWithFormat:@"Overwriting the archived game failed. Reason:\n\n%@", [error localizedDescription]];
    else
      *errorMessage = [NSString stringWithFormat:@"Writing to saved game to the archive failed. Reason:\n\n%@", [error localizedDescription]];

    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for validateSgfDocument:errorMessage:() and
/// saveSgfDocument:toTemporaryFilePath:errorMessage().
// -----------------------------------------------------------------------------
- (NSString*) errorMessageWithException:(NSException*)exception
                     usingContextString:(NSString*)contextString
{
  return [NSString stringWithFormat:@"An unexpected error occurred while %@. The technical error message is:\n\n%@",
          contextString,
          exception.name];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for validateSgfDocument:errorMessage:() and
/// saveSgfDocument:toTemporaryFilePath:errorMessage().
// -----------------------------------------------------------------------------
- (bool) evaluateDocumentWriteResult:(SGFCDocumentWriteResult*)documentWriteResult
                  usingContextString:(NSString*)contextString
                        errorMessage:(NSString**)errorMessage
{
  if (documentWriteResult.exitCode == SGFCExitCodeFatalError)
  {
    for (SGFCMessage* message in documentWriteResult.parseResult)
    {
      if (message.messageType == SGFCMessageTypeFatalError)
      {
        *errorMessage = [NSString stringWithFormat:@"A fatal error occurred while %@. The technical error message is:\n\n%@",
                         contextString,
                         message.formattedMessageText];
        return false;
      }
    }

    *errorMessage = [NSString stringWithFormat:@"A fatal error occurred while %@. The SgfcKit library did not specify a reason for the failure.",
                     contextString];
    return false;
  }
  else if (documentWriteResult.exitCode == SGFCExitCodeWarning || documentWriteResult.exitCode == SGFCExitCodeError)
  {
    for (SGFCMessage* message in documentWriteResult.parseResult)
    {
      if (message.isCriticalMessage)
      {
        *errorMessage = [NSString stringWithFormat:@"A critical problem was found while %@. The technical error message is:\n\n%@",
                         contextString,
                         message.formattedMessageText];
        return false;
      }
    }
  }

  return true;
}

@end
