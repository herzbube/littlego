// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "MoveMarkupPanGestureHandler.h"
#import "../../boardview/BoardView.h"
#import "../../gameaction/GameActionManager.h"
#import "../../model/BoardViewMetrics.h"
#import "../../model/MarkupModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoBoardPosition.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoNode.h"
#import "../../../go/GoNodeMarkup.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoUtilities.h"
#import "../../../go/GoVertex.h"
#import "../../../utility/MarkupUtilities.h"


NS_ASSUME_NONNULL_BEGIN

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// MoveMarkupPanGestureHandler.
// -----------------------------------------------------------------------------
@interface MoveMarkupPanGestureHandler()
@property(nonatomic, assign) BoardView* boardView;
@property(nonatomic, assign) BoardViewMetrics* boardViewMetrics;
@property(nonatomic, assign) MarkupModel* markupModel;
/// @brief The type of markup that is being moved.
@property(nonatomic, assign) enum MarkupType markupTypeToMove;
/// @brief The category of markup that is being moved.
@property(nonatomic, assign) enum MarkupTool markupCategoryToMove;
/// @brief The start point of the connection that is being moved. Is set for
/// #MarkupTypeConnectionArrow and #MarkupTypeConnectionLine.
@property(nonatomic, retain, nullable) GoPoint* connectionToMoveStartPoint;
/// @brief The end point of the connection that is being moved. Is set for
/// #MarkupTypeConnectionArrow and #MarkupTypeConnectionLine.
@property(nonatomic, retain, nullable) GoPoint* connectionToMoveEndPoint;
/// @brief Is true if the start point of the connection that is being moved is
/// moved, false if the end point is moved. Is set for
/// #MarkupTypeConnectionArrow and #MarkupTypeConnectionLine.
@property(nonatomic, assign) bool connectionToMoveStartPointIsMoved;
/// @brief The label text that is being moved. Is set for
/// #MarkupTypeMarkerNumber, #MarkupTypeMarkerLetter and #MarkupTypeLabel.
@property(nonatomic, retain, nullable) NSString* labelTextToMove;
@end


@implementation MoveMarkupPanGestureHandler

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a MoveMarkupPanGestureHandler object.
///
/// @note This is the designated initializer of MoveMarkupPanGestureHandler.
// -----------------------------------------------------------------------------
- (id) initWithBoardView:(BoardView*)boardView markupModel:(MarkupModel*)markupModel boardViewMetrics:(BoardViewMetrics*)boardViewMetrics
{
  // Call designated initializer of superclass (PanGestureHandler)
  self = [super init];
  if (! self)
    return nil;

  self.boardView = boardView;
  self.markupModel = markupModel;
  self.boardViewMetrics = boardViewMetrics;

  self.markupTypeToMove = MarkupTypeSymbolCircle;  // dummy value
  self.markupCategoryToMove = MarkupToolSymbol;    // dummy value
  self.connectionToMoveStartPoint = nil;
  self.connectionToMoveEndPoint = nil;
  self.connectionToMoveStartPointIsMoved = true;
  self.labelTextToMove = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this MoveMarkupPanGestureHandler
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.connectionToMoveStartPoint = nil;
  self.connectionToMoveEndPoint = nil;
  self.labelTextToMove = nil;

  [super dealloc];
}

#pragma mark - PanGestureHandler overrides

// -----------------------------------------------------------------------------
/// @brief PanGestureHandler method.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
                    gestureStartPoint:(GoPoint*)gestureStartPoint
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  GoNode* currentNode = boardPosition.currentNode;
  bool ignoreLabels = ! [self areLabelsVisible];
  bool markupExists = [MarkupUtilities markupExistsOnPoint:gestureStartPoint
                                                   forNode:currentNode
                                              ignoreLabels:ignoreLabels];
  return markupExists ? YES : NO;
}

// -----------------------------------------------------------------------------
/// @brief PanGestureHandler method.
// -----------------------------------------------------------------------------
- (void) handleGestureWithGestureRecognizerState:(UIGestureRecognizerState)recognizerState
                               gestureStartPoint:(GoPoint*)gestureStartPoint
                             gestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  switch (recognizerState)
  {
    case UIGestureRecognizerStateBegan:
    {
      [self handleGestureBeganWithGestureStartPoint:gestureStartPoint gestureCurrentPoint:gestureCurrentPoint];
      break;
    }
    case UIGestureRecognizerStateChanged:
    {
      [self handleGestureChangedWithGestureStartPoint:gestureStartPoint gestureCurrentPoint:gestureCurrentPoint];
      break;
    }
    // UIGestureRecognizerStateEnded
    // UIGestureRecognizerStateCancelled
    default:
    {
      [self handleGestureEndedWithGestureRecognizerState:recognizerState gestureStartPoint:gestureStartPoint gestureCurrentPoint:gestureCurrentPoint];
      break;
    }
  }
}

