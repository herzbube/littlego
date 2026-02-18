// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
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
#import "TimeViewController.h"
#import "TimeView.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoClock.h"
#import "../../go/GoGame.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeTimeData.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPlayerTimeData.h"
#import "../../go/GoTimeDataValidator.h"
#import "../../go/GoTimeSettings.h"
#import "../../go/GoTimeSystem.h"
#import "../../main/Registry.h"
#import "../../play/timedplay/PlayerClockService.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/ExceptionUtility.h"


// This variable must be accessed via [TimeViewController timeViewControllerClockViewSize]
static CGSize timeViewControllerClockViewSize = { 0.0f, 0.0f };


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TimeViewController.
// -----------------------------------------------------------------------------
@interface TimeViewController()
@property(nonatomic, assign) bool clockViewMode;
@property(nonatomic, retain) TimeView* timeViewBlackPlayer;
@property(nonatomic, retain) TimeView* timeViewWhitePlayer;
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizerTimeViewBlackPlayer;
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizerTimeViewWhitePlayer;
@property(nonatomic, assign) bool timeDataNeedsUpdate;
@property(nonatomic, assign) bool blackPlayerClockStateNeedsUpdate;
@property(nonatomic, assign) bool whitePlayerClockStateNeedsUpdate;
@property(nonatomic, assign) bool blackPlayerTimeDataNeedsUpdate;
@property(nonatomic, assign) bool whitePlayerTimeDataNeedsUpdate;
@property(nonatomic, assign) bool isTimeDataValid;
@property(nonatomic, assign) bool timeDataValidityNeedsUpdate;
@property(nonatomic, retain) TimeView* timeViewNodeTimeData;
@property(nonatomic, assign) bool nodeTimeDataNeedsUpdate;
@end


@implementation TimeViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a TimeViewController object that operates in
/// "clock view" mode.
// -----------------------------------------------------------------------------
- (id) initWithClockView
{
  return [self initWithMode:true];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a TimeViewController object that operates in
/// "node time data view" mode.
// -----------------------------------------------------------------------------
- (id) initWithNodeTimeDataView
{
  return [self initWithMode:false];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a TimeViewController object that operates either in
/// "clock view" mode (@a clockViewMode is true) or in "node time data view"
/// mode (@a clockViewMode is false).
///
/// @note This is the designated initializer of TimeViewController.
// -----------------------------------------------------------------------------
- (id) initWithMode:(bool)clockViewMode
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.clockViewMode = clockViewMode;

  self.timeViewBlackPlayer = nil;
  self.timeViewWhitePlayer = nil;
  self.tapRecognizerTimeViewBlackPlayer = nil;
  self.tapRecognizerTimeViewWhitePlayer = nil;

  self.timeDataNeedsUpdate = false;
  self.blackPlayerClockStateNeedsUpdate = false;
  self.whitePlayerClockStateNeedsUpdate = false;
  self.blackPlayerTimeDataNeedsUpdate = false;
  self.whitePlayerTimeDataNeedsUpdate = false;
  self.isTimeDataValid = false;
  self.timeDataValidityNeedsUpdate = false;

  self.timeViewNodeTimeData = nil;
  self.nodeTimeDataNeedsUpdate = false;

  [self setupNotificationResponders];
  [self initializeWithGoModelData];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TimeViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  
  self.timeViewBlackPlayer = nil;
  self.timeViewWhitePlayer = nil;
  self.tapRecognizerTimeViewBlackPlayer = nil;
  self.tapRecognizerTimeViewWhitePlayer = nil;

  self.timeViewNodeTimeData = nil;

  [super dealloc];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(timeDataDidBecomeValid:) name:timeDataDidBecomeValid object:nil];
  [center addObserver:self selector:@selector(timeDataDidBecomeInvalid:) name:timeDataDidBecomeInvalid object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  if (self.clockViewMode)
  {
    [center addObserver:self selector:@selector(playerClockStateHasChanged:) name:playerClockStateHasChanged object:nil];
    [center addObserver:self selector:@selector(playerTimeDataHasChanged:) name:playerTimeDataHasChanged object:nil];
  }
  else
  {
    [center addObserver:self selector:@selector(currentBoardPositionDidChange:) name:currentBoardPositionDidChange object:nil];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self setupViewHierarchy];
  [self configureView];
  [self setupAutoLayoutConstraints];

  // This controller can be instantiated in response to goGameDidCreate. In
  // that case it will miss goGameDidCreate, so to make sure the views are
  // properly initialized we have to trigger a full update here.
  self.timeDataNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection*)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle &&
      self.clockViewMode)
  {
    [self updateColors];
  }
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Sets up the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  if (self.clockViewMode)
  {
    self.timeViewBlackPlayer = [[[TimeView alloc] initWithFrame:CGRectZero isTimeDataForBlackPlayer:true] autorelease];
    self.timeViewWhitePlayer = [[[TimeView alloc] initWithFrame:CGRectZero isTimeDataForBlackPlayer:false] autorelease];

    [self.view addSubview:self.timeViewBlackPlayer];
    [self.view addSubview:self.timeViewWhitePlayer];
  }
  else
  {
    self.timeViewNodeTimeData = [[[TimeView alloc] initWithFrame:CGRectZero] autorelease];
    [self.view addSubview:self.timeViewNodeTimeData];
  }
}

