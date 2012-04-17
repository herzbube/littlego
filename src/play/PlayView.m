// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayView.h"
#import "PlayViewMetrics.h"
#import "PlayViewModel.h"
#import "ScoringModel.h"
#import "layer/BoardLayerDelegate.h"
#import "layer/CrossHairLinesLayerDelegate.h"
#import "layer/CrossHairStoneLayerDelegate.h"
#import "layer/DeadStonesLayerDelegate.h"
#import "layer/GridLayerDelegate.h"
#import "layer/StarPointsLayerDelegate.h"
#import "layer/StonesLayerDelegate.h"
#import "layer/SymbolsLayerDelegate.h"
#import "layer/TerritoryLayerDelegate.h"
#import "../main/ApplicationDelegate.h"
#import "../go/GoGame.h"
#import "../go/GoBoard.h"
#import "../go/GoPoint.h"
#import "../go/GoVertex.h"
#import "../utility/NSStringAdditions.h"
#import "../utility/UIColorAdditions.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayView.
// -----------------------------------------------------------------------------
@interface PlayView()
/// @name Initialization and deallocation
//@{
- (id) initWithFrame:(CGRect)aRect;
- (void) dealloc;
//@}
/// @name Notification responders
//@{
- (void) applicationIsReadyForAction:(NSNotification*)notification;
- (void) goGameDidCreate:(NSNotification*)notification;
- (void) goGameLastMoveChanged:(NSNotification*)notification;
- (void) goScoreScoringModeEnabled:(NSNotification*)notification;
- (void) goScoreScoringModeDisabled:(NSNotification*)notification;
- (void) goScoreCalculationEnds:(NSNotification*)notification;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name Private helpers
//@{
- (void) makeViewReadyForDrawing;
- (void) setupSubLayer:(CALayer*)subLayer;
- (void) updateCrossHairPointDistanceFromFinger;
- (void) updateLayers;
- (void) delayedUpdate;
- (void) notifyLayerDelegates:(enum PlayViewLayerDelegateEvent)event eventInfo:(id)eventInfo;
//@}
/// @name Update optimizing
//@{
/// @brief Number of "expensive" actions that are currently in progress. View
/// updates are delayed while this number is >0.
@property(nonatomic, assign) int actionsInProgress;
/// @brief Is true if updates were delayed because @e actionsInProgress was >0.
@property(nonatomic, assign) bool updatesWereDelayed;
//@}
/// @name Dynamically calculated properties
//@{
@property(nonatomic, assign) float crossHairPointDistanceFromFinger;
//@}
/// @name Other privately declared properties
//@{
@property(nonatomic, assign) bool viewReadyForDrawing;
@property(nonatomic, assign) PlayViewModel* playViewModel;
@property(nonatomic, assign) ScoringModel* scoringModel;
@property(nonatomic, retain) PlayViewMetrics* playViewMetrics;
@property(nonatomic, retain) id<PlayViewLayerDelegate> boardLayerDelegate;
@property(nonatomic, retain) id<PlayViewLayerDelegate> gridLayerDelegate;
@property(nonatomic, retain) id<PlayViewLayerDelegate> starPointsLayerDelegate;
@property(nonatomic, retain) id<PlayViewLayerDelegate> crossHairLinesLayerDelegate;
@property(nonatomic, retain) id<PlayViewLayerDelegate> stonesLayerDelegate;
@property(nonatomic, retain) id<PlayViewLayerDelegate> crossHairStoneLayerDelegate;
@property(nonatomic, retain) id<PlayViewLayerDelegate> symbolsLayerDelegate;
@property(nonatomic, retain) id<PlayViewLayerDelegate> territoryLayerDelegate;
@property(nonatomic, retain) id<PlayViewLayerDelegate> deadStonesLayerDelegate;
//@}
@end


@implementation PlayView

@synthesize playViewModel;
@synthesize scoringModel;
@synthesize viewReadyForDrawing;

@synthesize crossHairPoint;
@synthesize crossHairPointIsLegalMove;
@synthesize crossHairPointDistanceFromFinger;

@synthesize actionsInProgress;
@synthesize updatesWereDelayed;