#pragma mark - Gesture handling - UIGestureRecognizerStateBegan

// -----------------------------------------------------------------------------
/// @brief Handler for UIGestureRecognizerStateBegan.
// -----------------------------------------------------------------------------
- (void) handleGestureBeganWithGestureStartPoint:(GoPoint*)gestureStartPoint
                             gestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  [self findMarkupToMoveOnGestureStartPoint:gestureStartPoint];

  // An optimization idea that was not implemented was to do the temporary
  // removal only when the gesture moves away from the gesture start point.
  // The idea was abandoned when it turned out that the drawing logic in
  // SymbolsLayerDelegate would become more complicated.
  [self temporarilyRemoveOriginalMarkupToMoveAtGestureStartPoint:gestureStartPoint];

  switch (self.markupCategoryToMove)
  {
    case MarkupToolSymbol:
    {
      [self notifyBoardViewSymbolDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      [self notifyStatusViewSymbolDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      break;
    }
    case MarkupToolConnection:
    {
      [self notifyBoardViewConnectionDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      [self notifyStatusViewConnectionDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      break;
    }
    case MarkupToolMarker:
    case MarkupToolLabel:
    {
      [self notifyBoardViewLabelDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      [self notifyStatusViewLabelDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      break;
    }
    default:
    {
      assert(0);
      return;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// handleGestureBeganWithGestureStartPoint:gestureCurrentPoint:().
// -----------------------------------------------------------------------------
- (void) findMarkupToMoveOnGestureStartPoint:(GoPoint*)gestureStartPoint
{
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  GoNode* currentNode = boardPosition.currentNode;
  bool ignoreLabels = ! [self areLabelsVisible];
  enum MarkupType markupTypeToMove;
  id markupInfo;
  bool markupExists = [MarkupUtilities markupExistsOnPoint:gestureStartPoint
                                                   forNode:currentNode
                                              ignoreLabels:ignoreLabels
                                           firstMarkupType:&markupTypeToMove
                                           firstMarkupInfo:&markupInfo];
  if (! markupExists)
  {
    assert(0);
    DDLogError(@"%@: UIGestureRecognizerStateBegan failed, did not find any markup to move", self.shortDescription);
    return;
  }

  self.markupTypeToMove = markupTypeToMove;
  self.markupCategoryToMove = [MarkupUtilities markupToolForMarkupType:markupTypeToMove];

  switch (self.markupCategoryToMove)
  {
    case MarkupToolConnection:
    {
      NSArray* startEndIntersectionsOfConnection = markupInfo;
      GoBoard* board = game.board;
      self.connectionToMoveStartPoint = [board pointAtVertex:startEndIntersectionsOfConnection.firstObject];
      self.connectionToMoveEndPoint = [board pointAtVertex:startEndIntersectionsOfConnection.lastObject];
      self.connectionToMoveStartPointIsMoved = (self.connectionToMoveStartPoint == gestureStartPoint);
      break;
    }
    case MarkupToolMarker:
    case MarkupToolLabel:
    {
      self.labelTextToMove = markupInfo;
      break;
    }
    default:
    {
      return;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for
/// handleGestureBeganWithGestureStartPoint:gestureCurrentPoint:().
// -----------------------------------------------------------------------------
- (void) temporarilyRemoveOriginalMarkupToMoveAtGestureStartPoint:(GoPoint*)gestureStartPoint
{
  GoNode* node = [self currentNode];
  GoNodeMarkup* nodeMarkup = [self currentNodeMarkup];

  switch (self.markupCategoryToMove)
  {
    case MarkupToolSymbol:
    {
      [self temporarilyRemoveOriginalSymbolToMoveAtGestureStartPoint:gestureStartPoint nodeMarkup:nodeMarkup node:node];
      break;
    }
    case MarkupToolConnection:
    {
      [self temporarilyRemoveOriginalConnectionToMove:nodeMarkup node:node];
      break;
    }
    case MarkupToolMarker:
    case MarkupToolLabel:
    {
      [self temporarilyRemoveOriginalLabelToMoveAtGestureStartPoint:gestureStartPoint nodeMarkup:nodeMarkup node:node];
      break;
    }
    default:
    {
      assert(0);
      return;
    }
  }
}

#pragma mark - Gesture handling - UIGestureRecognizerStateChanged

// -----------------------------------------------------------------------------
/// @brief Handler for UIGestureRecognizerStateChanged.
// -----------------------------------------------------------------------------
- (void) handleGestureChangedWithGestureStartPoint:(GoPoint*)gestureStartPoint
                               gestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  switch (self.markupCategoryToMove)
  {
    case MarkupToolSymbol:
    {
      [self notifyBoardViewSymbolDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      [self notifyStatusViewSymbolDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      break;
    }
    case MarkupToolConnection:
    {
      [self notifyBoardViewConnectionDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      [self notifyStatusViewConnectionDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      break;
    }
    case MarkupToolMarker:
    case MarkupToolLabel:
    {
      [self notifyBoardViewLabelDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      [self notifyStatusViewLabelDidChangeWithGestureCurrentPoint:gestureCurrentPoint];
      break;
    }
    default:
    {
      assert(0);
      return;
    }
  }
}

#pragma mark - Gesture handling - UIGestureRecognizerStateEnded and UIGestureRecognizerStateCancelled

// -----------------------------------------------------------------------------
/// @brief Handler for UIGestureRecognizerStateEnded and
/// UIGestureRecognizerStateCancelled.
// -----------------------------------------------------------------------------
- (void) handleGestureEndedWithGestureRecognizerState:(UIGestureRecognizerState)recognizerState
                                    gestureStartPoint:(GoPoint*)gestureStartPoint
                                  gestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  switch (self.markupCategoryToMove)
  {
    case MarkupToolSymbol:
    {
      [self notifyBoardViewSymbolDidChangeWithGestureCurrentPoint:nil];
      [self notifyStatusViewSymbolDidChangeWithGestureCurrentPoint:nil];
      [self placeOrRestoreSymbolWithGestureRecognizerState:recognizerState
                                         gestureStartPoint:gestureStartPoint
                                       gestureCurrentPoint:gestureCurrentPoint];
      break;
    }
    case MarkupToolConnection:
    {
      [self notifyBoardViewConnectionDidChangeWithGestureCurrentPoint:nil];
      [self notifyStatusViewConnectionDidChangeWithGestureCurrentPoint:nil];
      [self placeOrRestoreConnectionWithGestureRecognizerState:recognizerState
                                             gestureStartPoint:gestureStartPoint
                                           gestureCurrentPoint:gestureCurrentPoint];
      self.connectionToMoveStartPoint = nil;
      self.connectionToMoveEndPoint = nil;
      break;
    }
    case MarkupToolMarker:
    case MarkupToolLabel:
    {
      [self notifyBoardViewLabelDidChangeWithGestureCurrentPoint:nil];
      [self notifyStatusViewLabelDidChangeWithGestureCurrentPoint:nil];
      [self placeOrRestoreLabelWithGestureRecognizerState:recognizerState
                                        gestureStartPoint:gestureStartPoint
                                      gestureCurrentPoint:gestureCurrentPoint];

      self.labelTextToMove = nil;
      break;
    }
    default:
    {
      assert(0);
      return;
    }
  }
}

#pragma mark - Helpers for handling symbols

// -----------------------------------------------------------------------------
/// @brief Notifies the board view that it should update the temporarily drawn
/// symbol. If @a gestureCurrentPoint is @e nil, the board view does not
/// draw a symbol.
// -----------------------------------------------------------------------------
- (void) notifyBoardViewSymbolDidChangeWithGestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  enum GoMarkupSymbol symbol = [MarkupUtilities symbolForMarkupType:self.markupTypeToMove];

  [self.boardView moveCrossHairWithSymbol:symbol
                                  toPoint:gestureCurrentPoint];
}

// -----------------------------------------------------------------------------
/// @brief Notifies the status view to display updated information about the
/// temporarily drawn symbol. If @a gestureCurrentPoint is @e nil, the status
/// view does not display any information.
// -----------------------------------------------------------------------------
- (void) notifyStatusViewSymbolDidChangeWithGestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  NSArray* symbolInformation = gestureCurrentPoint ? @[[NSNumber numberWithInt:self.markupTypeToMove], gestureCurrentPoint] : @[];
  [[NSNotificationCenter defaultCenter] postNotificationName:boardViewMarkupLocationDidChange
                                                      object:symbolInformation];
}

// -----------------------------------------------------------------------------
/// @brief Temporarily remove the symbol being moved from @a nodeMarkup.
/// The symbol is either replaced later on with a new symbol (if the
/// gesture completes) or restored (if the gesture is canceled).
// -----------------------------------------------------------------------------
- (void) temporarilyRemoveOriginalSymbolToMoveAtGestureStartPoint:(GoPoint*)gestureStartPoint
                                                       nodeMarkup:(GoNodeMarkup*)nodeMarkup
                                                             node:(GoNode*)node
{
  NSString* intersection = gestureStartPoint.vertex.string;
  [nodeMarkup removeSymbolAtVertex:intersection];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];

  NSArray* pointsWithChangedMarkup = @[gestureStartPoint];
  [center postNotificationName:markupOnPointsDidChange object:pointsWithChangedMarkup];
  [center postNotificationName:nodeMarkupDataDidChange object:node];
}

// -----------------------------------------------------------------------------
/// @brief Either places a new symbol (if the gesture completes) or restores
/// the original symbol that was temporarily removed (if the gesture is
/// canceled).
// -----------------------------------------------------------------------------
- (void) placeOrRestoreSymbolWithGestureRecognizerState:(UIGestureRecognizerState)recognizerState
                                      gestureStartPoint:(GoPoint*)gestureStartPoint
                                    gestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  enum GoMarkupSymbol symbol = [MarkupUtilities symbolForMarkupType:self.markupTypeToMove];

  if (recognizerState == UIGestureRecognizerStateEnded && gestureStartPoint && gestureCurrentPoint && gestureStartPoint != gestureCurrentPoint)
  {
    [[GameActionManager sharedGameActionManager] handleMarkupEditingPlaceMovedSymbol:symbol
                                                                             atPoint:gestureCurrentPoint];
  }
  else
  {
    GoNodeMarkup* nodeMarkup = [self currentNodeMarkup];
    [nodeMarkup setSymbol:symbol
                 atVertex:gestureStartPoint.vertex.string];

    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];

    NSArray* pointsWithChangedMarkup = @[gestureStartPoint];
    [center postNotificationName:markupOnPointsDidChange object:pointsWithChangedMarkup];

    GoNode* node = [self currentNode];
    [center postNotificationName:nodeMarkupDataDidChange object:node];
  }
}

#pragma mark - Helpers for handling connections

// -----------------------------------------------------------------------------
/// @brief Notifies the board view that it should update the temporarily drawn
/// connection. If @a gestureCurrentPoint is @e nil, the board view does not
/// draw a connection.
// -----------------------------------------------------------------------------
- (void) notifyBoardViewConnectionDidChangeWithGestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  enum GoMarkupConnection connection = [MarkupUtilities connectionForMarkupType:self.markupTypeToMove];

  GoPoint* temporaryConnectionStartPoint;
  GoPoint* temporaryConnectionEndPoint;
  if (gestureCurrentPoint)
  {
    [self temporaryConnectionWithGestureCurrentPoint:gestureCurrentPoint startPoint:&temporaryConnectionStartPoint endPoint:&temporaryConnectionEndPoint];
  }
  else
  {
    temporaryConnectionStartPoint = nil;
    temporaryConnectionEndPoint = nil;
  }

  [self.boardView moveMarkupConnection:connection
                        withStartPoint:temporaryConnectionStartPoint
                            toEndPoint:temporaryConnectionEndPoint];
}

// -----------------------------------------------------------------------------
/// @brief Notifies the status view to display updated information about the
/// temporarily drawn connection. If @a gestureCurrentPoint is @e nil, the
/// status view does not display any information.
// -----------------------------------------------------------------------------
- (void) notifyStatusViewConnectionDidChangeWithGestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  NSArray* connectionInformation;
  if (gestureCurrentPoint)
  {
    GoPoint* temporaryConnectionStartPoint;
    GoPoint* temporaryConnectionEndPoint;
    [self temporaryConnectionWithGestureCurrentPoint:gestureCurrentPoint startPoint:&temporaryConnectionStartPoint endPoint:&temporaryConnectionEndPoint];

    connectionInformation = (temporaryConnectionStartPoint && temporaryConnectionEndPoint)
      ? @[[NSNumber numberWithInt:self.markupTypeToMove], temporaryConnectionStartPoint, temporaryConnectionEndPoint]
      : @[];
  }
  else
  {
    connectionInformation = @[];
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:boardViewMarkupLocationDidChange
                                                      object:connectionInformation];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) temporaryConnectionWithGestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
                                         startPoint:(GoPoint**)temporaryConnectionStartPoint
                                           endPoint:(GoPoint**)temporaryConnectionEndPoint
{
  *temporaryConnectionStartPoint = self.connectionToMoveStartPointIsMoved ? gestureCurrentPoint : self.connectionToMoveStartPoint;
  *temporaryConnectionEndPoint = self.connectionToMoveStartPointIsMoved ? self.connectionToMoveEndPoint : gestureCurrentPoint;
}

// -----------------------------------------------------------------------------
/// @brief Temporarily remove the connection being moved from @a nodeMarkup.
/// The connection is either replaced later on with a new connection (if the
/// gesture completes) or restored (if the gesture is canceled).
// -----------------------------------------------------------------------------
- (void) temporarilyRemoveOriginalConnectionToMove:(GoNodeMarkup*)nodeMarkup
                                              node:(GoNode*)node
{
  [nodeMarkup removeConnectionFromVertex:self.connectionToMoveStartPoint.vertex.string
                                toVertex:self.connectionToMoveEndPoint.vertex.string];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];

  NSArray* pointsInConnectionRectangle = [GoUtilities pointsInRectangleDelimitedByCornerPoint:self.connectionToMoveStartPoint
                                                                          oppositeCornerPoint:self.connectionToMoveEndPoint
                                                                                       inGame:[GoGame sharedGame]];
  NSArray* pointsWithChangedMarkup = @[self.connectionToMoveStartPoint, self.connectionToMoveEndPoint, pointsInConnectionRectangle];
  [center postNotificationName:markupOnPointsDidChange object:pointsWithChangedMarkup];

  [center postNotificationName:nodeMarkupDataDidChange object:node];
}

// -----------------------------------------------------------------------------
/// @brief Either places a new connection (if the gesture completes) or restores
/// the original connection that was temporarily removed (if the gesture is
/// canceled).
// -----------------------------------------------------------------------------
- (void) placeOrRestoreConnectionWithGestureRecognizerState:(UIGestureRecognizerState)recognizerState
                                          gestureStartPoint:(GoPoint*)gestureStartPoint
                                        gestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  bool restoreOriginalConnection = true;
  if (recognizerState == UIGestureRecognizerStateEnded && gestureStartPoint && gestureCurrentPoint && gestureStartPoint != gestureCurrentPoint)
  {
    GoPoint* finalConnectionStartPoint = self.connectionToMoveStartPointIsMoved ? gestureCurrentPoint : self.connectionToMoveStartPoint;
    GoPoint* finalConnectionEndPoint = self.connectionToMoveStartPointIsMoved ? self.connectionToMoveEndPoint : gestureCurrentPoint;

    // Only place the connection if user did not shorten it to a single point
    if (finalConnectionStartPoint != finalConnectionEndPoint)
    {
      restoreOriginalConnection = false;
      enum GoMarkupConnection connection = [MarkupUtilities connectionForMarkupType:self.markupTypeToMove];
      [[GameActionManager sharedGameActionManager] handleMarkupEditingPlaceNewOrMovedConnection:connection
                                                                                      fromPoint:finalConnectionStartPoint
                                                                                        toPoint:finalConnectionEndPoint
                                                                             connectionWasMoved:true];
    }
  }

  if (restoreOriginalConnection)
  {
    enum GoMarkupConnection connection = [MarkupUtilities connectionForMarkupType:self.markupTypeToMove];

    GoNodeMarkup* nodeMarkup = [self currentNodeMarkup];
    [nodeMarkup setConnection:connection
                   fromVertex:self.connectionToMoveStartPoint.vertex.string
                     toVertex:self.connectionToMoveEndPoint.vertex.string];

    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];

    NSArray* pointsInConnectionRectangle = [GoUtilities pointsInRectangleDelimitedByCornerPoint:self.connectionToMoveStartPoint
                                                                            oppositeCornerPoint:self.connectionToMoveEndPoint
                                                                                         inGame:[GoGame sharedGame]];
    NSArray* pointsWithChangedMarkup = @[self.connectionToMoveStartPoint, self.connectionToMoveEndPoint, pointsInConnectionRectangle];
    [center postNotificationName:markupOnPointsDidChange object:pointsWithChangedMarkup];

    GoNode* node = [self currentNode];
    [center postNotificationName:nodeMarkupDataDidChange object:node];
  }
}

#pragma mark - Helpers for handling labels

// -----------------------------------------------------------------------------
/// @brief Notifies the board view that it should update the temporarily drawn
/// label. If @a gestureCurrentPoint is @e nil, the board view does not
/// draw a label.
// -----------------------------------------------------------------------------
- (void) notifyBoardViewLabelDidChangeWithGestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  enum GoMarkupLabel label = [MarkupUtilities labelForMarkupType:self.markupTypeToMove];

  [self.boardView moveCrossHairWithLabel:label
                               labelText:self.labelTextToMove
                                 toPoint:gestureCurrentPoint];
}

// -----------------------------------------------------------------------------
/// @brief Notifies the status view to display updated information about the
/// temporarily drawn label. If @a gestureCurrentPoint is @e nil, the status
/// view does not display any information.
// -----------------------------------------------------------------------------
- (void) notifyStatusViewLabelDidChangeWithGestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  NSArray* labelInformation = gestureCurrentPoint ? @[[NSNumber numberWithInt:self.markupTypeToMove], gestureCurrentPoint] : @[];
  [[NSNotificationCenter defaultCenter] postNotificationName:boardViewMarkupLocationDidChange
                                                      object:labelInformation];
}

// -----------------------------------------------------------------------------
/// @brief Temporarily remove the label being moved from @a nodeMarkup.
/// The label is either replaced later on with a new label (if the
/// gesture completes) or restored (if the gesture is canceled).
// -----------------------------------------------------------------------------
- (void) temporarilyRemoveOriginalLabelToMoveAtGestureStartPoint:(GoPoint*)gestureStartPoint
                                                      nodeMarkup:(GoNodeMarkup*)nodeMarkup
                                                            node:(GoNode*)node
{
  NSString* intersection = gestureStartPoint.vertex.string;
  [nodeMarkup removeLabelAtVertex:intersection];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];

  enum GoMarkupLabel label = [MarkupUtilities labelForMarkupType:self.markupTypeToMove];
  NSArray* pointsWithChangedMarkup = @[gestureStartPoint, [NSNumber numberWithInt:label]];
  [center postNotificationName:markupOnPointsDidChange object:pointsWithChangedMarkup];

  [center postNotificationName:nodeMarkupDataDidChange object:node];
}

// -----------------------------------------------------------------------------
/// @brief Either places a new label (if the gesture completes) or restores
/// the original label that was temporarily removed (if the gesture is
/// canceled).
// -----------------------------------------------------------------------------
- (void) placeOrRestoreLabelWithGestureRecognizerState:(UIGestureRecognizerState)recognizerState
                                     gestureStartPoint:(GoPoint*)gestureStartPoint
                                   gestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  enum GoMarkupLabel label = [MarkupUtilities labelForMarkupType:self.markupTypeToMove];

  if (recognizerState == UIGestureRecognizerStateEnded && gestureStartPoint && gestureCurrentPoint && gestureStartPoint != gestureCurrentPoint)
  {
    [[GameActionManager sharedGameActionManager] handleMarkupEditingPlaceMovedLabel:label
                                                                      withLabelText:self.labelTextToMove
                                                                            atPoint:gestureCurrentPoint];
  }
  else
  {
    GoNodeMarkup* nodeMarkup = [self currentNodeMarkup];
    [nodeMarkup setLabel:label
               labelText:self.labelTextToMove
                atVertex:gestureStartPoint.vertex.string];

    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];

    NSArray* pointsWithChangedMarkup = @[gestureStartPoint, [NSNumber numberWithInt:label]];
    [center postNotificationName:markupOnPointsDidChange object:pointsWithChangedMarkup];

    GoNode* node = [self currentNode];
    [center postNotificationName:nodeMarkupDataDidChange object:node];
  }
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the GoNode object that corresponds to the current board
/// position.
// -----------------------------------------------------------------------------
- (GoNode*) currentNode
{
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  return boardPosition.currentNode;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoNodeMarkup object associated with the node of the
/// current board position.
// -----------------------------------------------------------------------------
- (GoNodeMarkup*) currentNodeMarkup
{
  GoNode* currentNode = [self currentNode];
  GoNodeMarkup* nodeMarkup = currentNode.goNodeMarkup;
  return nodeMarkup;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if labels of type #GoMarkupLabelLabel are currently
/// visible in the UI. Otherwise returns false.
// -----------------------------------------------------------------------------
- (bool) areLabelsVisible
{
  return (self.boardViewMetrics.markupLabelFont != nil);
}

@end

NS_ASSUME_NONNULL_END
