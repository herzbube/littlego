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
#import "layer/CrossHairStoneLayerDelegate.h"
#import "layer/GridLayerDelegate.h"
#import "layer/InfluenceLayerDelegate.h"
#import "layer/StonesLayerDelegate.h"
#import "layer/SymbolsLayerDelegate.h"
#import "layer/TerritoryLayerDelegate.h"
#import "../model/PlayViewMetrics.h"
#import "../model/PlayViewModel.h"
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
@property(nonatomic, assign) BVGridLayerDelegate* gridLayerDelegate;
@property(nonatomic, assign) BVCrossHairLinesLayerDelegate* crossHairLinesLayerDelegate;
@property(nonatomic, assign) BVStonesLayerDelegate* stonesLayerDelegate;
@property(nonatomic, assign) BVCrossHairStoneLayerDelegate* crossHairStoneLayerDelegate;
@property(nonatomic, assign) BVInfluenceLayerDelegate* influenceLayerDelegate;
@property(nonatomic, assign) BVSymbolsLayerDelegate* symbolsLayerDelegate;
@property(nonatomic, assign) BVTerritoryLayerDelegate* territoryLayerDelegate;
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
  [self setupLayers];
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
  [super dealloc];
}

#pragma mark - View setup

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupLayers
{
  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;
  self.gridLayerDelegate = [[[BVGridLayerDelegate alloc] initWithTile:self
                                                              metrics:metrics] autorelease];
  self.crossHairLinesLayerDelegate = nil;
  self.stonesLayerDelegate = [[[BVStonesLayerDelegate alloc] initWithTile:self
                                                                  metrics:metrics] autorelease];
  self.crossHairStoneLayerDelegate = nil;
  [self createOrResetInfluenceLayer];
  [self createOrResetSymbolsLayer];
  [self createOrResetTerritoryLayer];

  [self updateLayers];
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
  PlayViewMetrics* metrics = appDelegate.playViewMetrics;
  PlayViewModel* playViewModel = appDelegate.playViewModel;
  BoardPositionModel* boardPositionModel = appDelegate.boardPositionModel;
  ScoringModel* scoringModel = appDelegate.scoringModel;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
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
  [metrics addObserver:self forKeyPath:@"rect" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"boardSize" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"displayCoordinates" options:0 context:NULL];
  [playViewModel addObserver:self forKeyPath:@"displayPlayerInfluence" options:0 context:NULL];
  [playViewModel addObserver:self forKeyPath:@"markLastMove" options:0 context:NULL];
  [playViewModel addObserver:self forKeyPath:@"moveNumbersPercentage" options:0 context:NULL];
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
  PlayViewMetrics* metrics = appDelegate.playViewMetrics;
  PlayViewModel* playViewModel = appDelegate.playViewModel;
  BoardPositionModel* boardPositionModel = appDelegate.boardPositionModel;
  ScoringModel* scoringModel = appDelegate.scoringModel;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center removeObserver:self];
  [boardPositionModel removeObserver:self forKeyPath:@"markNextMove"];
  [metrics removeObserver:self forKeyPath:@"rect"];
  [metrics removeObserver:self forKeyPath:@"boardSize"];
  [metrics removeObserver:self forKeyPath:@"displayCoordinates"];
  [playViewModel removeObserver:self forKeyPath:@"displayPlayerInfluence"];
  [playViewModel removeObserver:self forKeyPath:@"markLastMove"];
  [playViewModel removeObserver:self forKeyPath:@"moveNumbersPercentage"];
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
  if (self.crossHairStoneLayerDelegate)
    [newLayerDelegates addObject:self.crossHairStoneLayerDelegate];
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

