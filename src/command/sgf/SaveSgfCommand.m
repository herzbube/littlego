// -----------------------------------------------------------------------------
// Copyright 2021-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../go/GoNode.h"
#import "../../go/GoNodeAnnotation.h"
#import "../../go/GoNodeMarkup.h"
#import "../../go/GoNodeModel.h"
#import "../../go/GoNodeSetup.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../player/Player.h"
#import "../../sgf/SgfUtilities.h"
#import "../../utility/PathUtilities.h"


@implementation SaveSgfCommand

#pragma mark - Initialization and deallocation

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

#pragma mark - CommandBase methods

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

#pragma mark - Create SGF document

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

  [self addRemainingPropertiesStartingAtGameInfoNode:gameInfoNode
                                withValuesFromGoGame:goGame
                                           boardSize:boardSize
                                         treeBuilder:treeBuilder];

  return true;
}

#pragma mark - Create SGF document - Root node

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

#pragma mark - Create SGF document - Game info node

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

#pragma mark - Create SGF document - All other nodes

// -----------------------------------------------------------------------------
/// @brief Private helper for createSgfDocument:errorMessage:()
// -----------------------------------------------------------------------------
- (void) addRemainingPropertiesStartingAtGameInfoNode:(SGFCNode*)gameInfoNode
                                 withValuesFromGoGame:(GoGame*)goGame
                                            boardSize:(SGFCBoardSize)boardSize
                                          treeBuilder:(SGFCTreeBuilder*)treeBuilder
{
  NSMutableArray* stack = [NSMutableArray array];

  bool dataSourceIsRootNode = true;
  SGFCNode* parentSgfNode = gameInfoNode;
  GoNode* currentGoNode = goGame.nodeModel.rootNode;

  while (true)
  {
    while (currentGoNode)
    {
      SGFCNode* sgfNode;
      if (dataSourceIsRootNode)
      {
        // The app ensures that the root node does not contain a move. The root
        // node can contain only setup information, annotation data and/or
        // markup data.
        sgfNode = gameInfoNode;
        dataSourceIsRootNode = false;
      }
      else
      {
        sgfNode = [SGFCNode node];

        // We add the node to the document even if we don't add any properties
        // to it. If we were skipping the node there would be a gap between the
        // in-memory model and the saved data, which could cause trouble or at
        // least irritation later on (e.g. user saves a game, then loads it in
        // some other application => where the heck did the empty node go?).
        // Note 1: Loading an SGF file in this app will result in empty nodes
        // being discarded.
        // Note 2: SGFC has an option to skip empty nodes (-n), but by default
        // it retains them.
        [treeBuilder appendChild:sgfNode toNode:parentSgfNode];
      }

      if (currentGoNode.goNodeSetup)
      {
        [self addSgfPropertiesToNode:sgfNode
                     withGoNodeSetup:currentGoNode.goNodeSetup
                           boardSize:boardSize
                  nodeIsGameInfoNode:sgfNode == gameInfoNode];

      }
      else if (currentGoNode.goMove)
      {
        [self addSgfPropertiesToNode:sgfNode
                          withGoMove:currentGoNode.goMove
                           boardSize:boardSize];
      }

      if (currentGoNode.goNodeAnnotation)
      {
        [self addSgfPropertiesToNode:sgfNode
          withGoNodeAnnotationValues:currentGoNode.goNodeAnnotation];
      }

      if (currentGoNode.goNodeMarkup)
      {
        [self addSgfPropertiesToNode:sgfNode
              withGoNodeMarkupValues:currentGoNode.goNodeMarkup
                           boardSize:boardSize];
      }

      [stack addObject:@[currentGoNode, parentSgfNode]];

      parentSgfNode = sgfNode;

      currentGoNode = currentGoNode.firstChild;
    }

    if (stack.count > 0)
    {
      NSArray* tuple = stack.lastObject;
      [stack removeLastObject];

      currentGoNode = tuple.firstObject;
      parentSgfNode = tuple.lastObject;

      currentGoNode = currentGoNode.nextSibling;
    }
    else
    {
      // We're done
      break;
    }
  }
}

