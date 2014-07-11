// -----------------------------------------------------------------------------
// Copyright 2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardTileView.h"
#import "layer/CoordinatesLayerDelegate.h"
#import "layer/CrossHairLinesLayerDelegate.h"
#import "layer/GridLayerDelegate.h"
#import "layer/InfluenceLayerDelegate.h"
#import "layer/StonesLayerDelegate.h"
#import "layer/SymbolsLayerDelegate.h"
#import "layer/TerritoryLayerDelegate.h"
#import "../model/BoardViewMetrics.h"
#import "../model/BoardViewModel.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardTileView.
// -----------------------------------------------------------------------------
@interface BoardTileView()
/// @brief Prevents double-unregistering of notification responders by
/// willMoveToSuperview: followed by dealloc, or double-registering by two
/// consecutive invocations of willMoveToSuperview: where the argument is not
/// nil.
///
/// With the current tiling implementation these precautions are probably
/// unnecessary because the two scenarios should never occur. The keyword is
/// "should" - we are not entirely sure how things might behave in production,
/// so we are playing it safe. Also, we guard against future implementation
/// changes.
@property(nonatomic, assign) bool notificationRespondersAreSetup;
@property(nonatomic, assign) bool drawLayersWasDelayed;
@property(nonatomic, retain) NSArray* layerDelegates;
@property(nonatomic, assign) GridLayerDelegate* gridLayerDelegate;
@property(nonatomic, assign) CrossHairLinesLayerDelegate* crossHairLinesLayerDelegate;
@property(nonatomic, assign) StonesLayerDelegate* stonesLayerDelegate;
@property(nonatomic, assign) InfluenceLayerDelegate* influenceLayerDelegate;
@property(nonatomic, assign) SymbolsLayerDelegate* symbolsLayerDelegate;
@property(nonatomic, assign) TerritoryLayerDelegate* territoryLayerDelegate;
//@}
@end


@implementation BoardTileView

