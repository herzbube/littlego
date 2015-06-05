// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardPositionButtonBoxDataSource.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates all buttons that appear in the board position navigation
/// button box, without regard in which section or oder they appear.
///
/// This enumeration exists to simplify controller logic. Using this enumeration
/// allows to write a single switch() statement instead of writing complicated
/// complicated nested switch/if statements.
// -----------------------------------------------------------------------------
enum ButtonID
{
  RewindToStartButtonID,
  PreviousButtonID,
  NextButtonID,
  ForwardToEndButtonID,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionButtonBoxDataSource.
// -----------------------------------------------------------------------------
@interface BoardPositionButtonBoxDataSource()
@property(nonatomic, retain) NSMutableArray* navigationButtons;
@property(nonatomic, retain) NSMutableArray* navigationButtonsBackward;
@property(nonatomic, retain) NSMutableArray* navigationButtonsForward;
@end


@implementation BoardPositionButtonBoxDataSource

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionButtonBoxDataSource object.
///
/// @note This is the designated initializer of
/// BoardPositionButtonBoxDataSource.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.navigationButtons = [NSMutableArray arrayWithCapacity:0];
  self.navigationButtonsBackward = [NSMutableArray arrayWithCapacity:0];
  self.navigationButtonsForward = [NSMutableArray arrayWithCapacity:0];
  [BoardPositionNavigationManager sharedNavigationManager].delegate = self;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionButtonBoxDataSource
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.navigationButtons = nil;
  self.navigationButtonsBackward = nil;
  self.navigationButtonsForward = nil;
  if ([BoardPositionNavigationManager sharedNavigationManager].delegate == self)
    [BoardPositionNavigationManager sharedNavigationManager].delegate = nil;
  [super dealloc];
}

#pragma mark - ButtonBoxControllerDataSource overrides

// -----------------------------------------------------------------------------
/// @brief ButtonBoxControllerDataSource method.
// -----------------------------------------------------------------------------
- (int) numberOfSectionsInButtonBoxController:(ButtonBoxController*)buttonBoxController
{
  return 2;
}

// -----------------------------------------------------------------------------
/// @brief ButtonBoxControllerDataSource method.
// -----------------------------------------------------------------------------
- (int) buttonBoxController:(ButtonBoxController*)buttonBoxController numberOfRowsInSection:(NSInteger)section
{
  if (buttonBoxController.scrollDirection == UICollectionViewScrollDirectionHorizontal)
    return 1;
  else
    return 2;
}

// -----------------------------------------------------------------------------
/// @brief ButtonBoxControllerDataSource method.
// -----------------------------------------------------------------------------
- (int) buttonBoxController:(ButtonBoxController*)buttonBoxController numberOfColumnsInSection:(NSInteger)section
{
  if (buttonBoxController.scrollDirection == UICollectionViewScrollDirectionHorizontal)
    return 2;
  else
    return 1;
}

// -----------------------------------------------------------------------------
/// @brief ButtonBoxControllerDataSource method.
// -----------------------------------------------------------------------------
- (UIButton*) buttonBoxController:(ButtonBoxController*)buttonBoxController buttonAtIndexPath:(NSIndexPath*)indexPath
{
  NSString* imageResourceName;
  SEL selector;
  enum BoardPositionNavigationDirection boardPositionNavigationDirection;
  enum ButtonID buttonID = [self buttonIDForIndexPath:indexPath];
  switch (buttonID)
  {
    case RewindToStartButtonID:
    {
      imageResourceName = rewindToStartButtonIconResource;
      selector = @selector(rewindToStart:);
      boardPositionNavigationDirection = BoardPositionNavigationDirectionBackward;
      break;
    }
    case PreviousButtonID:
    {
      imageResourceName = backButtonIconResource;
      selector = @selector(previousBoardPosition:);
      boardPositionNavigationDirection = BoardPositionNavigationDirectionBackward;
      break;
    }
    case NextButtonID:
    {
      imageResourceName = forwardButtonIconResource;
      selector = @selector(nextBoardPosition:);
      boardPositionNavigationDirection = BoardPositionNavigationDirectionForward;
      break;
    }
    case ForwardToEndButtonID:
    {
      imageResourceName = forwardToEndButtonIconResource;
      selector = @selector(fastForwardToEnd:);
      boardPositionNavigationDirection = BoardPositionNavigationDirectionForward;
      break;
    }
    default:
    {
      return nil;
    }
  }

  UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
  [button setImage:[UIImage imageNamed:imageResourceName]
          forState:UIControlStateNormal];
  [button addTarget:[BoardPositionNavigationManager sharedNavigationManager]
             action:selector
   forControlEvents:UIControlEventTouchUpInside];
  button.enabled = [[BoardPositionNavigationManager sharedNavigationManager] isNavigationEnabledInDirection:boardPositionNavigationDirection];

  [self.navigationButtons addObject:button];
  if (boardPositionNavigationDirection == BoardPositionNavigationDirectionForward)
    [self.navigationButtonsForward addObject:button];
  else
    [self.navigationButtonsBackward addObject:button];

  return button;
}

#pragma mark - BoardPositionNavigationManagerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief BoardPositionNavigationManagerDelegate method.
// -----------------------------------------------------------------------------
- (void) boardPositionNavigationManager:(BoardPositionNavigationManager*)manager
                       enableNavigation:(BOOL)enable
                            inDirection:(enum BoardPositionNavigationDirection)direction
{
  switch (direction)
  {
    case BoardPositionNavigationDirectionForward:
    {
      for (UIButton* item in self.navigationButtonsForward)
        item.enabled = enable;
      break;
    }
    case BoardPositionNavigationDirectionBackward:
    {
      for (UIButton* item in self.navigationButtonsBackward)
        item.enabled = enable;
      break;
    }
    case BoardPositionNavigationDirectionAll:
    {
      for (UIButton* item in self.navigationButtons)
        item.enabled = enable;
      break;
    }
    default:
    {
      break;
    }
  }
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the #ButtonID value that corresponds to @a indexPath.
// -----------------------------------------------------------------------------
- (enum ButtonID) buttonIDForIndexPath:(NSIndexPath*)indexPath
{
  if (0 == indexPath.section)
  {
    if (0 == indexPath.row)
      return RewindToStartButtonID;
    else
      return PreviousButtonID;
  }
  else
  {
    if (0 == indexPath.row)
      return NextButtonID;
    else
      return ForwardToEndButtonID;
  }
}

@end
