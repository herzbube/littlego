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
#import "BoardAnimationController.h"
#import "BoardView.h"
#import "StoneView.h"
#import "layer/BoardViewDrawingHelper.h"
#import "../model/BoardViewModel.h"
#import "../../go/GoPoint.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/UIViewControllerAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardAnimationController.
// -----------------------------------------------------------------------------
@interface BoardAnimationController()
@end


@implementation BoardAnimationController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardAnimationController object.
///
/// @note This is the designated initializer of BoardAnimationController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.boardView = nil;

  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.boardView = nil;
  [super dealloc];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(computerPlayerGeneratedMoveSuggestion:) name:computerPlayerGeneratedMoveSuggestion object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center removeObserver:self];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Handles the event that the computer player generated a move
/// suggestion. @a notification contains the move suggestion data.
///
/// @see #computerPlayerGeneratedMoveSuggestion.
// -----------------------------------------------------------------------------
- (void) computerPlayerGeneratedMoveSuggestion:(NSNotification*)notification
{
  if (! self.boardView)
    return;

  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(computerPlayerGeneratedMoveSuggestion:) withObject:notification waitUntilDone:YES];
    return;
  }

  // Unpack notification data
  NSDictionary* dictionary = notification.userInfo;
  NSNumber* colorAsNumber = dictionary[moveSuggestionColorKey];
  enum GoColor color = colorAsNumber.intValue;
  NSNumber* moveSuggestionTypeAsNumber = dictionary[moveSuggestionTypeKey];
  enum MoveSuggestionType moveSuggestionType = moveSuggestionTypeAsNumber.intValue;
  id pointAsObject = dictionary[moveSuggestionPointKey];
  GoPoint* point = (pointAsObject == [NSNull null] ? nil : pointAsObject);
  id errorMessageAsObject = dictionary[moveSuggestionErrorMessageKey];
  NSString* errorMessage = (errorMessageAsObject == [NSNull null] ? nil : errorMessageAsObject);

  NSString* alertTitle = @"Move suggestion";
  NSString* alertMessage;

  if (errorMessage)
  {
    alertMessage = errorMessage;
  }
  else
  {
    if (moveSuggestionType == MoveSuggestionTypePass)
      alertMessage = @"The computer suggests to pass.";
    else if (moveSuggestionType == MoveSuggestionTypeResign)
      alertMessage = @"The computer suggests to resign.";
    else
      alertMessage = nil;
  }

  if (alertMessage)
  {
    [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:alertTitle
                                                                                    message:alertMessage];
  }
  else
  {
    BoardViewMetrics* boardViewMetrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
    CGRect stoneRect = [BoardViewDrawingHelper canvasRectForStoneAtPoint:point
                                                                 metrics:boardViewMetrics];

    // Add the view to the BoardView's tileContainerView, which represents the
    // entire canvas. We can't add the view to the BoardView itself because
    // while zoomed a transform is in effect on the tileContainerView which
    // causes the frame of the tileContainerView to be enlarged by the current
    // zoom scale.
    StoneView* stoneView = [[[StoneView alloc] initWithFrame:stoneRect stoneColor:color metrics:boardViewMetrics] autorelease];
    stoneView.userInteractionEnabled = NO;

    [self.boardView.tileContainerView addSubview:stoneView];

    BoardViewModel* boardViewModel = [ApplicationDelegate sharedDelegate].boardViewModel;
    boardViewModel.boardViewDisplaysAnimation = true;
    [[NSNotificationCenter defaultCenter] postNotificationName:boardViewAnimationWillBegin object:nil];
    [self blinkView:stoneView repeatCount:moveSuggestionAnimationRepeatCount completionHandler:^
    {
      // The completion handler is also invoked if the animation ends
      // prematurely, e.g. due to interface orientation change or the board
      // view becoming hidden (tab bar switch, main menu being presented).
      // Zooming and scrolling does not end the animation.

      [stoneView removeFromSuperview];
      boardViewModel.boardViewDisplaysAnimation = false;
      [[NSNotificationCenter defaultCenter] postNotificationName:boardViewAnimationDidEnd object:nil];
    }];
  }
}

#pragma mark - Animation handlers