@synthesize playViewMetrics;
@synthesize boardLayerDelegate;
@synthesize gridLayerDelegate;
@synthesize starPointsLayerDelegate;
@synthesize crossHairLinesLayerDelegate;
@synthesize stonesLayerDelegate;
@synthesize crossHairStoneLayerDelegate;
@synthesize symbolsLayerDelegate;
@synthesize territoryLayerDelegate;
@synthesize deadStonesLayerDelegate;


// -----------------------------------------------------------------------------
/// @brief Shared instance of PlayView.
// -----------------------------------------------------------------------------
static PlayView* sharedPlayView = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared PlayView object.
// -----------------------------------------------------------------------------
+ (PlayView*) sharedView
{
  return sharedPlayView;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayView object with frame rectangle @a aRect. This
/// happens at least once during application launch, but may occur again later
/// on if the view is unloaded and then reloaded due to a memory warning.
///
/// Attempts to set up the view and make it ready for drawing. If this method
/// is invoked the very first time during application launch, the attempt fails
/// because the application delegate has not yet created all the objects that
/// are necessary for the application lifecycle. The delegate will send us a
/// notification as soon as it has finished its setup task, which will then
/// trigger the view setup.
///
/// If this method is invoked again later during the application's lifetime,
/// the setup attempt will succeed because all the necessary objects are already
/// there.
///
/// @note This is the designated initializer of PlayView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)aRect
{
  // Call designated initializer of superclass (NSView)
  self = [super initWithFrame:aRect];
  if (! self)
    return nil;

  sharedPlayView = self;

  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  if (! delegate.applicationReadyForAction)
  {
    self.viewReadyForDrawing = false;
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(applicationIsReadyForAction:) name:applicationIsReadyForAction object:nil];
  }
  else
  {
    [self makeViewReadyForDrawing];
    self.viewReadyForDrawing = true;
    [self notifyLayerDelegates:PVLDEventRectangleChanged eventInfo:nil];
    [self delayedUpdate];
  }

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.playViewModel removeObserver:self forKeyPath:@"markLastMove"];
  [self.playViewModel removeObserver:self forKeyPath:@"displayCoordinates;"];
  [self.playViewModel removeObserver:self forKeyPath:@"displayMoveNumbers"];
  [self.playViewModel removeObserver:self forKeyPath:@"placeStoneUnderFinger"];
  [self.scoringModel removeObserver:self forKeyPath:@"inconsistentTerritoryMarkupType"];

  self.playViewModel = nil;
  self.scoringModel = nil;
  self.crossHairPoint = nil;
  if (self == sharedPlayView)
    sharedPlayView = nil;

  self.playViewMetrics = nil;
  self.boardLayerDelegate = nil;
  self.gridLayerDelegate = nil;
  self.starPointsLayerDelegate = nil;
  self.crossHairLinesLayerDelegate = nil;
  self.stonesLayerDelegate = nil;
  self.crossHairStoneLayerDelegate = nil;
  self.symbolsLayerDelegate = nil;
  self.territoryLayerDelegate = nil;
  self.deadStonesLayerDelegate = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #applicationIsReadyForAction notification.
