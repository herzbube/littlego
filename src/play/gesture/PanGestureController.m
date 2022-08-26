// -----------------------------------------------------------------------------
// Copyright 2013-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "PanGestureController.h"
#import "handler/PanGestureHandler.h"
#import "../boardview/BoardView.h"
#import "../model/BoardViewMetrics.h"
#import "../model/BoardViewModel.h"
#import "../model/MarkupModel.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoUtilities.h"
#import "../../main/ApplicationDelegate.h"
#import "../../main/MainUtility.h"
#import "../../main/MagnifyingGlassOwner.h"
#import "../../shared/LayoutManager.h"
#import "../../ui/MagnifyingViewModel.h"
#import "../../ui/UiSettingsModel.h"
#import "../../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PanGestureController.
// -----------------------------------------------------------------------------
@interface PanGestureController()
@property(nonatomic, retain) UILongPressGestureRecognizer* longPressRecognizer;
@property(nonatomic, assign, getter=isPanningEnabled) bool panningEnabled;
/// @brief Remember whether the controller has registered as observer for
/// GoBoardPosition.
///
/// Before this flag was introduced, crash reports were received that indicated
/// that the controller tried to unregister from observing GoBoardPosition
/// although the controller hadn't registered as observer before. The scenario
/// was thought to be impossible, but obviously the analysis must have missed
/// something. Although the root cause for the problem was never identified,
/// this flag was added so that a bit of general-purpose defensive programming
/// could be implemented.
@property(nonatomic, assign) bool observingBoardPosition;
/// @brief The GoPoint that identifies the intersection from which the panning
/// gesture started.
///
/// This property is initialized when the panning gesture begins. It is updated
/// continuously while the gesture is in progress. It is set back to @e nil when
/// the gesture ends.
@property(nonatomic, assign) GoPoint* gestureStartPoint;
/// @brief The GoPoint that identifies the intersection near the location of the
/// most recent gesture update.
///
/// This property is initialized when the panning gesture begins. It is updated
/// continuously while the gesture is in progress. It is set back to @e nil when
/// the gesture ends.
@property(nonatomic, assign) GoPoint* gestureMostRecentPoint;
/// @brief An object that is handling pan gestures for the current application
/// state.
@property(nonatomic, retain) PanGestureHandler* panGestureHandler;
@end


