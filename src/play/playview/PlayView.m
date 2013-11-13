// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "layer/CoordinateLabelsLayerDelegate.h"
#import "layer/CrossHairLinesLayerDelegate.h"
#import "layer/CrossHairStoneLayerDelegate.h"
#import "layer/DeadStonesLayerDelegate.h"
#import "layer/GridLayerDelegate.h"
#import "layer/StarPointsLayerDelegate.h"
#import "layer/StonesLayerDelegate.h"
#import "layer/SymbolsLayerDelegate.h"
#import "layer/TerritoryLayerDelegate.h"
#import "layer/InfluenceLayerDelegate.h"
#import "../model/BoardPositionModel.h"
#import "../model/PlayViewModel.h"
#import "../model/ScoringModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoScore.h"
#import "../../go/GoVertex.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIColorAdditions.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PlayView.
// -----------------------------------------------------------------------------
@interface PlayView()
/// @name Update optimizing properties
//@{
/// @brief Is true if updates were delayed because of long-running actions.
@property(nonatomic, assign) bool updatesWereDelayed;
//@}
/// @name Dynamically calculated properties
//@{
@property(nonatomic, assign) float crossHairPointDistanceFromFinger;
//@}
/// @name Other privately declared properties
//@{
@property(nonatomic, assign) BoardPositionModel* boardPositionModel;
@property(nonatomic, assign) PlayViewModel* playViewModel;
@property(nonatomic, assign) ScoringModel* scoringModel;
@property(nonatomic, retain) PlayViewMetrics* playViewMetrics;
@property(nonatomic, retain) NSMutableArray* layerDelegates;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) UIScrollView* coordinateLabelsLetterViewScrollView;
@property(nonatomic, retain, readwrite) UIView* coordinateLabelsLetterView;
@property(nonatomic, retain, readwrite) UIScrollView* coordinateLabelsNumberViewScrollView;
@property(nonatomic, retain, readwrite) UIView* coordinateLabelsNumberView;
//@}
@end


@implementation PlayView

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayView object with frame rectangle @a rect. This
/// happens at least once during application launch, but may occur again later
/// on if the view is unloaded and then reloaded due to a memory warning.
///
/// @note This is the designated initializer of PlayView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  self.boardPositionModel = delegate.boardPositionModel;
  self.playViewModel = delegate.playViewModel;
  self.scoringModel = delegate.scoringModel;
  self.playViewMetrics = [[[PlayViewMetrics alloc] initWithView:self
                                                          model:self.playViewModel] autorelease];
  self.layerDelegates = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

  [self setupView];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.boardPositionModel removeObserver:self forKeyPath:@"markNextMove"];
  [self.playViewModel removeObserver:self forKeyPath:@"markLastMove"];
  [self.playViewModel removeObserver:self forKeyPath:@"displayCoordinates"];
  [self.playViewModel removeObserver:self forKeyPath:@"moveNumbersPercentage"];
  [self.playViewModel removeObserver:self forKeyPath:@"stoneDistanceFromFingertip"];
  [self.scoringModel removeObserver:self forKeyPath:@"inconsistentTerritoryMarkupType"];
  [[GoGame sharedGame].boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];

  self.playViewModel = nil;
  self.scoringModel = nil;
  self.crossHairPoint = nil;

  self.playViewMetrics = nil;
  self.layerDelegates = nil;

  self.coordinateLabelsLetterViewScrollView = nil;
  self.coordinateLabelsLetterView = nil;
  self.coordinateLabelsNumberViewScrollView = nil;
  self.coordinateLabelsNumberView = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the view and makes it ready for drawing.