// -----------------------------------------------------------------------------
- (void) applicationIsReadyForAction:(NSNotification*)notification
{
  // We only need this notification once
  [[NSNotificationCenter defaultCenter] removeObserver:self name:applicationIsReadyForAction object:nil];

  [self makeViewReadyForDrawing];
  self.viewReadyForDrawing = true;
  [self notifyLayerDelegates:PVLDEventRectangleChanged eventInfo:nil];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the view and makes it ready for drawing.
// -----------------------------------------------------------------------------
- (void) makeViewReadyForDrawing
{
  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  self.playViewModel = delegate.playViewModel;
  self.scoringModel = delegate.scoringModel;

  self.crossHairPoint = nil;
  self.crossHairPointIsLegalMove = true;
  self.crossHairPointDistanceFromFinger = 0;

  self.actionsInProgress = 0;
  self.updatesWereDelayed = false;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goGameLastMoveChanged:) name:goGameLastMoveChanged object:nil];
  [center addObserver:self selector:@selector(goScoreScoringModeEnabled:) name:goScoreScoringModeEnabled object:nil];
  [center addObserver:self selector:@selector(goScoreScoringModeDisabled:) name:goScoreScoringModeDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  // KVO observing
  [self.playViewModel addObserver:self forKeyPath:@"markLastMove" options:0 context:NULL];
  [self.playViewModel addObserver:self forKeyPath:@"displayCoordinates;" options:0 context:NULL];
  [self.playViewModel addObserver:self forKeyPath:@"displayMoveNumbers" options:0 context:NULL];
  [self.playViewModel addObserver:self forKeyPath:@"placeStoneUnderFinger" options:0 context:NULL];
  [self.scoringModel addObserver:self forKeyPath:@"inconsistentTerritoryMarkupType" options:0 context:NULL];
  
  // One-time initialization
  [self updateCrossHairPointDistanceFromFinger];
  
  // Calculate an initial set of metrics. Later, layer delegates observe
  // PlayViewMetrics for rectangle and board size changes and update their
  // layers automatically.
  self.playViewMetrics = [[[PlayViewMetrics alloc] initWithView:self
                                                          model:playViewModel] autorelease];
  // If we already have a game, recalculate
  GoGame* game = [GoGame sharedGame];
  if (game)
    [self.playViewMetrics updateWithBoardSize:game.board.size];


  self.boardLayerDelegate = [[[BoardLayerDelegate alloc] initWithLayer:[CALayer layer]
                                                               metrics:playViewMetrics
                                                                 model:playViewModel] autorelease];
  self.gridLayerDelegate = [[[GridLayerDelegate alloc] initWithLayer:[CALayer layer]
                                                             metrics:playViewMetrics
                                                               model:playViewModel] autorelease];
  self.starPointsLayerDelegate = [[[StarPointsLayerDelegate alloc] initWithLayer:[CALayer layer]
                                                                         metrics:playViewMetrics
                                                                           model:playViewModel] autorelease];
  self.crossHairLinesLayerDelegate = [[[CrossHairLinesLayerDelegate alloc] initWithLayer:[CALayer layer]
                                                                                 metrics:playViewMetrics
                                                                                   model:playViewModel] autorelease];
  self.stonesLayerDelegate = [[[StonesLayerDelegate alloc] initWithLayer:[CALayer layer]
                                                                 metrics:playViewMetrics
                                                                   model:playViewModel] autorelease];
  self.crossHairStoneLayerDelegate = [[[CrossHairStoneLayerDelegate alloc] initWithLayer:[CALayer layer]
                                                                                 metrics:playViewMetrics
                                                                                   model:playViewModel] autorelease];
  self.symbolsLayerDelegate = [[[SymbolsLayerDelegate alloc] initWithLayer:[CALayer layer]
                                                                   metrics:playViewMetrics
                                                             playViewModel:playViewModel
                                                              scoringModel:scoringModel] autorelease];
  self.territoryLayerDelegate = [[[TerritoryLayerDelegate alloc] initWithLayer:[CALayer layer]
                                                                       metrics:playViewMetrics
                                                                 playViewModel:playViewModel
                                                                  scoringModel:scoringModel] autorelease];
  self.deadStonesLayerDelegate = [[[DeadStonesLayerDelegate alloc] initWithLayer:[CALayer layer]
                                                                         metrics:playViewMetrics
                                                                   playViewModel:playViewModel
                                                                    scoringModel:scoringModel] autorelease];

  [self setupSubLayer:boardLayerDelegate.layer];
  [self setupSubLayer:gridLayerDelegate.layer];
  [self setupSubLayer:starPointsLayerDelegate.layer];
  [self setupSubLayer:crossHairLinesLayerDelegate.layer];
  [self setupSubLayer:stonesLayerDelegate.layer];
  [self setupSubLayer:crossHairStoneLayerDelegate.layer];
  [self setupSubLayer:symbolsLayerDelegate.layer];
  [self setupSubLayer:territoryLayerDelegate.layer];
  [self setupSubLayer:deadStonesLayerDelegate.layer];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the specified layer as a sublayer of this Play view.
// -----------------------------------------------------------------------------
- (void) setupSubLayer:(CALayer*)subLayer
{
  [self.layer addSublayer:subLayer];
  // This disables the implicit animation that normally occurs when the layer
  // delegate is drawing. As always, stackoverflow.com is our friend:
  // http://stackoverflow.com/questions/2244147/disabling-implicit-animations-in-calayer-setneedsdisplayinrect
  NSMutableDictionary* newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"contents", nil];
  subLayer.actions = newActions;
  [newActions release];
}

// -----------------------------------------------------------------------------
/// @brief Increases @e actionsInProgress by 1.
// -----------------------------------------------------------------------------
- (void) actionStarts
{
  self.actionsInProgress++;
}