// -----------------------------------------------------------------------------
/// @brief Configures the view and its elements.
// -----------------------------------------------------------------------------
- (void) configureView
{
  if (self.clockViewMode)
  {
    self.timeViewBlackPlayer.userInteractionEnabled = YES;
    self.tapRecognizerTimeViewBlackPlayer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)] autorelease];
    [self.timeViewBlackPlayer addGestureRecognizer:self.tapRecognizerTimeViewBlackPlayer];

    self.timeViewWhitePlayer.userInteractionEnabled = YES;
    self.tapRecognizerTimeViewWhitePlayer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)] autorelease];
    [self.timeViewWhitePlayer addGestureRecognizer:self.tapRecognizerTimeViewWhitePlayer];

    [self updateColors];
  }
  else
  {
    self.timeViewNodeTimeData.userInteractionEnabled = NO;
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets up the Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  if (self.clockViewMode)
    [self setupAutoLayoutConstraintsClockViewMode];
  else
    [self setupAutoLayoutConstraintsNodeTimeDataViewMode];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the Auto Layout constraints when this controller operates in
/// "clock view" mode.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsClockViewMode
{
  // IMPORTANT: If you change anything about these constraints, make sure that
  // the calculation in timeViewControllerClockViewSize remains aligned.

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.timeViewBlackPlayer.translatesAutoresizingMaskIntoConstraints = NO;
  self.timeViewWhitePlayer.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"timeViewBlackPlayer"] = self.timeViewBlackPlayer;
  viewsDictionary[@"timeViewWhitePlayer"] = self.timeViewWhitePlayer;

  CGFloat horizontalSpacingSiblings = [AutoLayoutUtility horizontalSpacingSiblings];
  CGFloat horizontalSpacingSuperview = [AutoLayoutUtility horizontalSpacingSuperview];
  CGFloat verticalSpacingSuperview = [AutoLayoutUtility verticalSpacingSuperview];

  [visualFormats addObject:[NSString stringWithFormat:@"H:|-%f-[timeViewBlackPlayer]-%f-[timeViewWhitePlayer]-%f-|", horizontalSpacingSuperview, horizontalSpacingSiblings, horizontalSpacingSuperview]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-%f-[timeViewBlackPlayer]-%f-|", verticalSpacingSuperview, verticalSpacingSuperview]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-%f-[timeViewWhitePlayer]-%f-|", verticalSpacingSuperview, verticalSpacingSuperview]];

  CGSize timeViewSize = [TimeView timeViewSize];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[timeViewBlackPlayer(==%f)]", timeViewSize.width]];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[timeViewWhitePlayer(==%f)]", timeViewSize.width]];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the Auto Layout constraints when this controller operates in
/// "node time data view" mode.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsNodeTimeDataViewMode
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.timeViewNodeTimeData.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"timeViewNodeTimeData"] = self.timeViewNodeTimeData;

  CGFloat horizontalSpacingSuperview = [AutoLayoutUtility horizontalSpacingSuperview];
  CGFloat verticalSpacingSuperview = [AutoLayoutUtility verticalSpacingSuperview];

  [visualFormats addObject:[NSString stringWithFormat:@"H:|-%f-[timeViewNodeTimeData]-%f-|", horizontalSpacingSuperview, horizontalSpacingSuperview]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-%f-[timeViewNodeTimeData]-%f-|", verticalSpacingSuperview, verticalSpacingSuperview]];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];
}

