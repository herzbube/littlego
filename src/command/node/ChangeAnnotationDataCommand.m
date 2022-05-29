// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "ChangeAnnotationDataCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameDocument.h"
#import "../../go/GoMove.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeAnnotation.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../utility/NSStringAdditions.h"


enum AnnotationDataChangeType
{
  AnnotationDataChangeTypeDescriptions,
  AnnotationDataChangeTypeBoardPositionValuation,
  AnnotationDataChangeTypeEstimatedScore,
  AnnotationDataChangeTypeBoardPositionHotspotDesignation,
  AnnotationDataChangeTypeMoveValuation
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// ChangeAnnotationDataCommand.
// -----------------------------------------------------------------------------
@interface ChangeAnnotationDataCommand()
@property(nonatomic, assign) enum AnnotationDataChangeType annotationDataChangeType;
@property(nonatomic, retain) GoNode* node;
@property(nonatomic, retain) NSString* shortDescription;
@property(nonatomic, retain) NSString* longDescription;
@property(nonatomic, assign) enum GoBoardPositionValuation boardPositionValuation;
@property(nonatomic, assign) enum GoScoreSummary scoreSummary;
@property(nonatomic, assign) double scoreValue;
@property(nonatomic, assign) enum GoBoardPositionHotspotDesignation hotspotDesignation;
@property(nonatomic, assign) enum GoMoveValuation moveValuation;
@end


@implementation ChangeAnnotationDataCommand

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeAnnotationDataCommand object that will change the
/// annotation data specified by @a annotationDataChangeType that is associated
/// with @a node.
///
/// @note This is the designated initializer of ChangeAnnotationDataCommand.
// -----------------------------------------------------------------------------
- (id) initWithNode:(GoNode*)node annotationDataChangeType:(enum AnnotationDataChangeType)annotationDataChangeType
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  if (! node)
  {
    NSString* errorMessage = @"initWithNode:annotationDataChangeType: failed: node is nil object";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  self.annotationDataChangeType = annotationDataChangeType;
  self.node = node;
  self.shortDescription = nil;
  self.longDescription = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeAnnotationDataCommand object that will change the
/// short and long descriptions of the GoNodeAnnotation object associated with
/// @a node.
// -----------------------------------------------------------------------------
- (id) initWithNode:(GoNode*)node shortDescription:(NSString*)shortDescription longDescription:(NSString*)longDescription
{
  self = [self initWithNode:node annotationDataChangeType:AnnotationDataChangeTypeDescriptions];

  self.shortDescription = shortDescription;
  self.longDescription = longDescription;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeAnnotationDataCommand object that will change the
/// board position valuation of the GoNodeAnnotation object associated with
/// @a node.
// -----------------------------------------------------------------------------
- (id) initWithNode:(GoNode*)node boardPositionValuation:(enum GoBoardPositionValuation)boardPositionValuation
{
  self = [self initWithNode:node annotationDataChangeType:AnnotationDataChangeTypeBoardPositionValuation];

  self.boardPositionValuation = boardPositionValuation;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeAnnotationDataCommand object that will change the
/// estimated score of the GoNodeAnnotation object associated with @a node.
// -----------------------------------------------------------------------------
- (id) initWithNode:(GoNode*)node estimatedScoreSummary:(enum GoScoreSummary)scoreSummary value:(double)scoreValue
{
  self = [self initWithNode:node annotationDataChangeType:AnnotationDataChangeTypeEstimatedScore];

  self.scoreSummary = scoreSummary;
  self.scoreValue = scoreValue;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeAnnotationDataCommand object that will change the
/// board position hotspot designation of the GoNodeAnnotation object associated
/// with @a node.
// -----------------------------------------------------------------------------
- (id) initWithNode:(GoNode*)node boardPositionHotspotDesignation:(enum GoBoardPositionHotspotDesignation)hotspotDesignation
{
  self = [self initWithNode:node annotationDataChangeType:AnnotationDataChangeTypeBoardPositionHotspotDesignation];

  self.hotspotDesignation = hotspotDesignation;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeAnnotationDataCommand object that will change the
/// move valuation of the GoMove object associated with @a node.
// -----------------------------------------------------------------------------
- (id) initWithNode:(GoNode*)node moveValuation:(enum GoMoveValuation)moveValuation
{
  self = [self initWithNode:node annotationDataChangeType:AnnotationDataChangeTypeMoveValuation];

  self.moveValuation = moveValuation;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ChangeAnnotationDataCommand
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.node = nil;
  self.shortDescription = nil;
  self.longDescription = nil;

  [super dealloc];
}

#pragma mark - CommandBase methods

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  bool dataDidChange = false;

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];

    if (self.annotationDataChangeType != AnnotationDataChangeTypeMoveValuation)
      [self createAnnotationIfNotExistsInNode:self.node];

    switch (self.annotationDataChangeType)
    {
      case AnnotationDataChangeTypeDescriptions:
        dataDidChange = [self changeDescriptions:self.node];
        break;
      case AnnotationDataChangeTypeBoardPositionValuation:
        dataDidChange = [self changeBoardPositionValuation:self.node];
        break;
      case AnnotationDataChangeTypeEstimatedScore:
        dataDidChange = [self changeEstimatedScore:self.node];
        break;
      case AnnotationDataChangeTypeBoardPositionHotspotDesignation:
        dataDidChange = [self changeHotspotDesignation:self.node];
        break;
      case AnnotationDataChangeTypeMoveValuation:
        dataDidChange = [self changeMoveValuation:self.node];
        break;
      default:
        assert(0);
        return false;
    }

    if (self.annotationDataChangeType != AnnotationDataChangeTypeMoveValuation)
      [self removeAnnotationFromNodeIfEmpty:self.node];

    if (dataDidChange)
    {
      [GoGame sharedGame].document.dirty = true;
      [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
      [[NSNotificationCenter defaultCenter] postNotificationName:nodeAnnotationDataDidChange object:self.node];
    }
  }
  @finally
  {
    if (dataDidChange)
      [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
  }

  return true;
}

#pragma mark - Change methods

// -----------------------------------------------------------------------------
/// @brief Changes the short and long descriptions of the GoNodeAnnotation
/// object associated with @a node.
// -----------------------------------------------------------------------------
- (bool) changeDescriptions:(GoNode*)node
{
  GoNodeAnnotation* nodeAnnotation = node.goNodeAnnotation;
  bool dataDidChange = false;

  if (![NSString nullableString:nodeAnnotation.shortDescription isEqualToNullableString:self.shortDescription])
  {
    nodeAnnotation.shortDescription = self.shortDescription;
    dataDidChange = true;
  }
  if (![NSString nullableString:nodeAnnotation.longDescription isEqualToNullableString:self.longDescription])
  {
    nodeAnnotation.longDescription = self.longDescription;
    dataDidChange = true;
  }

  return dataDidChange;
}

// -----------------------------------------------------------------------------
/// @brief Changes the board position valuation of the GoNodeAnnotation object
/// associated with @a node.
// -----------------------------------------------------------------------------
- (bool) changeBoardPositionValuation:(GoNode*)node
{
  GoNodeAnnotation* nodeAnnotation = node.goNodeAnnotation;
  bool dataDidChange = false;

  if (nodeAnnotation.goBoardPositionValuation != self.boardPositionValuation)
  {
    nodeAnnotation.goBoardPositionValuation = self.boardPositionValuation;
    dataDidChange = true;
  }

  return dataDidChange;
}

// -----------------------------------------------------------------------------
/// @brief Changes the estimated score of the GoNodeAnnotation object associated
/// with @a node.
// -----------------------------------------------------------------------------
- (bool) changeEstimatedScore:(GoNode*)node
{
  GoNodeAnnotation* nodeAnnotation = node.goNodeAnnotation;
  bool dataDidChange = false;

  if (nodeAnnotation.estimatedScoreSummary != self.scoreSummary ||
      nodeAnnotation.estimatedScoreValue != self.scoreValue)
  {
    [nodeAnnotation setEstimatedScoreSummary:self.scoreSummary
                                       value:self.scoreValue];
    dataDidChange = true;
  }

  return dataDidChange;
}

// -----------------------------------------------------------------------------
/// @brief Changes the board position hotspot designation of the
/// GoNodeAnnotation object associated with @a node.
// -----------------------------------------------------------------------------
- (bool) changeHotspotDesignation:(GoNode*)node
{
  GoNodeAnnotation* nodeAnnotation = node.goNodeAnnotation;
  bool dataDidChange = false;

  if (nodeAnnotation.goBoardPositionHotspotDesignation != self.hotspotDesignation)
  {
    nodeAnnotation.goBoardPositionHotspotDesignation = self.hotspotDesignation;
    dataDidChange = true;
  }

  return dataDidChange;
}

// -----------------------------------------------------------------------------
/// @brief Changes the move valuation of the GoMove object associated with
/// @a node.
// -----------------------------------------------------------------------------
- (bool) changeMoveValuation:(GoNode*)node
{
  GoMove* move = self.node.goMove;
  if (! move)
  {
    NSString* errorMessage = @"Move valuation cannot be changed if there is no move";
    DDLogError(@"%@: %@", self, errorMessage);
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:errorMessage
                                 userInfo:nil];
  }
  bool dataDidChange = false;

  if (move.goMoveValuation != self.moveValuation)
  {
    move.goMoveValuation = self.moveValuation;
    dataDidChange = true;
  }

  return dataDidChange;
}

#pragma mark - Helper methods

// -----------------------------------------------------------------------------
/// @brief Creates a new GoNodeAnnotation object if none exists in @a node, then
/// adds it to @a node.
// -----------------------------------------------------------------------------
- (void) createAnnotationIfNotExistsInNode:(GoNode*)node
{
  if (node.goNodeAnnotation)
    return;

  GoNodeAnnotation* nodeAnnotation = [[[GoNodeAnnotation alloc] init] autorelease];
  node.goNodeAnnotation = nodeAnnotation;
}

// -----------------------------------------------------------------------------
/// @brief Removes the GoNodeAnnotation object from @a node if it exists but
/// it is empty, i.e. all of its properties have default values.
// -----------------------------------------------------------------------------
- (void) removeAnnotationFromNodeIfEmpty:(GoNode*)node
{
  GoNodeAnnotation* nodeAnnotation = node.goNodeAnnotation;

  if (nodeAnnotation &&
      nodeAnnotation.shortDescription == nil &&
      nodeAnnotation.longDescription == nil &&
      nodeAnnotation.goBoardPositionValuation == GoBoardPositionValuationNone &&
      nodeAnnotation.goBoardPositionHotspotDesignation == GoBoardPositionHotspotDesignationNone &&
      nodeAnnotation.estimatedScoreSummary == GoScoreSummaryNone)
  {
    node.goNodeAnnotation = nil;
  }
}

@end