#pragma mark - Create SGF document - Setup data

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// addRemainingNodesAfterNode:withValuesFromGoGame:boardSize:treeBuilder:()
// -----------------------------------------------------------------------------
- (void) addSgfPropertiesToNode:(SGFCNode*)node
                withGoNodeSetup:(GoNodeSetup*)goNodeSetup
                      boardSize:(SGFCBoardSize)boardSize
             nodeIsGameInfoNode:(bool)nodeIsGameInfoNode
{
  if (goNodeSetup.isEmpty)
    return;

  NSArray* blackSetupStones = goNodeSetup.blackSetupStones;
  NSArray* whiteSetupStones = goNodeSetup.whiteSetupStones;
  NSArray* noSetupStones = goNodeSetup.noSetupStones;

  if (blackSetupStones && blackSetupStones.count > 0)
  {
    // The order in which GoPoints are added to the array is important: If
    // handicap stones exist they must appear first. Reason: LoadGameCommand
    // expects the first <n> points of the AB property to be handicap stones
    // (<n> is the numeric value of the HA property).
    NSMutableArray* mergedHandicapStonesAndBlackSetupStones = [NSMutableArray array];

    // A GoNodeSetup that is associated with the root node has the handicap
    // stones captured in the previous board state => no need to get the data
    // from GoGame.
    // Also note: No need to subtract whiteSetupStones or noSetupStones, because
    // the app does not allow whiteSetupStones or noSetupStones to "overwrite"
    // handicap stones. Reason: Adding blackSetupStones after the subtraction
    // would cause the added blackSetupStones to be treated as handicap stones
    // when the SGF file is loaded.
    if (nodeIsGameInfoNode && goNodeSetup.previousBlackSetupStones.count > 0)
      [mergedHandicapStonesAndBlackSetupStones addObjectsFromArray:goNodeSetup.previousBlackSetupStones];

    [mergedHandicapStonesAndBlackSetupStones addObjectsFromArray:blackSetupStones];

    // If we write to the game info node and the game has handicap stones,
    // then the game info node already contains an AB property, which was added
    // in an earlier routine that deals with komi + handicap. Here we overwrite
    // the already existing AB property with new values.
    [self addSgfPropertyWithType:SGFCPropertyTypeAB
                          toNode:node
          withValuesFromGoPoints:mergedHandicapStonesAndBlackSetupStones
                       boardSize:boardSize];
  }

  if (whiteSetupStones && whiteSetupStones.count > 0)
  {
    [self addSgfPropertyWithType:SGFCPropertyTypeAW
                          toNode:node
          withValuesFromGoPoints:whiteSetupStones
                       boardSize:boardSize];
  }

  if (noSetupStones && noSetupStones.count > 0)
  {
    [self addSgfPropertyWithType:SGFCPropertyTypeAE
                          toNode:node
          withValuesFromGoPoints:noSetupStones
                       boardSize:boardSize];
  }

  enum GoColor setupFirstMoveColor = goNodeSetup.setupFirstMoveColor;
  if (setupFirstMoveColor != GoColorNone)
  {
    SGFCColor color = (setupFirstMoveColor == GoColorBlack) ? SGFCColorBlack : SGFCColorWhite;
    SGFCColorPropertyValue* plPropertyValue = [SGFCPropertyValueFactory propertyValueWithColor:color];
    SGFCProperty* plProperty = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypePL value:plPropertyValue];
    [node setProperty:plProperty];
  }
}