// -----------------------------------------------------------------------------
/// @brief Decreases @e actionsInProgress by 1. Triggers a view update if
/// @e actionsInProgress becomes 0 and @e updatesWereDelayed is true.
// -----------------------------------------------------------------------------
- (void) actionEnds
{
  self.actionsInProgress--;
  if (0 == self.actionsInProgress)
  {
    if (self.updatesWereDelayed)
      [self updateLayers];
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. PlayView
/// methods that need a view update should invoke this helper instead of
/// updateLayers().
///
/// If @e actionsInProgress is 0, this helper invokes updateLayers(),
/// thus triggering the update in UIKit.
///
/// If @e actionsInProgress is >0, this helper sets @e updatesWereDelayed to
/// true.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if (self.actionsInProgress > 0)
    self.updatesWereDelayed = true;
  else
    [self updateLayers];
}

// -----------------------------------------------------------------------------
/// @brief Notifies all layers that they need to update now if they are dirty.
/// This marks one update cycle.
// -----------------------------------------------------------------------------
- (void) updateLayers
{
  // Guard against
  // - updates triggered while the view is still uninitialized and not yet ready
  //   for drawing (occurs during application launch)
  if (! self.viewReadyForDrawing)
  {
    self.updatesWereDelayed = true;
    return;
  }
  // No game -> no board -> no drawing. This situation exists right after the
  // application has launched and the initial game is created only after a
  // small delay.
  if (! [GoGame sharedGame])
    return;
  self.updatesWereDelayed = false;

  [boardLayerDelegate drawLayer];
  [gridLayerDelegate drawLayer];
  [starPointsLayerDelegate drawLayer];
  [crossHairLinesLayerDelegate drawLayer];
  [stonesLayerDelegate drawLayer];
  [crossHairStoneLayerDelegate drawLayer];
  [symbolsLayerDelegate drawLayer];
  [territoryLayerDelegate drawLayer];
  [deadStonesLayerDelegate drawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Notifies all layer delegates that @a event has occurred. The event
/// info object supplied to the delegates is @a eventInfo.
///
/// Delegates will ignore the event, or react to the event, as appropriate for
/// the layer that they manage.
// -----------------------------------------------------------------------------
- (void) notifyLayerDelegates:(enum PlayViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  [boardLayerDelegate notify:event eventInfo:eventInfo];
  [gridLayerDelegate notify:event eventInfo:eventInfo];
  [starPointsLayerDelegate notify:event eventInfo:eventInfo];
  [crossHairLinesLayerDelegate notify:event eventInfo:eventInfo];
  [stonesLayerDelegate notify:event eventInfo:eventInfo];
  [crossHairStoneLayerDelegate notify:event eventInfo:eventInfo];
  [symbolsLayerDelegate notify:event eventInfo:eventInfo];
  [territoryLayerDelegate notify:event eventInfo:eventInfo];
  [deadStonesLayerDelegate notify:event eventInfo:eventInfo];
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when the frame of this view changes.
// -----------------------------------------------------------------------------
- (void) frameChanged
{
  [self.playViewMetrics updateWithRect:self.bounds];
  [self notifyLayerDelegates:PVLDEventRectangleChanged eventInfo:nil];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  [self updateCrossHairPointDistanceFromFinger];  // depends on board size
  [playViewMetrics updateWithBoardSize:[GoGame sharedGame].board.size];
  [self notifyLayerDelegates:PVLDEventGoGameStarted eventInfo:nil];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameLastMoveChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameLastMoveChanged:(NSNotification*)notification
{
  [self notifyLayerDelegates:PVLDEventLastMoveChanged eventInfo:nil];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringModeEnabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeEnabled:(NSNotification*)notification
{
  [self notifyLayerDelegates:PVLDEventScoringModeEnabled eventInfo:nil];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringModeDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeDisabled:(NSNotification*)notification
{
  [self notifyLayerDelegates:PVLDEventScoringModeDisabled eventInfo:nil];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  [self notifyLayerDelegates:PVLDEventScoreCalculationEnds eventInfo:nil];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if (object == self.scoringModel)
  {
    if ([keyPath isEqualToString:@"inconsistentTerritoryMarkupType"])
    {
      if (self.scoringModel.scoringMode)
      {
        [self notifyLayerDelegates:PVLDEventInconsistentTerritoryMarkupTypeChanged eventInfo:nil];
        [self delayedUpdate];
      }
    }
  }
  else if (object == self.playViewModel)
  {
    if ([keyPath isEqualToString:@"markLastMove"])
    {
      [self notifyLayerDelegates:PVLDEventMarkLastMoveChanged eventInfo:nil];
      [self delayedUpdate];
    }
    else if ([keyPath isEqualToString:@"displayCoordinates"])
    {
      [self notifyLayerDelegates:PVLDEventDisplayCoordinatesChanged eventInfo:nil];
      [self delayedUpdate];
    }
    else if ([keyPath isEqualToString:@"displayMoveNumbers"])
    {
      [self notifyLayerDelegates:PVLDEventDisplayMoveNumbersChanged eventInfo:nil];
      [self delayedUpdate];
    }
    else if ([keyPath isEqualToString:@"placeStoneUnderFinger"])
      [self updateCrossHairPointDistanceFromFinger];
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates self.crossHairPointDistanceFromFinger.
///
/// The calculation performed by this method depends on the following input
/// parameters:
/// - The value of the "place stone under fingertip" user preference
/// - The current board size
// -----------------------------------------------------------------------------
- (void) updateCrossHairPointDistanceFromFinger
{
  if (self.playViewModel.placeStoneUnderFinger)
  {
    self.crossHairPointDistanceFromFinger = 0;
  }
  else
  {
    GoGame* game = [GoGame sharedGame];
    float scaleFactor;
    if (! game)
      scaleFactor = 1.0;
    else
    {
      // Distance from fingertip should scale with board size. The base for
      // calculating the scale factor is the minimum board size.
      scaleFactor = 1.0 * game.board.size / GoBoardSizeMin;
      // Straight scaling results in a scale factor that is too large for big
      // boards, so we tune down the scale a little bit. The factor of 0.75 has
      // been determined experimentally.
      scaleFactor *= 0.75;
      // The final scale factor must not drop below 1 because we don't want to
      // get lower than crossHairPointDistanceFromFingerOnSmallestBoard.
      if (scaleFactor < 1.0)
        scaleFactor = 1.0;
    }
    self.crossHairPointDistanceFromFinger = crossHairPointDistanceFromFingerOnSmallestBoard * scaleFactor;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a GoPoint object for the intersection that is closest to the
/// view coordinates @a coordinates. Returns nil if there is no "closest"
/// intersection.
///
/// Determining "closest" works like this:
/// - If the user has turned this on in the preferences, @a coordinates are
///   slightly adjusted so that the intersection is not directly under the
///   user's fingertip
/// - Otherwise the same rules as for pointNear:() apply - see that method's
///   documentation.
// -----------------------------------------------------------------------------
- (GoPoint*) crossHairPointNear:(CGPoint)coordinates
{
  // Adjust so that the cross-hair is not directly under the user's fingertip,
  // but one or more point distances above
  coordinates.y -= self.crossHairPointDistanceFromFinger * self.playViewMetrics.pointDistance;
  return [playViewMetrics pointNear:coordinates];
}

// -----------------------------------------------------------------------------
/// @brief Moves the cross-hair to the intersection identified by @a point,
/// specifying whether an actual play move at the intersection would be legal.
// -----------------------------------------------------------------------------
- (void) moveCrossHairTo:(GoPoint*)point isLegalMove:(bool)isLegalMove
{
  if (crossHairPoint == point && crossHairPointIsLegalMove == isLegalMove)
    return;

  // Update *BEFORE* self.crossHairPoint so that KVO observers that monitor
  // self.crossHairPoint get both changes at once. Don't use self to update the
  // property because we don't want observers to monitor the property via KVO.
  crossHairPointIsLegalMove = isLegalMove;
  self.crossHairPoint = point;

  [self notifyLayerDelegates:PVLDEventCrossHairChanged eventInfo:point];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Returns a GoPoint object for the intersection that is closest to the
/// view coordinates @a coordinates. Returns nil if there is no "closest"
/// intersection.
///
/// @see PlayViewMetrics::pointNear:() for details.
// -----------------------------------------------------------------------------
- (GoPoint*) pointNear:(CGPoint)coordinates
{
  return [playViewMetrics pointNear:coordinates];
}

@end