#pragma mark - Synthesize properties

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// Tile protocol.
@synthesize row = _row;
@synthesize column = _column;

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardTileView object with frame rectangle @a rect.
///
/// @note This is the designated initializer of BoardTileView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;
  self.row = -1;
  self.column = -1;
  self.notificationRespondersAreSetup = false;
  self.drawLayersWasDelayed = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardTileView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  for (id<BoardViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate.layer removeFromSuperlayer];
  self.layerDelegates = nil;
  self.gridLayerDelegate = nil;
  self.crossHairLinesLayerDelegate = nil;
  self.stonesLayerDelegate = nil;
  self.influenceLayerDelegate = nil;
  self.symbolsLayerDelegate = nil;
  self.territoryLayerDelegate = nil;
  [super dealloc];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  if (self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = true;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  BoardViewMetrics* metrics = appDelegate.boardViewMetrics;
  BoardViewModel* boardViewModel = appDelegate.boardViewModel;
  BoardPositionModel* boardPositionModel = appDelegate.boardPositionModel;
  ScoringModel* scoringModel = appDelegate.scoringModel;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goScoreScoringEnabled:) name:goScoreScoringEnabled object:nil];
  [center addObserver:self selector:@selector(goScoreScoringDisabled:) name:goScoreScoringDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(territoryStatisticsChanged:) name:territoryStatisticsChanged object:nil];
  [center addObserver:self selector:@selector(boardViewWillDisplayCrossHair:) name:boardViewWillDisplayCrossHair object:nil];
  [center addObserver:self selector:@selector(boardViewWillHideCrossHair:) name:boardViewWillHideCrossHair object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  [boardPositionModel addObserver:self forKeyPath:@"markNextMove" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"canvasSize" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"boardSize" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"displayCoordinates" options:0 context:NULL];
  [boardViewModel addObserver:self forKeyPath:@"displayPlayerInfluence" options:0 context:NULL];
  [boardViewModel addObserver:self forKeyPath:@"markLastMove" options:0 context:NULL];
  [boardViewModel addObserver:self forKeyPath:@"moveNumbersPercentage" options:0 context:NULL];
  [scoringModel addObserver:self forKeyPath:@"inconsistentTerritoryMarkupType" options:0 context:NULL];
  GoGame* game = [GoGame sharedGame];
  if (game)
  {
    GoBoardPosition* boardPosition = game.boardPosition;
    [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
    [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for dealloc.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  if (! self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = false;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  BoardViewMetrics* metrics = appDelegate.boardViewMetrics;
  BoardViewModel* boardViewModel = appDelegate.boardViewModel;
  BoardPositionModel* boardPositionModel = appDelegate.boardPositionModel;
  ScoringModel* scoringModel = appDelegate.scoringModel;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center removeObserver:self];
  [boardPositionModel removeObserver:self forKeyPath:@"markNextMove"];
  [metrics removeObserver:self forKeyPath:@"canvasSize"];
  [metrics removeObserver:self forKeyPath:@"boardSize"];
  [metrics removeObserver:self forKeyPath:@"displayCoordinates"];
  [boardViewModel removeObserver:self forKeyPath:@"displayPlayerInfluence"];
  [boardViewModel removeObserver:self forKeyPath:@"markLastMove"];
  [boardViewModel removeObserver:self forKeyPath:@"moveNumbersPercentage"];
  [scoringModel removeObserver:self forKeyPath:@"inconsistentTerritoryMarkupType"];
  GoGame* game = [GoGame sharedGame];
  if (game)
  {
    GoBoardPosition* boardPosition = game.boardPosition;
    [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
    [boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
  }
}

#pragma mark - Manage layers and layer delegates

// -----------------------------------------------------------------------------
/// @brief Sets up this BoardTileView with layers that match the current
/// application state.
///
/// The process consists of these actions:
/// - Layers that are required but do not exist are created
/// - Layers that are not required but that exist are deallocated
/// - Layers that are required and that already exist are kept as-is
///
/// Due to the last point, a caller may need to invalidate all layers' contents
/// by invoking invalidateContent().
///
/// @note If this method is invoked two times in a row without any application
/// state changes in between, the second invocation does not have any effect.
// -----------------------------------------------------------------------------
- (void) setupLayerDelegates
{
  [self setupGridLayerDelegate];
  [self setupStonesLayerDelegate];
  [self setupCrossHairLinesLayerDelegateIsRequired:false];
  [self setupInfluenceLayerDelegate];
  [self setupSymbolsLayerDelegate];
  [self setupTerritoryLayerDelegate];

  [self updateLayers];
}

// -----------------------------------------------------------------------------
/// @brief Creates the grid layer delegate, or resets it to nil, depending
/// on the current application state.
// -----------------------------------------------------------------------------
- (void) setupGridLayerDelegate
{
  if (self.gridLayerDelegate)
    return;
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  self.gridLayerDelegate = [[[GridLayerDelegate alloc] initWithTile:self
                                                            metrics:metrics] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Creates the stones layer delegate, or resets it to nil, depending
/// on the current application state.
// -----------------------------------------------------------------------------
- (void) setupStonesLayerDelegate
{
  if (self.stonesLayerDelegate)
    return;
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  self.stonesLayerDelegate = [[[StonesLayerDelegate alloc] initWithTile:self
                                                                metrics:metrics] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Creates the cross-hair lines layer delegate, or resets it to nil,
/// depending on the value of @a layerIsRequired.
///
/// Unlike the other layer setup methods, with this method the caller must
/// provide the information whether or not the layer is required. The reason
/// is that there is no application state holding object that provides the
/// information.
// -----------------------------------------------------------------------------
- (void) setupCrossHairLinesLayerDelegateIsRequired:(bool)layerIsRequired
{
  if (layerIsRequired)
  {
    ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
    if (! self.crossHairLinesLayerDelegate)
    {
      self.crossHairLinesLayerDelegate = [[[CrossHairLinesLayerDelegate alloc] initWithTile:self
                                                                                    metrics:appDelegate.boardViewMetrics] autorelease];
    }
  }
  else
  {
    self.crossHairLinesLayerDelegate = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates the influence layer delegate, or resets it to nil, depending
/// on the current application state.
// -----------------------------------------------------------------------------
- (void) setupInfluenceLayerDelegate
{
  if ([GoGame sharedGame].score.scoringEnabled)
  {
    self.influenceLayerDelegate = nil;
  }
  else
  {
    ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
    BoardViewModel* boardViewModel = appDelegate.boardViewModel;
    if (boardViewModel.displayPlayerInfluence)
    {
      if (self.influenceLayerDelegate)
        return;
      self.influenceLayerDelegate = [[[InfluenceLayerDelegate alloc] initWithTile:self
                                                                          metrics:appDelegate.boardViewMetrics
                                                                   boardViewModel:boardViewModel] autorelease];
    }
    else
    {
      self.influenceLayerDelegate = nil;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates the symbols layer delegate, or resets it to nil, depending
/// on the current application state.
// -----------------------------------------------------------------------------
- (void) setupSymbolsLayerDelegate
{
  if ([GoGame sharedGame].score.scoringEnabled)
  {
    self.symbolsLayerDelegate = nil;
  }
  else
  {
    if (self.symbolsLayerDelegate)
      return;
    ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
    self.symbolsLayerDelegate = [[[SymbolsLayerDelegate alloc] initWithTile:self
                                                                    metrics:appDelegate.boardViewMetrics
                                                             boardViewModel:appDelegate.boardViewModel
                                                         boardPositionModel:appDelegate.boardPositionModel] autorelease];

  }
}

// -----------------------------------------------------------------------------
/// @brief Creates the territory layer delegate, or resets it to nil, depending
/// on the current application state.
// -----------------------------------------------------------------------------
- (void) setupTerritoryLayerDelegate
{
  if ([GoGame sharedGame].score.scoringEnabled)
  {
    if (self.territoryLayerDelegate)
      return;
    ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
    self.territoryLayerDelegate = [[[TerritoryLayerDelegate alloc] initWithTile:self
                                                                        metrics:appDelegate.boardViewMetrics
                                                                   scoringModel:appDelegate.scoringModel] autorelease];
  }
  else
  {
    self.territoryLayerDelegate = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the layers of this BoardTileView based on the layer delegates
/// that currently exist.
// -----------------------------------------------------------------------------
- (void) updateLayers
{
  NSArray* oldLayerDelegates = self.layerDelegates;
  NSMutableArray* newLayerDelegates = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

  // The order in which layer delegates are added to the array is important: It
  // determines the order in which layers are stacked.
  [newLayerDelegates addObject:self.gridLayerDelegate];
  if (self.crossHairLinesLayerDelegate)
    [newLayerDelegates addObject:self.crossHairLinesLayerDelegate];
  [newLayerDelegates addObject:self.stonesLayerDelegate];
  if (self.influenceLayerDelegate)
    [newLayerDelegates addObject:self.influenceLayerDelegate];
  if (self.symbolsLayerDelegate)
    [newLayerDelegates addObject:self.symbolsLayerDelegate];
  if (self.territoryLayerDelegate)
    [newLayerDelegates addObject:self.territoryLayerDelegate];

  // Removing/adding layers does not cause them to redraw. Only layers that
  // are newly created are redrawn.
  for (id<BoardViewLayerDelegate> oldLayerDelegate in oldLayerDelegates)
    [oldLayerDelegate.layer removeFromSuperlayer];
  for (id<BoardViewLayerDelegate> newLayerDelegate in newLayerDelegates)
    [self.layer addSublayer:newLayerDelegate.layer];

  // Replace the old array at the very end. The old array is now deallocated,
  // including any layer delegates that are no longer in newLayerDelegates
  self.layerDelegates = newLayerDelegates;
}

#pragma mark - Handle delayed drawing

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed drawing of layers.
/// BoardTileView methods that need a view update should invoke this helper
/// instead of drawLayers().
///
/// If no long-running actions are in progress, this helper invokes
/// drawLayers(), thus triggering the update in UIKit.
///
/// If any long-running actions are in progress, this helper sets
/// @e drawLayersWasDelayed to true.
// -----------------------------------------------------------------------------
- (void) delayedDrawLayers
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    self.drawLayersWasDelayed = true;
  else
    [self drawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Notifies all layers that they need to update now if they are dirty.
/// This marks one update cycle.
// -----------------------------------------------------------------------------
- (void) drawLayers
{
  // No game -> no board -> no drawing. This situation exists right after the
  // application has launched and the initial game is created only after a
  // small delay.
  if (! [GoGame sharedGame])
    return;
  self.drawLayersWasDelayed = false;

  for (id<BoardViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate drawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Notifies all layer delegates that @a event has occurred. The event
/// info object supplied to the delegates is @a eventInfo.
///
/// Delegates will ignore the event, or react to the event, as appropriate for
/// the layer that they manage.
// -----------------------------------------------------------------------------
- (void) notifyLayerDelegates:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  for (id<BoardViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate notify:event eventInfo:eventInfo];
}

#pragma mark - Tile protocol overrides

// -----------------------------------------------------------------------------
/// @brief Tile protocol method
// -----------------------------------------------------------------------------
- (void) invalidateContent
{
  [self notifyLayerDelegates:BVLDEventInvalidateContent eventInfo:nil];
  [self delayedDrawLayers];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  GoBoardPosition* oldBoardPosition = oldGame.boardPosition;
  [oldBoardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [oldBoardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  GoBoardPosition* newBoardPosition = newGame.boardPosition;
  [newBoardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [newBoardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
  [self notifyLayerDelegates:BVLDEventGoGameStarted eventInfo:nil];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringEnabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringEnabled:(NSNotification*)notification
{
  [self setupInfluenceLayerDelegate];
  [self setupSymbolsLayerDelegate];
  [self setupTerritoryLayerDelegate];
  [self updateLayers];
  [self notifyLayerDelegates:BVLDEventScoringModeEnabled eventInfo:nil];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringDisabled:(NSNotification*)notification
{
  [self setupInfluenceLayerDelegate];
  [self setupSymbolsLayerDelegate];
  [self setupTerritoryLayerDelegate];
  [self updateLayers];
  [self notifyLayerDelegates:BVLDEventScoringModeDisabled eventInfo:nil];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  [self notifyLayerDelegates:BVLDEventScoreCalculationEnds eventInfo:nil];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #territoryStatisticsChanged notifications.
// -----------------------------------------------------------------------------
- (void) territoryStatisticsChanged:(NSNotification*)notification
{
  [self notifyLayerDelegates:BVLDEventTerritoryStatisticsChanged eventInfo:nil];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewWillDisplayCrossHair notifications.
// -----------------------------------------------------------------------------
- (void) boardViewWillDisplayCrossHair:(NSNotification*)notification
{
  [self setupCrossHairLinesLayerDelegateIsRequired:true];
  [self updateLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewWillHideCrossHair notifications.
// -----------------------------------------------------------------------------
- (void) boardViewWillHideCrossHair:(NSNotification*)notification
{
  [self setupCrossHairLinesLayerDelegateIsRequired:false];
  [self updateLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  if (self.drawLayersWasDelayed)
    [self drawLayers];
}

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  BoardViewMetrics* metrics = appDelegate.boardViewMetrics;
  BoardViewModel* boardViewModel = appDelegate.boardViewModel;
  BoardPositionModel* boardPositionModel = appDelegate.boardPositionModel;
  ScoringModel* scoringModel = appDelegate.scoringModel;

  if (object == scoringModel)
  {
    if ([keyPath isEqualToString:@"inconsistentTerritoryMarkupType"])
    {
      if ([GoGame sharedGame].score.scoringEnabled)
      {
        [self notifyLayerDelegates:BVLDEventInconsistentTerritoryMarkupTypeChanged eventInfo:nil];
        [self delayedDrawLayers];
      }
    }
  }
  else if (object == boardPositionModel)
  {
    if ([keyPath isEqualToString:@"markNextMove"])
    {
      [self notifyLayerDelegates:BVLDEventMarkNextMoveChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
  }
  else if (object == metrics)
  {
    if ([keyPath isEqualToString:@"canvasSize"])
    {
      [self notifyLayerDelegates:BVLDEventBoardGeometryChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
    else if ([keyPath isEqualToString:@"boardSize"])
    {
      [self notifyLayerDelegates:BVLDEventBoardSizeChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
    else if ([keyPath isEqualToString:@"displayCoordinates"])
    {
      // Even though none of our layers draws coordinate labels, we still need
      // to send a notification because showing/hiding coordinates fundamentally
      // changes the geometry of the board
      [self notifyLayerDelegates:BVLDEventDisplayCoordinatesChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
  }
  else if (object == boardViewModel)
  {
    if ([keyPath isEqualToString:@"markLastMove"])
    {
      [self notifyLayerDelegates:BVLDEventMarkLastMoveChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
    else if ([keyPath isEqualToString:@"moveNumbersPercentage"])
    {
      [self notifyLayerDelegates:BVLDEventMoveNumbersPercentageChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
    else if ([keyPath isEqualToString:@"displayPlayerInfluence"])
    {
      [self setupInfluenceLayerDelegate];
      [self updateLayers];
    }
  }
  else if (object == [GoGame sharedGame].boardPosition)
  {
    if ([keyPath isEqualToString:@"currentBoardPosition"])
    {
      [self notifyLayerDelegates:BVLDEventBoardPositionChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
    else if ([keyPath isEqualToString:@"numberOfBoardPositions"])
    {
      [self notifyLayerDelegates:BVLDEventNumberOfBoardPositionsChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
  }
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
///
/// If this BoardTileView is added to a superview (i.e. @a newSuperview is not
/// nil), this BoardTileView registers to receive notifications so that it can
/// participate in drawing. It also sets up all layers and invalidates their
/// content so that they redraw in the next drawing cycle. This make sures that
/// 1) the tile view is drawing its content the first time after it is newly
/// allocated, or 2) re-drawing its content according to the current application
/// state after it is reused.
///
/// If this BoardTileView is removed from its superview (i.e. @a newSuperview is
/// nil), this BoardTileView unregisters from all notifications so that it no
/// longer takes part in the drawing process. Layers that currently exist are
/// frozen.
// -----------------------------------------------------------------------------
- (void) willMoveToSuperview:(UIView*)newSuperview
{
  if (newSuperview)
  {
    [self setupNotificationResponders];
    // If the view is reused: Layers may have come and gone since the view was
    // frozen
    [self setupLayerDelegates];
    [self invalidateContent];
  }
  else
  {
    [self removeNotificationResponders];
  }
}

// -----------------------------------------------------------------------------
/// @brief UIView method.
///
/// This implementation is not strictly required because BoardTileView is
/// currently not used in conjunction with Auto Layout.
// -----------------------------------------------------------------------------
- (CGSize) intrinsicContentSize
{
  return [ApplicationDelegate sharedDelegate].boardViewMetrics.tileSize;
}

@end