#pragma mark - User interface style handling (light/dark mode)

// -----------------------------------------------------------------------------
/// @brief Updates all kinds of colors to match the current
/// UIUserInterfaceStyle (light/dark mode).
// -----------------------------------------------------------------------------
- (void) updateColors
{
  UITraitCollection* traitCollection = self.traitCollection;
  [UiUtilities applyTransparentStyleToView:self.timeViewBlackPlayer traitCollection:traitCollection];
  [UiUtilities applyTransparentStyleToView:self.timeViewWhitePlayer traitCollection:traitCollection];
}

#pragma mark - Gesture handling

// -----------------------------------------------------------------------------
/// @brief Reacts to the time view being tapped.
// -----------------------------------------------------------------------------
- (void) viewTapped:(id)sender
{
  id<PlayerClockService> playerClockService = [Registry sharedRegistry].playerClockService;

  GoGame* game = [GoGame sharedGame];
  GoPlayer* player = (sender == self.tapRecognizerTimeViewBlackPlayer
                      ? game.playerBlack
                      : game.playerWhite);

  switch (player.timeData.clockState)
  {
    case GoClockStateStopped:
      [playerClockService startClockOfPlayer:player
                                      reason:PlayerClockStartReasonUserRequest];
      break;
    case GoClockStateStarted:
      [playerClockService suspendClockOfPlayer:player
                                        reason:PlayerClockSuspendReasonUserRequest];
      break;
    case GoClockStateSuspended:
      [playerClockService startClockOfPlayer:player
                                      reason:PlayerClockStartReasonUserRequest];
      break;
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"Invalid clock state %d"
                                                  argumentValue:player.timeData.clockState];
      break;
  }
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  self.timeDataNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #playerClockStateHasChanged notification.
// -----------------------------------------------------------------------------
- (void) playerClockStateHasChanged:(NSNotification*)notification
{
  GoPlayerTimeData* playerTimeData = notification.object;
  if (playerTimeData.isTimeDataForBlackPlayer)
    self.blackPlayerClockStateNeedsUpdate = true;
  else
    self.whitePlayerClockStateNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #playerTimeDataHasChanged notification.
// -----------------------------------------------------------------------------
- (void) playerTimeDataHasChanged:(NSNotification*)notification
{
  GoPlayerTimeData* playerTimeData = notification.object;
  if (playerTimeData.isTimeDataForBlackPlayer)
    self.blackPlayerTimeDataNeedsUpdate = true;
  else
    self.whitePlayerTimeDataNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #timeDataDidBecomeValid notification.
// -----------------------------------------------------------------------------
- (void) timeDataDidBecomeValid:(NSNotification*)notification
{
  self.isTimeDataValid = true;
  self.timeDataValidityNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #timeDataDidBecomeInvalid notification.
// -----------------------------------------------------------------------------
- (void) timeDataDidBecomeInvalid:(NSNotification*)notification
{
  self.isTimeDataValid = false;
  self.timeDataValidityNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #currentBoardPositionDidChange notification.
// -----------------------------------------------------------------------------
- (void) currentBoardPositionDidChange:(NSNotification*)notification
{
  self.nodeTimeDataNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

#pragma mark - Updaters

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;

  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(delayedUpdate) withObject:nil waitUntilDone:YES];
    return;
  }

  // Must be invoked first because it sets "needs update" flags for other
  // updaters
  [self updateTimeData];

  if (self.clockViewMode)
  {
    [self updateBlackPlayerClockState];
    [self updateWhitePlayerClockState];
    [self updateBlackPlayerTimeData];
    [self updateWhitePlayerTimeData];
  }
  else
  {
    [self updateNodeTimeData];
  }

  [self updateTimeDataValidity];
}

// -----------------------------------------------------------------------------
/// @brief Updates all TimeView instances shown by this controller to completely
/// refresh the data they display.
// -----------------------------------------------------------------------------
- (void) updateTimeData
{
  if (! self.timeDataNeedsUpdate)
    return;
  self.timeDataNeedsUpdate = false;

  if (self.clockViewMode)
  {
    self.blackPlayerClockStateNeedsUpdate = true;
    self.whitePlayerClockStateNeedsUpdate = true;
    self.blackPlayerTimeDataNeedsUpdate = true;
    self.whitePlayerTimeDataNeedsUpdate = true;
  }
  else
  {
    self.nodeTimeDataNeedsUpdate = true;
  }

  self.timeDataValidityNeedsUpdate = true;
}

// -----------------------------------------------------------------------------
/// @brief Updates the TimeView for the black player to display the black
/// player's current clock state.
// -----------------------------------------------------------------------------
- (void) updateBlackPlayerClockState
{
  if (! self.blackPlayerClockStateNeedsUpdate)
    return;
  self.blackPlayerClockStateNeedsUpdate = false;

  GoGame* game = [GoGame sharedGame];
  GoPlayerTimeData* playerTimeData = game.playerBlack.timeData;
  [self updateClockStateInTimeView:self.timeViewBlackPlayer withPlayerTimeData:playerTimeData];
}

// -----------------------------------------------------------------------------
/// @brief Updates the TimeView for the white player to display the white
/// player's current clock state.
// -----------------------------------------------------------------------------
- (void) updateWhitePlayerClockState
{
  if (! self.whitePlayerClockStateNeedsUpdate)
    return;
  self.whitePlayerClockStateNeedsUpdate = false;

  GoGame* game = [GoGame sharedGame];
  GoPlayerTimeData* playerTimeData = game.playerWhite.timeData;
  [self updateClockStateInTimeView:self.timeViewWhitePlayer withPlayerTimeData:playerTimeData];
}

// -----------------------------------------------------------------------------
/// @brief Updates the TimeView for the black player to display the black
/// player's current time data.
// -----------------------------------------------------------------------------
- (void) updateBlackPlayerTimeData
{
  if (! self.blackPlayerTimeDataNeedsUpdate)
    return;
  self.blackPlayerTimeDataNeedsUpdate = false;

  GoGame* game = [GoGame sharedGame];
  GoPlayerTimeData* playerTimeData = game.playerBlack.timeData;
  [self updateTimeDataInTimeView:self.timeViewBlackPlayer withPlayerTimeData:playerTimeData];
}

// -----------------------------------------------------------------------------
/// @brief Updates the TimeView for the white player to display the white
/// player's current time data.
// -----------------------------------------------------------------------------
- (void) updateWhitePlayerTimeData
{
  if (! self.whitePlayerTimeDataNeedsUpdate)
    return;
  self.whitePlayerTimeDataNeedsUpdate = false;

  GoGame* game = [GoGame sharedGame];
  GoPlayerTimeData* playerTimeData = game.playerWhite.timeData;
  [self updateTimeDataInTimeView:self.timeViewWhitePlayer withPlayerTimeData:playerTimeData];
}

// -----------------------------------------------------------------------------
/// @brief Updates the TimeView that displays the currently selected node's
/// time data.
// -----------------------------------------------------------------------------
- (void) updateNodeTimeData
{
  if (! self.nodeTimeDataNeedsUpdate)
    return;
  self.nodeTimeDataNeedsUpdate = false;

  GoGame* game = [GoGame sharedGame];
  [self updateTimeDataInTimeView:self.timeViewNodeTimeData
                withNodeTimeData:game.boardPosition.currentNode
                    timeSettings:game.timeSettings];
}

// -----------------------------------------------------------------------------
/// @brief Updates all TimeView instances shown by this controller to either
/// display their normal time data (if time data is valid), or a special string
/// indicating that time data is invalid.
// -----------------------------------------------------------------------------
- (void) updateTimeDataValidity
{
  if (! self.timeDataValidityNeedsUpdate)
    return;
  self.timeDataValidityNeedsUpdate = false;

  if (self.clockViewMode)
  {
    self.timeViewBlackPlayer.isTimeDataValid = self.isTimeDataValid;
    self.timeViewWhitePlayer.isTimeDataValid = self.isTimeDataValid;
  }
  else
  {
    self.timeViewNodeTimeData.isTimeDataValid = self.isTimeDataValid;
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates @a timeView to display the clock state taken from
/// @a playerTimeData.
// -----------------------------------------------------------------------------
- (void) updateClockStateInTimeView:(TimeView*)timeView
                 withPlayerTimeData:(GoPlayerTimeData*)playerTimeData
{
  timeView.clockState = playerTimeData.clockState;
}

// -----------------------------------------------------------------------------
/// @brief Updates @a timeView to display the time data taken from
/// @a playerTimeData.
// -----------------------------------------------------------------------------
- (void) updateTimeDataInTimeView:(TimeView*)timeView
               withPlayerTimeData:(GoPlayerTimeData*)playerTimeData
{
  timeView.timeSystemType = playerTimeData.effectiveTimeSystemType;
  timeView.remainingTimeInSeconds = playerTimeData.remainingTimeInSeconds;
  timeView.remainingNumberOfMovesOrPeriods = playerTimeData.remainingNumberOfMovesOrPeriods;
}

// -----------------------------------------------------------------------------
/// @brief Updates @a timeView to display the time data taken from
/// @a playerTimeData.
// -----------------------------------------------------------------------------
- (void) updateTimeDataInTimeView:(TimeView*)timeView
                 withNodeTimeData:(GoNode*)node
                     timeSettings:(GoTimeSettings*)timeSettings
{
  GoNodeTimeData* nodeTimeData = node.goNodeTimeData;
  if (nodeTimeData)
  {
    timeView.showsTimeData = true;
    timeView.isTimeDataForBlackPlayer = nodeTimeData.isTimeDataForBlackPlayer;
    timeView.isTimeDataValid = node.isTimeDataValid;
    timeView.timeSystemType = (nodeTimeData.isRemainingTimeAbsoluteTime
                               ? timeSettings.absoluteTimeSystem.goTimeSystemType
                               : timeSettings.periodBasedTimeSystem.goTimeSystemType);
    timeView.remainingTimeInSeconds = nodeTimeData.remainingTimeInSeconds;
    if (nodeTimeData.isRemainingTimeAbsoluteTime)
      timeView.remainingNumberOfMovesOrPeriods = 0;
    else if (timeSettings.periodBasedTimeSystem.goTimeSystemType == GoTimeSystemTypeJapanese)
      timeView.remainingNumberOfMovesOrPeriods = nodeTimeData.remainingNumberOfPeriods;
    else
      timeView.remainingNumberOfMovesOrPeriods = nodeTimeData.remainingNumberOfMoves;
  }
  else
  {
    timeView.showsTimeData = false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Initializes some properties of this controller with current Go model
/// data.
///
/// The instance of this controller that shows the player clocks is created on
/// demand when a game is created that supports timed play. This controller
/// instance may miss some notifications that have already been sent before it
/// was created. This method is a somewhat ugly hack to initialize properties
/// that may have the wrong values because of the missed notifications.
// -----------------------------------------------------------------------------
- (void) initializeWithGoModelData
{
  GoGame* game = [GoGame sharedGame];
  if (! game)
    return;

  // The instance of this controller that shows the player clocks is created in
  // response to goGameDidCreate. Either the game is created with only a root
  // node (completely new game, or game loaded from .sgf), or the game is
  // created with a full node tree (unarchive) with the current board position
  // set up correctly. In all cases the current board position must hold the
  // correct time data validity. If the current board position changes later on,
  // we will get a time validity notification.
  GoTimeDataValidationResult validationState = [GoTimeDataValidator validationStateOfCurrentNode:game];
  self.isTimeDataValid = validationState.isTimeDataValid;
}

#pragma mark - One-time view size calculation

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
+ (CGSize) timeViewControllerClockViewSize
{
  if (CGSizeEqualToSize(timeViewControllerClockViewSize, CGSizeZero))
  {
    CGSize timeViewSize = [TimeView timeViewSize];
    CGFloat horizontalSpacingSiblings = [AutoLayoutUtility horizontalSpacingSiblings];
    CGFloat horizontalSpacingSuperview = [AutoLayoutUtility horizontalSpacingSuperview];
    CGFloat verticalSpacingSuperview = [AutoLayoutUtility verticalSpacingSuperview];

    // Aligned to setupAutoLayoutConstraints()
    timeViewControllerClockViewSize = CGSizeMake(2 * horizontalSpacingSuperview + 2 * timeViewSize.width + horizontalSpacingSiblings,
                                                 2 * verticalSpacingSuperview + timeViewSize.height);
  }

  return timeViewControllerClockViewSize;
}

@end