// -----------------------------------------------------------------------------
/// @brief Performs a blink animation on @a view. Repeats the animation
/// @a repeatCount number of times. Invokes @a completionHandler when all
/// animations have finished.
///
/// The blink animation works by manipulating the @e alpha property of
/// @a blinkView. The animation is implemented using keyframes:
///
/// ---A----B----C----D----E------------------> t
///    ^    ^    ^    ^    ^
///    |    |    |    |    +-- View is still transparent
///    |    |    |    +-- View is transparent again
///    |    |    +-- View is still opaque
///    |    +-- View is opaque
///    +-- View is transparent
///
/// - From A to B the view becomes opaque. B is keyframe 1.
/// - From B to C the view remains opaque
/// - From C to D the view becomes transparent again. D is keyframe 2.
/// - From D to E the view remains transparent
// -----------------------------------------------------------------------------
- (void) blinkView:(UIView*)blinkView
       repeatCount:(unsigned int)repeatCount
 completionHandler:(void (^)(void))completionHandler
{
  // These are absolute numbers in seconds that define when each part of the
  // animation begins and how long its duration is. These numbers have been
  // determined experimentally to look good.
  double startMakeOpaque = 0.0;
  double durationMakeOpaque = 0.1;
  double startRemainOpaque = startMakeOpaque + durationMakeOpaque;
  double durationRemainOpaque = 0.5;
  double startMakeTransparent = startRemainOpaque + durationRemainOpaque;
  double durationMakeTransparent = 0.2;
  //double startRemainTransparent = startMakeTransparent + durationMakeTransparent;
  double durationRemainTransparent = 0.5;
  double durationTotal = durationMakeOpaque + durationRemainOpaque + durationMakeTransparent + durationRemainTransparent;

  double relativeDurationMakeOpaque = durationMakeOpaque / durationTotal;
  double relativeStartMakeOpaque = startMakeOpaque / durationTotal;
  double relativeDurationMakeTransparent = durationMakeTransparent / durationTotal;
  double relativeStartMakeTransparent = startMakeTransparent / durationTotal;

  double alphaOpaque = 1.0;
  double alphaTransparent = 0.0;

  blinkView.alpha = alphaTransparent;

  void (^animations) (void) = ^()
  {
    [UIView addKeyframeWithRelativeStartTime:relativeStartMakeOpaque relativeDuration:relativeDurationMakeOpaque animations:^{
      blinkView.alpha = alphaOpaque;
    }];

    [UIView addKeyframeWithRelativeStartTime:relativeStartMakeTransparent relativeDuration:relativeDurationMakeTransparent animations:^{
      blinkView.alpha = alphaTransparent;
    }];
  };

  int remainingAnimations = repeatCount;
  [self animateKeyframesWithDuration:durationTotal
                          animations:animations
                         repeatCount:remainingAnimations
                   completionHandler:completionHandler];
}

// -----------------------------------------------------------------------------
/// @brief Sets up a keyframe-based animation. The animation's total duration in
/// seconds is @a duration. The keyframe animations are set up using the block
/// @a animations. Repeats the animation @a repeatCount number of times. Invokes
/// @a completionHandler when all animations have finished.
// -----------------------------------------------------------------------------
- (void) animateKeyframesWithDuration:(double)duration
                           animations:(void (^)(void))animations
                          repeatCount:(unsigned int)repeatCount
                    completionHandler:(void (^)(void))completionHandler
{
  if (repeatCount == 0)
  {
    completionHandler();
    return;
  }

  unsigned int remainingAnimations = repeatCount;
  remainingAnimations--;

  void (^actualCompletionHandler)(BOOL);
  if (remainingAnimations > 0)
  {
    actualCompletionHandler = ^(BOOL finished)
    {
      [self animateKeyframesWithDuration:duration
                              animations:animations
                             repeatCount:remainingAnimations
                       completionHandler:completionHandler];
    };
  }
  else
  {
    actualCompletionHandler = ^(BOOL finished)
    {
      completionHandler();
    };
  }

  [UIView animateKeyframesWithDuration:duration
                                 delay:0.0
                               options:UIViewKeyframeAnimationOptionCalculationModeLinear
                            animations:animations
                            completion:actualCompletionHandler];
}

@end
