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
#import "layer/CrossHairLayerDelegate.h"
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
- (void) goScoreScoringModeDisabled:(NSNotification*)notification;
- (void) goScoreCalculationEnds:(NSNotification*)notification;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name Private helpers
//@{
- (void) makeViewReadyForDrawing;
- (void) updateCrossHairPointDistanceFromFinger;
- (void) updateLayers;
- (void) delayedUpdate;
- (void) dirtyAllLayers;
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
@property(nonatomic, retain) BoardLayerDelegate* boardLayerDelegate;
@property(nonatomic, retain) GridLayerDelegate* gridLayerDelegate;
@property(nonatomic, retain) StarPointsLayerDelegate* starPointsLayerDelegate;
@property(nonatomic, retain) StonesLayerDelegate* stonesLayerDelegate;
@property(nonatomic, retain) CrossHairLayerDelegate* crossHairLayerDelegate;
@property(nonatomic, retain) SymbolsLayerDelegate* symbolsLayerDelegate;
@property(nonatomic, retain) TerritoryLayerDelegate* territoryLayerDelegate;
@property(nonatomic, retain) DeadStonesLayerDelegate* deadStonesLayerDelegate;
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
@synthesize stonesLayerDelegate;
@synthesize crossHairLayerDelegate;
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
    [self dirtyAllLayers];
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
  self.stonesLayerDelegate = nil;
  self.crossHairLayerDelegate = nil;
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
  [self dirtyAllLayers];
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
  self.stonesLayerDelegate = [[[StonesLayerDelegate alloc] initWithLayer:[CALayer layer]
                                                                 metrics:playViewMetrics
                                                                   model:playViewModel] autorelease];
  self.crossHairLayerDelegate = [[[CrossHairLayerDelegate alloc] initWithLayer:[CALayer layer]
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

  [self.layer addSublayer:boardLayerDelegate.layer];
  [self.layer addSublayer:gridLayerDelegate.layer];
  [self.layer addSublayer:starPointsLayerDelegate.layer];
  [self.layer addSublayer:stonesLayerDelegate.layer];
  [self.layer addSublayer:crossHairLayerDelegate.layer];
  [self.layer addSublayer:symbolsLayerDelegate.layer];
  [self.layer addSublayer:territoryLayerDelegate.layer];
  [self.layer addSublayer:deadStonesLayerDelegate.layer];
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
//xxx  if (! [GoGame sharedGame])
//xxx    return;
  self.updatesWereDelayed = false;

  [boardLayerDelegate updateIfDirty];
  [gridLayerDelegate updateIfDirty];
  [starPointsLayerDelegate updateIfDirty];
  [stonesLayerDelegate updateIfDirty];
  [crossHairLayerDelegate updateIfDirty];
  [symbolsLayerDelegate updateIfDirty];
  [territoryLayerDelegate updateIfDirty];
  [deadStonesLayerDelegate updateIfDirty];
}

// -----------------------------------------------------------------------------
/// @brief Marks all layers dirty so that they redraw themselves in the next
/// update cycle.
// -----------------------------------------------------------------------------
- (void) dirtyAllLayers
{
  boardLayerDelegate.dirty = true;
  gridLayerDelegate.dirty = true;
  starPointsLayerDelegate.dirty = true;
  stonesLayerDelegate.dirty = true;
  crossHairLayerDelegate.dirty = true;
  symbolsLayerDelegate.dirty = true;
  territoryLayerDelegate.dirty = true;
  deadStonesLayerDelegate.dirty = true;
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when the frame of this view changes.
// -----------------------------------------------------------------------------
- (void) frameChanged
{
  // Updating the metrics object triggers layer delegates to update their layers
  [self.playViewMetrics updateWithRect:self.bounds];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  [self updateCrossHairPointDistanceFromFinger];  // depends on board size
  [playViewMetrics updateWithBoardSize:[GoGame sharedGame].board.size];
  [self dirtyAllLayers];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameLastMoveChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameLastMoveChanged:(NSNotification*)notification
{
  self.stonesLayerDelegate.dirty = true;
  self.symbolsLayerDelegate.dirty = true;  // update "last move" marker
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringModeDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeDisabled:(NSNotification*)notification
{
//xxx  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  self.territoryLayerDelegate.dirty = true;
  self.deadStonesLayerDelegate.dirty = true;
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
        self.territoryLayerDelegate.dirty = true;
        [self delayedUpdate];
      }
    }
  }
  else if (object == self.playViewModel)
  {
    if ([keyPath isEqualToString:@"markLastMove"])
    {
      self.symbolsLayerDelegate.dirty = true;
      [self delayedUpdate];
    }
    else if ([keyPath isEqualToString:@"displayCoordinates"])
    {
      // TODO: not yet implemented
    }
    else if ([keyPath isEqualToString:@"displayMoveNumbers"])
    {
      // TODO: not yet implemented
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
      int minBoardDimension = [GoBoard dimensionForSize:GoBoardSizeMin];
      int currentBoardDimension = game.board.dimensions;
      scaleFactor = 1.0 * currentBoardDimension / minBoardDimension;
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
/// - Otherwise the same rules as for pointAt:() apply - see that method's
///   documentation.
// -----------------------------------------------------------------------------
- (GoPoint*) crossHairPointAt:(CGPoint)coordinates
{
  // Adjust so that the cross-hair is not directly under the user's fingertip,
  // but one or more point distances above
  coordinates.y -= self.crossHairPointDistanceFromFinger * self.playViewMetrics.pointDistance;
  return [self pointAt:coordinates];
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

  self.crossHairLayerDelegate.crossHairPoint = point;
  self.crossHairLayerDelegate.dirty = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Returns a GoPoint object for the intersection that is closest to the
/// view coordinates @a coordinates. Returns nil if there is no "closest"
/// intersection.
///
/// Determining "closest" works like this:
/// - The closest intersection is the one whose distance to @a coordinates is
///   less than half the distance between two adjacent intersections
///   - During panning this creates a "snap-to" effect when the user's panning
///     fingertip crosses half the distance between two adjacent intersections.
///   - For a tap this simply makes sure that the fingertip does not have to
///     hit the exact coordinate of the intersection.
/// - If @a coordinates are a sufficient distance away from the Go board edges,
///   there is no "closest" intersection
// -----------------------------------------------------------------------------
- (GoPoint*) pointAt:(CGPoint)coordinates
{
  int halfPointDistance = floor(playViewMetrics.pointDistance / 2);
  bool coordinatesOutOfRange = false;

  // Check if coordinates are outside the grid on the x-axis and cannot be
  // mapped to a point. To make the edge lines accessible in the same way as
  // the inner lines, a padding of half a point distance must be added.
  if (coordinates.x < playViewMetrics.topLeftPointX)
  {
    if (coordinates.x < playViewMetrics.topLeftPointX - halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.x = playViewMetrics.topLeftPointX;
  }
  else if (coordinates.x > playViewMetrics.topLeftPointX + playViewMetrics.lineLength)
  {
    if (coordinates.x > playViewMetrics.topLeftPointX + playViewMetrics.lineLength + halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.x = playViewMetrics.topLeftPointX + playViewMetrics.lineLength;
  }
  else
  {
    // Adjust so that the snap-to calculation below switches to the next vertex
    // when the coordinates are half-way through the distance to that vertex
    coordinates.x += halfPointDistance;
  }

  // Unless the x-axis checks have already found the coordinates to be out of
  // range, we now perform the same checks as above on the y-axis
  if (coordinatesOutOfRange)
  {
    // Coordinates are already out of range, no more checks necessary
  }
  else if (coordinates.y < playViewMetrics.topLeftPointY)
  {
    if (coordinates.y < playViewMetrics.topLeftPointY - halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.y = playViewMetrics.topLeftPointY;
  }
  else if (coordinates.y > playViewMetrics.topLeftPointY + playViewMetrics.lineLength)
  {
    if (coordinates.y > playViewMetrics.topLeftPointY + playViewMetrics.lineLength + halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.y = playViewMetrics.topLeftPointY + playViewMetrics.lineLength;
  }
  else
  {
    coordinates.y += halfPointDistance;
  }

  // Snap to the nearest vertex, unless the coordinates were out of range
  if (coordinatesOutOfRange)
    return nil;
  else
  {
    coordinates.x = (playViewMetrics.topLeftPointX
                     + playViewMetrics.pointDistance * floor((coordinates.x - playViewMetrics.topLeftPointX) / playViewMetrics.pointDistance));
    coordinates.y = (playViewMetrics.topLeftPointY
                     + playViewMetrics.pointDistance * floor((coordinates.y - playViewMetrics.topLeftPointY) / playViewMetrics.pointDistance));
    return [playViewMetrics pointFromCoordinates:coordinates];
  }
}

@end