// -----------------------------------------------------------------------------
/// @brief Creates the influence layer delegate, or resets it to nil, depending
/// on the current application state.
// -----------------------------------------------------------------------------
- (void) createOrResetInfluenceLayer
{
  if ([GoGame sharedGame].score.scoringEnabled)
  {
    self.influenceLayerDelegate = nil;
  }
  else
  {
    ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
    PlayViewModel* playViewModel = appDelegate.playViewModel;
    if (playViewModel.displayPlayerInfluence)
    {
      self.influenceLayerDelegate = [[[BVInfluenceLayerDelegate alloc] initWithTile:self
                                                                            metrics:appDelegate.playViewMetrics
                                                                      playViewModel:playViewModel] autorelease];
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
- (void) createOrResetSymbolsLayer
{
  if ([GoGame sharedGame].score.scoringEnabled)
  {
    self.symbolsLayerDelegate = nil;
  }
  else
  {
    ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
    self.symbolsLayerDelegate = [[[BVSymbolsLayerDelegate alloc] initWithTile:self
                                                                      metrics:appDelegate.playViewMetrics
                                                                playViewModel:appDelegate.playViewModel
                                                           boardPositionModel:appDelegate.boardPositionModel] autorelease];

  }
}

// -----------------------------------------------------------------------------
/// @brief Creates the territory layer delegate, or resets it to nil, depending
/// on the current application state.
// -----------------------------------------------------------------------------
- (void) createOrResetTerritoryLayer
{

  if ([GoGame sharedGame].score.scoringEnabled)
  {
    ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
    self.territoryLayerDelegate = [[[BVTerritoryLayerDelegate alloc] initWithTile:self
                                                                          metrics:appDelegate.playViewMetrics
                                                                     scoringModel:appDelegate.scoringModel] autorelease];
  }
  else
  {
    self.territoryLayerDelegate = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates the cross-hair layer delegates.
// -----------------------------------------------------------------------------
- (void) createCrossHairLayers
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  self.crossHairLinesLayerDelegate = [[[BVCrossHairLinesLayerDelegate alloc] initWithTile:self
                                                                                  metrics:appDelegate.playViewMetrics] autorelease];
  self.crossHairStoneLayerDelegate = [[[BVCrossHairStoneLayerDelegate alloc] initWithTile:self
                                                                                  metrics:appDelegate.playViewMetrics] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Resets the cross-hair layer delegates to nil.
// -----------------------------------------------------------------------------
- (void) resetCrossHairLayers
{
  self.crossHairLinesLayerDelegate = nil;
  self.crossHairStoneLayerDelegate = nil;
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
  // todo xxx we should not need that, but layer delegates still rely on it
  [self notifyLayerDelegates:BVLDEventBoardGeometryChanged eventInfo:nil];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringEnabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringEnabled:(NSNotification*)notification
{
  [self createOrResetInfluenceLayer];
  [self createOrResetSymbolsLayer];
  [self createOrResetTerritoryLayer];
  [self updateLayers];
  [self notifyLayerDelegates:BVLDEventScoringModeEnabled eventInfo:nil];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringDisabled:(NSNotification*)notification
{
  [self createOrResetInfluenceLayer];
  [self createOrResetSymbolsLayer];
  [self createOrResetTerritoryLayer];
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
  [self createCrossHairLayers];
  [self updateLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewWillHideCrossHair notifications.
// -----------------------------------------------------------------------------
- (void) boardViewWillHideCrossHair:(NSNotification*)notification
{
  [self resetCrossHairLayers];
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
  PlayViewMetrics* metrics = appDelegate.playViewMetrics;
  PlayViewModel* playViewModel = appDelegate.playViewModel;
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
    if ([keyPath isEqualToString:@"rect"])
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
  else if (object == playViewModel)
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
      [self createOrResetInfluenceLayer];
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
/// participate in drawing. It also invalidates the content in all of its
/// layers so that they redraw in the next drawing cycle. This make sures that
/// the tile view is drawing its content the first time after it is newly
/// allocated, or after it is reused.
///
/// If this BoardTileView is removed from its superview (i.e. @a newSuperview is
/// nil), this BoardTileView unregisters from all notifications so that it no
/// longer takes part in the drawing process.
// -----------------------------------------------------------------------------
- (void) willMoveToSuperview:(UIView*)newSuperview
{
  if (newSuperview)
  {
    [self setupNotificationResponders];
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
  return [ApplicationDelegate sharedDelegate].playViewMetrics.tileSize;
}

@end