#pragma mark - Create SGF document - Move + move valuation data

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// addRemainingNodesAfterNode:withValuesFromGoGame:boardSize:treeBuilder:()
// -----------------------------------------------------------------------------
- (void) addSgfPropertiesToNode:(SGFCNode*)node
                     withGoMove:(GoMove*)goMove
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

  if (goMove.goMoveValuation != GoMoveValuationNone)
  {
    [self addSgfPropertyToNode:node
      withGoMoveValuationValue:goMove.goMoveValuation];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// addSgfPropertyToNode:withValueFromMove:boardSize
// -----------------------------------------------------------------------------
- (void) addSgfPropertyToNode:(SGFCNode*)node
     withGoMoveValuationValue:(enum GoMoveValuation)goMoveValuation
{
  SGFCPropertyType propertyType;
  SGFCDouble doubleValue = SGFCDoubleNormal;
  bool isDoubleValuePropertyType = true;
  switch (goMoveValuation)
  {
    case GoMoveValuationGood:
      propertyType = SGFCPropertyTypeTE;
      break;
    case GoMoveValuationVeryGood:
      propertyType = SGFCPropertyTypeTE;
      doubleValue = SGFCDoubleEmphasized;
      break;
    case GoMoveValuationBad:
      propertyType = SGFCPropertyTypeBM;
      break;
    case GoMoveValuationVeryBad:
      propertyType = SGFCPropertyTypeBM;
      doubleValue = SGFCDoubleEmphasized;
      break;
    case GoMoveValuationInteresting:
      propertyType = SGFCPropertyTypeIT;
      isDoubleValuePropertyType = false;
      break;
    case GoMoveValuationDoubtful:
      propertyType = SGFCPropertyTypeDO;
      isDoubleValuePropertyType = false;
      break;
    default:
      assert(0);
      DDLogError(@"%@: Unexpected GoMoveValuation value %d", self, (int)goMoveValuation);
      return;
  }

  SGFCProperty* property;
  if (isDoubleValuePropertyType)
  {
    SGFCDoublePropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithDouble:doubleValue];
    property = [SGFCPropertyFactory propertyWithType:propertyType
                                               value:propertyValue];
  }
  else
  {
    property = [SGFCPropertyFactory propertyWithType:propertyType];
  }
  [node setProperty:property];
}

#pragma mark - Create SGF document - Node annotation data

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// addRemainingNodesAfterNode:withValuesFromGoGame:boardSize:treeBuilder:()
// -----------------------------------------------------------------------------
- (void) addSgfPropertiesToNode:(SGFCNode*)node
     withGoNodeAnnotationValues:(GoNodeAnnotation*)goNodeAnnotation
{
  if (goNodeAnnotation.shortDescription)
  {
    SGFCPropertyType propertyType = SGFCPropertyTypeN;
    SGFCSimpleTextPropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithSimpleText:goNodeAnnotation.shortDescription];
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                             value:propertyValue];
    [node setProperty:property];
  }

  if (goNodeAnnotation.longDescription)
  {
    SGFCPropertyType propertyType = SGFCPropertyTypeC;
    SGFCTextPropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithText:goNodeAnnotation.longDescription];
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                             value:propertyValue];
    [node setProperty:property];
  }

  if (goNodeAnnotation.goBoardPositionValuation != GoBoardPositionValuationNone)
  {
    SGFCPropertyType propertyType;
    SGFCDouble doubleValue;
    switch (goNodeAnnotation.goBoardPositionValuation)
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
        DDLogError(@"%@: Unexpected GoBoardPositionValuation value %d", self, (int)goNodeAnnotation.goBoardPositionValuation);
        return;
    }
    SGFCDoublePropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithDouble:doubleValue];
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                             value:propertyValue];
    [node setProperty:property];
  }

  if (goNodeAnnotation.goBoardPositionHotspotDesignation != GoBoardPositionHotspotDesignationNone)
  {
    SGFCPropertyType propertyType = SGFCPropertyTypeHO;
    SGFCDouble doubleValue;
    if (goNodeAnnotation.goBoardPositionHotspotDesignation == GoBoardPositionHotspotDesignationYes)
      doubleValue = SGFCDoubleNormal;
    else
      doubleValue = SGFCDoubleEmphasized;
    SGFCDoublePropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithDouble:doubleValue];
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                             value:propertyValue];
    [node setProperty:property];
  }

  if (goNodeAnnotation.estimatedScoreSummary != GoScoreSummaryNone)
  {
    SGFCPropertyType propertyType = SGFCPropertyTypeV;
    SGFCReal realValue;
    switch (goNodeAnnotation.estimatedScoreSummary)
    {
      case GoScoreSummaryBlackWins:
        realValue = goNodeAnnotation.estimatedScoreValue;
        break;
      case GoScoreSummaryWhiteWins:
        realValue = -goNodeAnnotation.estimatedScoreValue;
        break;
      case GoScoreSummaryTie:
        realValue = 0.0;
        break;
      default:
        assert(0);
        DDLogError(@"%@: Unexpected GoScoreSummary value %d", self, (int)goNodeAnnotation.estimatedScoreSummary);
        return;
    }
    SGFCRealPropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithReal:realValue];
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:propertyType
                                                             value:propertyValue];
    [node setProperty:property];
  }
}

