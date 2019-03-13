// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardViewAccessibility.h"
#import "BoardView.h"
#import "../model/BoardViewMetrics.h"
#import "../../go/GoGame.h"
#import "../../go/GoBoard.h"
#import "../../go/GoPoint.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../utility/AccessibilityUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardViewAccessibility.
// -----------------------------------------------------------------------------
@interface BoardViewAccessibility()
@property(nonatomic, assign) BoardView* boardView;
// Public property is readonly, we re-declare it here as readwrite
@property(nonatomic, retain) NSArray* accessibilityElements;
@property(nonatomic, assign) bool layoutChangedNotificationNeedsPosting;
@end


@implementation BoardViewAccessibility

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardViewAccessibility object with frame rectangle @a rect.
///
/// @note This is the designated initializer of BoardViewAccessibility.
// -----------------------------------------------------------------------------
- (id) initWithBoardView:(BoardView*)boardView;
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.boardView = boardView;
  self.accessibilityElements = @[];
  self.layoutChangedNotificationNeedsPosting = false;

  [self setupNotificationResponders];

  [self updateAccessibilityElements];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardViewAccessibility object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];

  [super dealloc];
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
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];

  // KVO observing
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  // KVO observing
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  GoBoardPosition* boardPosition = oldGame.boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  GoBoardPosition* boardPosition = newGame.boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:NSKeyValueObservingOptionOld context:NULL];

  self.layoutChangedNotificationNeedsPosting = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"currentBoardPosition"])
  {
    self.layoutChangedNotificationNeedsPosting = true;
    [self delayedUpdate];
  }
  else
  {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark - Updaters

// -----------------------------------------------------------------------------
/// @brief Handles delayed updates.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;

  [self postLayoutChangedNotification];
}

// -----------------------------------------------------------------------------
/// @brief Posts #UIAccessibilityLayoutChangedNotification to the global
/// notification centre. This causes the accessibility layer to request an
/// updated array of UIAccessibilityElement objects from BoardView, which in
/// turn delegates the request to this BoardViewAccessibility.
// -----------------------------------------------------------------------------
- (void) postLayoutChangedNotification
{
  if (! self.layoutChangedNotificationNeedsPosting)
    return;
  self.layoutChangedNotificationNeedsPosting = false;

  // Update the content of the accessibilityElements array. It's important that
  // this happens only once per #UIAccessibilityLayoutChangedNotification. The
  // accessibility layer will request the array many times and expects the array
  // content to remain stable in between requests. Experimentally determined:
  // If the array content changes from one request to the next, only the last
  // array element will become visible to an accessibility client such as a
  // UI test.
  [self updateAccessibilityElements];

  UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

// -----------------------------------------------------------------------------
/// @brief Update the content of the @e accessibilityElements array.
// -----------------------------------------------------------------------------
- (void) updateAccessibilityElements
{
  NSMutableArray* accessibilityElements = [NSMutableArray arrayWithCapacity:0];

  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  if (board)
  {
    BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;

    // Tests use this accessibility element to perform taps on the game board.
    // For this the accessibilityFrame must be set up correctly, see next
    // step.
    UIAccessibilityElement* uiAccessibilityElementLineGrid =
      [AccessibilityUtility uiAccessibilityElementInContainer:self forLineGridWithSize:board.size];
    // Setting this property is documented to automatically set
    // accessibilityFrame.
    // - UI tests perform taps based on the frame of this UIAccessibilityElement
    // - UI tests don't want to deal with paddings or borders! They want to
    //   be able to take the frame size and divide by the number of lines to
    //   arrive at the approximate coordinate to tap on. This means that the
    //   coordinate 0, 0 of the UIAccessibilityElement's frame must
    //   correspond to an intersection.
    // - Since UIAccessibilityElement frames use the same coordinate system
    //   as UIKit, i.e. the origin is in the top-left corner, we use the
    //   coordinates of the top-left intersection as the origin of the
    //   UIAccessibilityElement's frame.
    uiAccessibilityElementLineGrid.accessibilityFrameInContainerSpace = CGRectMake(metrics.topLeftPointX,
                                                                                   metrics.topLeftPointY,
                                                                                   metrics.lineLength,
                                                                                   metrics.lineLength);
    [accessibilityElements addObject:uiAccessibilityElementLineGrid];

    // Tests use this accessibility element to verify that the board has the
    // correct size
    [accessibilityElements addObject:[AccessibilityUtility uiAccessibilityElementInContainer:self forBoardSize:board.size]];

    // Tests use this accessibility element to verify that the correct
    // intersections are marked up as star points
    [accessibilityElements addObject:[AccessibilityUtility uiAccessibilityElementInContainer:self forStarPoints:board.starPoints]];

    // Tests use this accessibility element to verify that the correct
    // intersections are handicap points (the location of the actual handicap
    // stones is not verified with this, though)
    if (game.handicapPoints.count > 0)
      [accessibilityElements addObject:[AccessibilityUtility uiAccessibilityElementInContainer:self forHandicapPoints:game.handicapPoints]];

    // Tests use these accessibility elements to verify that the expected
    // black and white stones are on the board
    NSMutableArray* blackStonePoints = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray* whiteStonePoints = [NSMutableArray arrayWithCapacity:0];

    for (GoPoint* point = [board pointAtCorner:GoBoardCornerBottomLeft]; point != nil; point = point.next)
    {
      if (point.hasStone)
      {
        if (point.blackStone)
          [blackStonePoints addObject:point];
        else
          [whiteStonePoints addObject:point];
      }
    }

    if (blackStonePoints.count > 0)
      [accessibilityElements addObject:[AccessibilityUtility uiAccessibilityElementInContainer:self forStonePoints:blackStonePoints withColor:GoColorBlack]];
    if (whiteStonePoints.count > 0)
      [accessibilityElements addObject:[AccessibilityUtility uiAccessibilityElementInContainer:self forStonePoints:whiteStonePoints withColor:GoColorWhite]];
  }

  self.accessibilityElements = accessibilityElements;
}

@end