@implementation PanGestureController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PanGestureController object.
///
/// @note This is the designated initializer of PanGestureController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.boardView = nil;
  self.gestureStartPoint = nil;
  self.gestureMostRecentPoint = nil;
  self.panGestureHandler = nil;
  [self setupLongPressGestureRecognizer];
  [self setupNotificationResponders];
  [self updatePanningEnabled];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PanGestureController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.boardView = nil;
  self.longPressRecognizer = nil;
  self.gestureStartPoint = nil;
  self.gestureMostRecentPoint = nil;
  self.panGestureHandler = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupLongPressGestureRecognizer
{
  self.longPressRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)] autorelease];
  self.longPressRecognizer.delegate = self;
  CGFloat infiniteMovement = CGFLOAT_MAX;
  self.longPressRecognizer.allowableMovement = infiniteMovement;  // let the user pan as long as he wants
  self.longPressRecognizer.minimumPressDuration = gGoBoardLongPressDelay;
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(uiAreaPlayModeDidChange:) name:uiAreaPlayModeDidChange object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationWillBegin:) name:boardViewAnimationWillBegin object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationDidEnd:) name:boardViewAnimationDidEnd object:nil];
  // KVO observing
  [self setupBoardPositionObserver:[GoGame sharedGame].boardPosition];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  [appDelegate.markupModel addObserver:self forKeyPath:@"markupTool" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionObserver:(GoBoardPosition*)boardPosition
{
  if (boardPosition)
  {
    [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
    self.observingBoardPosition = true;
  }
  else
  {
    self.observingBoardPosition = false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self removeBoardPositionObserver:[GoGame sharedGame].boardPosition];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  [appDelegate.markupModel removeObserver:self forKeyPath:@"markupTool"];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeBoardPositionObserver:(GoBoardPosition*)boardPosition
{
  if (! self.observingBoardPosition)
    return;
  self.observingBoardPosition = false;
  if (boardPosition)
    [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
}

#pragma mark - Property setter

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardView:(BoardView*)boardView
{
  if (_boardView == boardView)
    return;

  if (_boardView && self.longPressRecognizer)
    [_boardView removeGestureRecognizer:self.longPressRecognizer];

  _boardView = boardView;

  if (_boardView && self.longPressRecognizer)
    [_boardView addGestureRecognizer:self.longPressRecognizer];

  [self updatePanGestureHandler];  // because gesture handler depends on BoardView
}

#pragma mark - UIGestureRecognizerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UIGestureRecognizerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) handlePanFrom:(UILongPressGestureRecognizer*)gestureRecognizer
{
  // TODO move the following summary somewhere else where it is not buried in
  // code and forgotten...
  // 1. Touching the screen starts stone placement
  // 2. Stone is placed when finger leaves the screen and the stone is placed
  //    in a valid location
  // 3. Stone placement can be cancelled by placing in an invalid location
  // 4. Invalid locations are: Another stone is already placed on the point;
  //    placing the stone would be suicide; the point is guarded by a Ko; the
  //    point is outside the board; the point is not on the visible area of the
  //    board (if the board is zoomed)
  // 5. While panning/dragging, provide continuous feedback on the current
  //    stone location
  //    - Display a stone of the correct color at the current location
  //    - Mark up the stone differently from already placed stones
  //    - Mark up the stone differently if it is in a valid location, and if
  //      it is in an invalid location
  //    - Display in the status line the vertex of the current location
  //    - If the location is invalid, display the reason in the status line
  //    - If placing a stone would capture other stones, mark up those stones
  //      and display in the status line how many stones would be captured
  //    - If placing a stone would set a group (your own or an enemy group) to
  //      atari, mark up that group
  // 6. Place the stone with an offset to the fingertip position so that the
  //    user can see the stone location

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  BoardViewModel* boardViewModel = appDelegate.boardViewModel;

  CGPoint panningLocation;
  BoardViewIntersection panningIntersection = [self boardViewIntersectionForGestureLocation:gestureRecognizer
                                                                            panningLocation:&panningLocation];

  if (! BoardViewIntersectionIsNullIntersection(panningIntersection))
  {
    CGRect visibleRect = self.boardView.bounds;
    // Don't use panningLocation for this check because the cross-hair center
    // is offset due to the snapping mechanism of the intersectionNear:()
    // method
    bool isPanningIntersectionInVisibleRect = CGRectContainsPoint(visibleRect, panningIntersection.coordinates);
    if (! isPanningIntersectionInVisibleRect)
    {
      panningIntersection = BoardViewIntersectionNull;
    }
  }

  static int gestureRecognizerStateChangedCount = 0;

  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  switch (recognizerState)
  {
    case UIGestureRecognizerStateBegan:
    {
      gestureRecognizerStateChangedCount = 0;
      DDLogDebug(@"UIGestureRecognizerStateBegan");

      [LayoutManager sharedManager].shouldAutorotate = false;

      boardViewModel.boardViewPanningGestureIsInProgress = true;
      [[NSNotificationCenter defaultCenter] postNotificationName:boardViewPanningGestureWillStart object:nil];

      self.gestureStartPoint = panningIntersection.point;
      self.gestureMostRecentPoint = panningIntersection.point;

      [self.panGestureHandler handleGestureWithGestureRecognizerState:recognizerState
                                                    gestureStartPoint:self.gestureStartPoint
                                                  gestureCurrentPoint:panningIntersection.point];

      break;
    }
    case UIGestureRecognizerStateChanged:
    {
      if (gestureRecognizerStateChangedCount % 200 == 0)
        DDLogDebug(@"UIGestureRecognizerStateChanged, gestureRecognizerStateChangedCount = %d", gestureRecognizerStateChangedCount);
      ++gestureRecognizerStateChangedCount;

      if (self.gestureMostRecentPoint != panningIntersection.point)
      {
        self.gestureMostRecentPoint = panningIntersection.point;
        [self.panGestureHandler handleGestureWithGestureRecognizerState:recognizerState
                                                      gestureStartPoint:self.gestureStartPoint
                                                    gestureCurrentPoint:panningIntersection.point];
      }

      break;
    }
    case UIGestureRecognizerStateEnded:
    // Occurs, for instance, if an alert is displayed while a gesture is
    // being handled, or if the gesture recognizer was disabled.
    case UIGestureRecognizerStateCancelled:
    {
      if (recognizerState == UIGestureRecognizerStateEnded)
        DDLogDebug(@"UIGestureRecognizerStateEnded");
      else
        DDLogDebug(@"UIGestureRecognizerStateCancelled");

      [self.panGestureHandler handleGestureWithGestureRecognizerState:recognizerState
                                                    gestureStartPoint:self.gestureStartPoint
                                                  gestureCurrentPoint:panningIntersection.point];

      self.gestureStartPoint = nil;
      self.gestureMostRecentPoint = nil;

      [LayoutManager sharedManager].shouldAutorotate = true;

      boardViewModel.boardViewPanningGestureIsInProgress = false;
      [[NSNotificationCenter defaultCenter] postNotificationName:boardViewPanningGestureWillEnd object:nil];

      break;
    }
    default:
    {
      DDLogDebug(@"handlePanFrom, unhandled recognizerState = %ld", (long)recognizerState);

      break;
    }
  }

  // Perform magnifying glass handling only after the Go board graphics changes
  // have been queued
  [self handleMagnifyingGlassForPanningLocation:panningLocation
                            panningIntersection:panningIntersection];
}

// -----------------------------------------------------------------------------
/// @brief UIGestureRecognizerDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
  if (! self.isPanningEnabled)
    return NO;

  // Begin the gesture only when it's near a valid intersection. This is
  // important for some markup editing tools (e.g. connections) that need a
  // starting intersection to which the gesture can be anchored.
  BoardViewIntersection startingIntersection = [self boardViewIntersectionForGestureLocation:gestureRecognizer
                                                                             panningLocation:nil];
  if (BoardViewIntersectionIsNullIntersection(startingIntersection))
    return NO;

  BOOL gestureRecognizerShouldBegin = [self.panGestureHandler gestureRecognizerShouldBegin:gestureRecognizer
                                                                         gestureStartPoint:startingIntersection.point];
  return gestureRecognizerShouldBegin;
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  [self removeBoardPositionObserver:oldGame.boardPosition];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  [self setupBoardPositionObserver:newGame.boardPosition];
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #uiAreaPlayModeDidChange notification.
// -----------------------------------------------------------------------------
- (void) uiAreaPlayModeDidChange:(NSNotification*)notification
{
  [self updatePanningEnabled];
  [self updatePanGestureHandler];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationWillBegin notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationWillBegin:(NSNotification*)notification
{
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationDidEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationDidEnd:(NSNotification*)notification
{
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if (object == [GoGame sharedGame].boardPosition)
  {
    [self cancelPanningInProgress];
    [self updatePanningEnabled];
  }
  else if ([keyPath isEqualToString:@"markupTool"])
  {
    [self cancelPanningInProgress];
    [self updatePanningEnabled];
    [self updatePanGestureHandler];
  }
}

#pragma mark - Updaters

// -----------------------------------------------------------------------------
/// @brief Updates whether panning is enabled.
// -----------------------------------------------------------------------------
- (void) updatePanningEnabled
{
  GoGame* game = [GoGame sharedGame];
  if (! game)
  {
    self.panningEnabled = false;
    return;
  }

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];

  enum UIAreaPlayMode uiAreaPlayMode = appDelegate.uiSettingsModel.uiAreaPlayMode;
  if (uiAreaPlayMode == UIAreaPlayModeEditMarkup)
  {
    self.panningEnabled = true;
    return;
  }
  else if (uiAreaPlayMode != UIAreaPlayModePlay)
  {
    self.panningEnabled = false;
    return;
  }

  if (appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    self.panningEnabled = false;
    return;
  }

  if (GoGameTypeComputerVsComputer == game.type)
  {
    self.panningEnabled = false;
    return;
  }

  if (GoGameStateGameHasEnded == game.state)
  {
    if (! [GoUtilities nodeWithNextMoveExists:game.boardPosition.currentNode])
    {
      self.panningEnabled = false;
      return;
    }
  }

  // We get here in two cases
  // 1) The game is still in progress
  // 2) The game has ended, but the user is viewing a board position that does
  //    not reflect the last move of the game
  if (game.isComputerThinking)
    self.panningEnabled = false;
  else if (game.nextMovePlayerIsComputerPlayer)
    self.panningEnabled = false;
  else
    self.panningEnabled = true;
}

// -----------------------------------------------------------------------------
/// @brief Updates the handler whether panning is enabled.
// -----------------------------------------------------------------------------
- (void) updatePanGestureHandler
{
  if (self.boardView)
  {
    ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
    self.panGestureHandler = [PanGestureHandler panGestureHandlerWithUiAreaPlayMode:appDelegate.uiSettingsModel.uiAreaPlayMode
                                                                         markupTool:appDelegate.markupModel.markupTool
                                                                        markupModel:appDelegate.markupModel
                                                                          boardView:self.boardView
                                                                   boardViewMetrics:appDelegate.boardViewMetrics];
  }
  else
  {
    self.panGestureHandler = nil;
  }
}

#pragma mark - Magnifying glass handling

// -----------------------------------------------------------------------------
/// @brief Performs magnifying glass handling according to the current user
/// defaults. If the magnifying glass is enabled, the center of magnification is
/// either at @a panningLocation or at the coordinate represented by
/// @a panningIntersection
// -----------------------------------------------------------------------------
- (void) handleMagnifyingGlassForPanningLocation:(CGPoint)panningLocation
                             panningIntersection:(BoardViewIntersection)panningIntersection
{
  MagnifyingViewModel* magnifyingViewModel = [ApplicationDelegate sharedDelegate].magnifyingViewModel;
  switch (magnifyingViewModel.enableMode)
  {
    case MagnifyingGlassEnableModeAlwaysOn:
      break;
    case MagnifyingGlassEnableModeAlwaysOff:
      return;
    case MagnifyingGlassEnableModeAuto:
      if ([ApplicationDelegate sharedDelegate].boardViewMetrics.cellWidth >= magnifyingViewModel.autoThreshold)
        return;
      break;
    default:
      [ExceptionUtility throwNotImplementedException];
      break;
  }

  switch (magnifyingViewModel.updateMode)
  {
    case MagnifyingGlassUpdateModeSmooth:
      if ([ApplicationDelegate sharedDelegate].boardViewModel.boardViewPanningGestureIsInProgress)
        [self updateMagnifyingGlassForPanningLocation:panningLocation];
      else
        [self disableMagnifyingGlass];
      break;
    case MagnifyingGlassUpdateModeIntersection:
      if (BoardViewIntersectionIsNullIntersection(panningIntersection))
        [self disableMagnifyingGlass];
      else
        [self updateMagnifyingGlassForPanningIntersection:panningIntersection];
    default:
      [ExceptionUtility throwNotImplementedException];
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief Enables the magnifying glass if it is not currently enabled, then
/// updates the magnifying glass so that it displays the content around the
/// center of magnification that is equal to @a panningLocation.
// -----------------------------------------------------------------------------
- (void) updateMagnifyingGlassForPanningLocation:(CGPoint)panningLocation
{
  id<MagnifyingGlassOwner> magnifyingGlassOwner = [MainUtility magnifyingGlassOwner];
  if (! magnifyingGlassOwner.magnifyingGlassEnabled)
  {
    DDLogDebug(@"Enabling magnifying glass for panning location, owner = %@", magnifyingGlassOwner);

    [magnifyingGlassOwner enableMagnifyingGlass:self];
  }
  MagnifyingViewController* magnifyingViewController = magnifyingGlassOwner.magnifyingViewController;
  [magnifyingViewController updateMagnificationCenter:panningLocation inView:self.boardView];
}

// -----------------------------------------------------------------------------
/// @brief Enables the magnifying glass if it is not currently enabled, then
/// updates the magnifying glass so that it displays the content around the
/// center of magnification that is at the coordinate represented by
/// @a panningIntersection.
// -----------------------------------------------------------------------------
- (void) updateMagnifyingGlassForPanningIntersection:(BoardViewIntersection)panningIntersection
{
  id<MagnifyingGlassOwner> magnifyingGlassOwner = [MainUtility magnifyingGlassOwner];
  if (! magnifyingGlassOwner.magnifyingGlassEnabled)
  {
    DDLogDebug(@"Enabling magnifying glass for panning intersection, owner = %@", magnifyingGlassOwner);

    [magnifyingGlassOwner enableMagnifyingGlass:self];
  }
  MagnifyingViewController* magnifyingViewController = magnifyingGlassOwner.magnifyingViewController;
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  CGPoint magnificationCenter = [metrics coordinatesFromPoint:panningIntersection.point];
  [magnifyingViewController updateMagnificationCenter:magnificationCenter inView:self.boardView];
}

// -----------------------------------------------------------------------------
/// @brief Disables (= hides) the magnifying glass.
// -----------------------------------------------------------------------------
- (void) disableMagnifyingGlass
{
  id<MagnifyingGlassOwner> magnifyingGlassOwner = [MainUtility magnifyingGlassOwner];
  if (magnifyingGlassOwner.magnifyingGlassEnabled)
  {
    DDLogDebug(@"Disabling magnifying glass, owner = %@", magnifyingGlassOwner);

    [magnifyingGlassOwner disableMagnifyingGlass];
  }
}

#pragma mark - MagnifyingViewControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief MagnifyingViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (MagnifyingViewModel*) magnifyingViewControllerModel:(MagnifyingViewController*)magnifyingViewController;
{
  return [ApplicationDelegate sharedDelegate].magnifyingViewModel;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Cancels a panning gesture that is currently in progress.
// -----------------------------------------------------------------------------
- (void) cancelPanningInProgress
{
  self.longPressRecognizer.enabled = NO;
  self.longPressRecognizer.enabled = YES;
}

// -----------------------------------------------------------------------------
/// @brief Returns the BoardViewIntersection that is nearest to the gesture
/// recognizer's current location.
// -----------------------------------------------------------------------------
- (BoardViewIntersection) boardViewIntersectionForGestureLocation:(UIGestureRecognizer*)gestureRecognizer
                                                  panningLocation:(CGPoint*)panningLocation
{
  CGPoint gestureLocation = [gestureRecognizer locationInView:self.boardView];
  if (panningLocation)
    *panningLocation = gestureLocation;
  BoardViewIntersection intersectionNearGestureLocation = [self.boardView intersectionNear:gestureLocation];
  return intersectionNearGestureLocation;
}

@end