#pragma mark - Create SGF document - Markup data

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// addRemainingNodesAfterNode:withValuesFromGoGame:boardSize:treeBuilder:()
// -----------------------------------------------------------------------------
- (void) addSgfPropertiesToNode:(SGFCNode*)node
     withGoNodeMarkupValues:(GoNodeMarkup*)goNodeMarkup
                      boardSize:(SGFCBoardSize)boardSize
{
  if (goNodeMarkup.symbols)
  {
    NSMutableDictionary* sgfProperties = [NSMutableDictionary dictionary];
    sgfProperties[[NSNumber numberWithInt:GoMarkupSymbolCircle]] = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeCR];
    sgfProperties[[NSNumber numberWithInt:GoMarkupSymbolSquare]] = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeSQ];
    sgfProperties[[NSNumber numberWithInt:GoMarkupSymbolTriangle]] = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeTR];
    sgfProperties[[NSNumber numberWithInt:GoMarkupSymbolX]] = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeMA];
    sgfProperties[[NSNumber numberWithInt:GoMarkupSymbolSelected]] = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeSL];

    [goNodeMarkup.symbols enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSNumber* symbolAsNumber, BOOL* stop)
    {
      SGFCPointPropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithGoPoint:vertexString
                                                                                       boardSize:boardSize];
      SGFCProperty* property = sgfProperties[symbolAsNumber];
      [property appendPropertyValue:propertyValue];
    }];

    [sgfProperties enumerateKeysAndObjectsUsingBlock:^(NSNumber* symbolAsNumber, SGFCProperty* property, BOOL* stop)
    {
      if (property.hasPropertyValues)
        [node setProperty:property];
    }];
  }

  if (goNodeMarkup.connections)
  {
    NSMutableDictionary* sgfProperties = [NSMutableDictionary dictionary];
    sgfProperties[[NSNumber numberWithInt:GoMarkupConnectionArrow]] = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeAR];
    sgfProperties[[NSNumber numberWithInt:GoMarkupConnectionLine]] = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeLN];

    [goNodeMarkup.connections enumerateKeysAndObjectsUsingBlock:^(NSArray* vertexStrings, NSNumber* connectionAsNumber, BOOL* stop)
    {
      SGFCComposedPropertyValue* propertyValue = [SGFCPropertyValueFactory composedPropertyValueWithGoPoint:[vertexStrings firstObject]
                                                                                                    goPoint:[vertexStrings lastObject]
                                                                                                  boardSize:boardSize];
      SGFCProperty* property = sgfProperties[connectionAsNumber];
      [property appendPropertyValue:propertyValue];
    }];

    [sgfProperties enumerateKeysAndObjectsUsingBlock:^(NSNumber* connectionAsNumber, SGFCProperty* property, BOOL* stop)
    {
      if (property.hasPropertyValues)
        [node setProperty:property];
    }];
  }

  if (goNodeMarkup.labels)
  {
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeLB];
    [node setProperty:property];

    [goNodeMarkup.labels enumerateKeysAndObjectsUsingBlock:^(NSString* vertexString, NSArray* labelTypeAndText, BOOL* stop)
    {
      NSString* labelText = labelTypeAndText.lastObject;
      SGFCComposedPropertyValue* propertyValue = [SGFCPropertyValueFactory composedPropertyValueWithGoPoint:vertexString
                                                                                                  boardSize:boardSize
                                                                                                 simpleText:labelText];
      [property appendPropertyValue:propertyValue];
    }];
  }

  if (goNodeMarkup.dimmings)
  {
    SGFCProperty* property = [SGFCPropertyFactory propertyWithType:SGFCPropertyTypeDD];
    [node setProperty:property];

    for (NSString* vertexString in goNodeMarkup.dimmings)
    {
      SGFCPointPropertyValue* propertyValue = [SGFCPropertyValueFactory propertyValueWithGoPoint:vertexString
                                                                                       boardSize:boardSize];
      [property appendPropertyValue:propertyValue];
    }
  }
}

#pragma mark - Create SGF document - Helper methods

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
  [node setProperty:property];  // overwrite!
}

#pragma mark - Validate SGF document

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

#pragma mark - Save SGF document

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

#pragma mark - Helper methods

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
