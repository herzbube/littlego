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


// Forward declarations
@class BoardPositionNavigationManager;


enum BoardPositionNavigationDirection
{
  BoardPositionNavigationDirectionBackward,
  BoardPositionNavigationDirectionForward,
  BoardPositionNavigationDirectionAll,
};

// -----------------------------------------------------------------------------
/// @brief The delegate of BoardPositionNavigationManager must adopt the
/// BoardPositionNavigationManagerDelegate protocol.
// -----------------------------------------------------------------------------
@protocol BoardPositionNavigationManagerDelegate <NSObject>
@required
- (void) boardPositionNavigationManager:(BoardPositionNavigationManager*)manager
                       enableNavigation:(BOOL)enable
                            inDirection:(enum BoardPositionNavigationDirection)direction;
@end


// -----------------------------------------------------------------------------
/// @brief The BoardPositionNavigationManager class defines an abstract set of
/// board position navigation operations (e.g. "go to next board position").
/// BoardPositionNavigationManager also defines the behaviour of these
/// operations (i.e. what they do) and when they are available.
///
/// BoardPositionNavigationManager requires a third party to provide a visual
/// representation of the operations. UIControls such as UIButton are commonly
/// used for this. BoardPositionNavigationManager provides action handler
/// methods that can easily be connected to the corresponding UIControls'
/// actions.
///
/// BoardPositionNavigationManager observes the application state to determine
/// when the navigation operations should be available.
/// BoardPositionNavigationManager informs its delegate when a state change
/// is required.
// -----------------------------------------------------------------------------
@interface BoardPositionNavigationManager : NSObject
{
}

+ (BoardPositionNavigationManager*) sharedNavigationManager;
+ (void) releaseSharedNavigationManager;

- (void) rewindToStart:(id)sender;
- (void) previousBoardPosition:(id)sender;
- (void) nextBoardPosition:(id)sender;
- (void) fastForwardToEnd:(id)sender;

- (BOOL) isNavigationEnabledInDirection:(enum BoardPositionNavigationDirection)direction;

@property(nonatomic, assign) id<BoardPositionNavigationManagerDelegate> delegate;

@end