// -----------------------------------------------------------------------------
- (void) setupView
{
  self.crossHairPoint = nil;
  self.crossHairPointIsLegalMove = true;
  self.crossHairPointIsIllegalReason = GoMoveIsIllegalReasonUnknown;
  self.crossHairPointDistanceFromFinger = 0;

  self.updatesWereDelayed = false;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goScoreTerritoryScoringEnabled:) name:goScoreTerritoryScoringEnabled object:nil];
  [center addObserver:self selector:@selector(goScoreTerritoryScoringDisabled:) name:goScoreTerritoryScoringDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(territoryStatisticsChanged:) name:territoryStatisticsChanged object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  [self.boardPositionModel addObserver:self forKeyPath:@"markNextMove" options:0 context:NULL];
  [self.playViewModel addObserver:self forKeyPath:@"markLastMove" options:0 context:NULL];
  [self.playViewModel addObserver:self forKeyPath:@"displayCoordinates" options:0 context:NULL];
  [self.playViewModel addObserver:self forKeyPath:@"moveNumbersPercentage" options:0 context:NULL];
  [self.playViewModel addObserver:self forKeyPath:@"stoneDistanceFromFingertip" options:0 context:NULL];
  [self.scoringModel addObserver:self forKeyPath:@"inconsistentTerritoryMarkupType" options:0 context:NULL];
  GoGame* game = [GoGame sharedGame];
  if (game)
    [game.boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];

  // One-time initialization
  [self updateCrossHairPointDistanceFromFinger];

  // If we already have a game, recalculate
  if (game)
    [self.playViewMetrics updateWithBoardSize:game.board.size];


  id<PlayViewLayerDelegate> layerDelegate;
  layerDelegate = [[[GridLayerDelegate alloc] initWithMainView:self
                                                    metrics:self.playViewMetrics
                                                      model:self.playViewModel] autorelease];
  [self setupLayerDelegate:layerDelegate withView:self];
  layerDelegate = [[[StarPointsLayerDelegate alloc] initWithMainView:self
                                                          metrics:self.playViewMetrics
                                                            model:self.playViewModel] autorelease];
  [self setupLayerDelegate:layerDelegate withView:self];
  layerDelegate = [[[CrossHairLinesLayerDelegate alloc] initWithMainView:self
                                                              metrics:self.playViewMetrics
                                                                model:self.playViewModel] autorelease];
  [self setupLayerDelegate:layerDelegate withView:self];
  layerDelegate = [[[StonesLayerDelegate alloc] initWithMainView:self
                                                      metrics:self.playViewMetrics
                                                        model:self.playViewModel] autorelease];
  [self setupLayerDelegate:layerDelegate withView:self];
  layerDelegate = [[[CrossHairStoneLayerDelegate alloc] initWithMainView:self
                                                              metrics:self.playViewMetrics
                                                                model:self.playViewModel] autorelease];
  [self setupLayerDelegate:layerDelegate withView:self];
  layerDelegate = [[[InfluenceLayerDelegate alloc] initWithMainView:self
                                                                      metrics:self.playViewMetrics
                                                                        model:self.playViewModel] autorelease];
  [self setupLayerDelegate:layerDelegate withView:self];
  layerDelegate = [[[SymbolsLayerDelegate alloc] initWithMainView:self
                                                       metrics:self.playViewMetrics
                                                 playViewModel:self.playViewModel
                                               boardPositionModel:self.boardPositionModel] autorelease];
  [self setupLayerDelegate:layerDelegate withView:self];
  layerDelegate = [[[TerritoryLayerDelegate alloc] initWithMainView:self
                                                         metrics:self.playViewMetrics
                                                   playViewModel:self.playViewModel
                                                    scoringModel:self.scoringModel] autorelease];
  [self setupLayerDelegate:layerDelegate withView:self];
  layerDelegate = [[[DeadStonesLayerDelegate alloc] initWithMainView:self
                                                          metrics:self.playViewMetrics
                                                    playViewModel:self.playViewModel
                                                     scoringModel:self.scoringModel] autorelease];
  [self setupLayerDelegate:layerDelegate withView:self];


  self.coordinateLabelsLetterView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.coordinateLabelsLetterViewScrollView = [[[UIScrollView alloc] initWithFrame:CGRectZero] autorelease];
  [self setupCoordinateLabelView:self.coordinateLabelsLetterView
                      scrollView:self.coordinateLabelsLetterViewScrollView
                            axis:CoordinateLabelAxisLetter];
  self.coordinateLabelsNumberView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.coordinateLabelsNumberViewScrollView = [[[UIScrollView alloc] initWithFrame:CGRectZero] autorelease];
  [self setupCoordinateLabelView:self.coordinateLabelsNumberView
                      scrollView:self.coordinateLabelsNumberViewScrollView
                            axis:CoordinateLabelAxisNumber];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupView().
// -----------------------------------------------------------------------------
- (void) setupLayerDelegate:(id<PlayViewLayerDelegate>)layerDelegate withView:(UIView*)view
{
  [view.layer addSublayer:layerDelegate.layer];
  [self.layerDelegates addObject:layerDelegate];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupView().
// -----------------------------------------------------------------------------
- (void) setupCoordinateLabelView:(UIView*)labelView
                       scrollView:(UIScrollView*)scrollView
                             axis:(enum CoordinateLabelAxis)axis
{
  scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  scrollView.backgroundColor = [UIColor clearColor];
  scrollView.userInteractionEnabled = NO;
  [scrollView addSubview:labelView];
  id<PlayViewLayerDelegate> layerDelegate = [[[CoordinateLabelsLayerDelegate alloc] initWithMainView:labelView
                                                                                             metrics:self.playViewMetrics
                                                                                               model:self.playViewModel
                                                                                                axis:axis] autorelease];
  [self setupLayerDelegate:layerDelegate withView:labelView];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. PlayView
/// methods that need a view update should invoke this helper instead of
/// updateLayers().
///
/// If no long-running actions are in progress, this helper invokes
/// updateLayers(), thus triggering the update in UIKit.
///
/// If any long-running actions are in progress, this helper sets
/// @e updatesWereDelayed to true.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
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
  // No game -> no board -> no drawing. This situation exists right after the
  // application has launched and the initial game is created only after a
  // small delay.
  if (! [GoGame sharedGame])
    return;
  self.updatesWereDelayed = false;
  for (id<PlayViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate drawLayer];
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
  for (id<PlayViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate notify:event eventInfo:eventInfo];
}

// -----------------------------------------------------------------------------
/// @brief UIView method.
///
/// Overriding this method is important so that we can react to frame size
/// changes that occur when this view is autoresized, e.g. when the device
/// orientation changes.
///
/// This is also invoked soon after initialization.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  [super layoutSubviews];

  // Disabling animations here is essential for a smooth GUI update after a zoom
  // operation ends. If animations were enabled, setting the layer frames would
  // trigger an animation that looks like a "bounce". For details see
  // http://stackoverflow.com/questions/15370803/how-to-prevent-bounce-effect-when-a-custom-view-redraws-after-zooming
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  [self.playViewMetrics updateWithRect:self.bounds];
  [self layoutCoordinateLabelView:self.coordinateLabelsLetterView
                       scrollView:self.coordinateLabelsLetterViewScrollView];
  [self layoutCoordinateLabelView:self.coordinateLabelsNumberView
                       scrollView:self.coordinateLabelsNumberViewScrollView];
  [self notifyLayerDelegates:PVLDEventRectangleChanged eventInfo:nil];
  [self delayedUpdate];
  [CATransaction commit];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for layoutSubviews.
// -----------------------------------------------------------------------------
- (void) layoutCoordinateLabelView:(UIView*)view scrollView:(UIScrollView*)scrollView
{
  CGRect viewFrame = view.frame;
  CGRect scrollViewFrame = scrollView.frame;
  if (view == self.coordinateLabelsLetterView)
  {
    viewFrame.size.width = self.bounds.size.width;
    viewFrame.size.height = self.playViewMetrics.coordinateLabelStripWidth;
    scrollViewFrame.size.width = self.superview.bounds.size.width;
    scrollViewFrame.size.height = self.playViewMetrics.coordinateLabelStripWidth;
  }
  else
  {
    viewFrame.size.width = self.playViewMetrics.coordinateLabelStripWidth;
    viewFrame.size.height = self.bounds.size.height;
    scrollViewFrame.size.width = self.playViewMetrics.coordinateLabelStripWidth;
    scrollViewFrame.size.height = self.superview.bounds.size.height;
  }
  view.frame = viewFrame;
  scrollView.contentSize = viewFrame.size;
  // Changing the scroll view frame resets the content offset to (0,0). This
  // must not happen because it would position the coordinate labels wrongly
  // after a zoom operation. We preserve the content offset by re-applying it
  // after the frame change.
  CGPoint contentOffset = scrollView.contentOffset;
  scrollView.frame = scrollViewFrame;
  scrollView.contentOffset = contentOffset;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  [oldGame.boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  [newGame.boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];

  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  [self.playViewMetrics updateWithBoardSize:[GoGame sharedGame].board.size];
  [self layoutCoordinateLabelView:self.coordinateLabelsLetterView
                       scrollView:self.coordinateLabelsLetterViewScrollView];
  [self layoutCoordinateLabelView:self.coordinateLabelsNumberView
                       scrollView:self.coordinateLabelsNumberViewScrollView];
  [self notifyLayerDelegates:PVLDEventGoGameStarted eventInfo:nil];
  [self delayedUpdate];
  [CATransaction commit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreTerritoryScoringEnabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreTerritoryScoringEnabled:(NSNotification*)notification
{
  [self notifyLayerDelegates:PVLDEventScoringModeEnabled eventInfo:nil];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreTerritoryScoringDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreTerritoryScoringDisabled:(NSNotification*)notification
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
/// @brief Responds to the #goScoreCalculationEnds notifications.
// -----------------------------------------------------------------------------
- (void) territoryStatisticsChanged:(NSNotification*)notification
{
  [self notifyLayerDelegates:PVLDEventTerritoryStatisticsChanged eventInfo:nil];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  if (self.updatesWereDelayed)
    [self updateLayers];
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
      if ([GoGame sharedGame].score.territoryScoringEnabled)
      {
        [self notifyLayerDelegates:PVLDEventInconsistentTerritoryMarkupTypeChanged eventInfo:nil];
        [self delayedUpdate];
      }
    }
  }
  else if (object == self.boardPositionModel)
  {
    if ([keyPath isEqualToString:@"markNextMove"])
    {
      [self notifyLayerDelegates:PVLDEventMarkNextMoveChanged eventInfo:nil];
      [self delayedUpdate];
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
      [self setNeedsLayout];
    }
    else if ([keyPath isEqualToString:@"moveNumbersPercentage"])
    {
      [self notifyLayerDelegates:PVLDEventMoveNumbersPercentageChanged eventInfo:nil];
      [self delayedUpdate];
    }
    else if ([keyPath isEqualToString:@"stoneDistanceFromFingertip"])
      [self updateCrossHairPointDistanceFromFinger];
  }
  else if (object == [GoGame sharedGame].boardPosition)
  {
    [self notifyLayerDelegates:PVLDEventBoardPositionChanged eventInfo:nil];
    [self delayedUpdate];
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates self.crossHairPointDistanceFromFinger.
///
/// The calculation performed by this method depends on the value of the
/// "stone distance from fingertip" user preference. The value is a percentage
/// that is applied to a maximum distance of n fingertips, i.e. if the user has
/// selected the maximum distance the cross-hair stone will appear n fingertips
/// away from the actual touch point on the screen. Currently n = 3, and 1
/// fingertip is assumed to be the size of a toolbar button as per Apple's HIG.
// -----------------------------------------------------------------------------
- (void) updateCrossHairPointDistanceFromFinger
{
  if (0.0f == self.playViewModel.stoneDistanceFromFingertip)
  {
    self.crossHairPointDistanceFromFinger = 0;
  }
  else
  {
    static const float fingertipSizeInPoints = 20.0;  // toolbar button size in points
    static const float numberOfFingertips = 3.0;
    self.crossHairPointDistanceFromFinger = (fingertipSizeInPoints
                                             * numberOfFingertips
                                             * self.playViewModel.stoneDistanceFromFingertip);
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a PlayViewIntersection object for the intersection that is
/// closest to the view coordinates @a coordinates. Returns
/// PlayViewIntersectionNull if there is no "closest" intersection.
///
/// Determining "closest" works like this:
/// - If the user has turned this on in the preferences, @a coordinates are
///   adjusted so that the intersection is not directly under the user's
///   fingertip
/// - Otherwise the same rules as for PlayViewMetrics::intersectionNear:()
///   apply - see that method's documentation.
// -----------------------------------------------------------------------------
- (PlayViewIntersection) crossHairIntersectionNear:(CGPoint)coordinates
{
  coordinates.y -= self.crossHairPointDistanceFromFinger;
  return [_playViewMetrics intersectionNear:coordinates];
}

// -----------------------------------------------------------------------------
/// @brief Moves the cross-hair to the intersection identified by @a point,
/// specifying whether an actual play move at the intersection would be legal.
// -----------------------------------------------------------------------------
- (void) moveCrossHairTo:(GoPoint*)point isLegalMove:(bool)isLegalMove isIllegalReason:(enum GoMoveIsIllegalReason)illegalReason
{
  if (_crossHairPoint == point && _crossHairPointIsLegalMove == isLegalMove)
    return;

  // Update *BEFORE* self.crossHairPoint so that KVO observers that monitor
  // self.crossHairPoint get both changes at once. Don't use self to update the
  // property because we don't want observers to monitor the property via KVO.
  _crossHairPointIsLegalMove = isLegalMove;
  _crossHairPointIsIllegalReason = illegalReason;
  self.crossHairPoint = point;

  [self notifyLayerDelegates:PVLDEventCrossHairChanged eventInfo:point];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Returns a PlayViewIntersection object for the intersection that is
/// closest to the view coordinates @a coordinates. Returns
/// PlayViewIntersectionNull if there is no "closest" intersection.
///
/// @see PlayViewMetrics::intersectionNear:() for details.
// -----------------------------------------------------------------------------
- (PlayViewIntersection) intersectionNear:(CGPoint)coordinates
{
  return [_playViewMetrics intersectionNear:coordinates];
}

@end
