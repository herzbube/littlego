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
#import "../ui/TableViewGridCell.h"

// Forward declarations
@class GameInfoViewController;
@class GoScore;


// -----------------------------------------------------------------------------
/// @brief The GameInfoViewControllerDelegate protocol must be implemented by
/// the delegate of GameInfoViewController.
// -----------------------------------------------------------------------------
@protocol GameInfoViewControllerDelegate
/// @brief This method is invoked when the user has finished working with
/// @a controller. The implementation is responsible for dismissing the
/// modal @a controller.
- (void) gameInfoViewControllerDidFinish:(GameInfoViewController*)controller;
@end


// -----------------------------------------------------------------------------
/// @brief The GameInfoViewController class is responsible for managing user
/// interaction on the "Game Info" view.
///
/// GameInfoViewController expects to be configured with a delegate that
/// can be informed when the user wants to dismiss the "Game Info" view. For
/// this to work, the delegate must implement the protocol
/// GameInfoViewControllerDelegate.
// -----------------------------------------------------------------------------
@interface GameInfoViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, TableViewGridCellDelegate>
{
}

+ (GameInfoViewController*) controllerWithDelegate:(id<GameInfoViewControllerDelegate>)delegate score:(GoScore*)score;

/// @brief This is the delegate that will be informed when the user wants to
/// dismiss the "Game Info" view.
@property(nonatomic, assign) id<GameInfoViewControllerDelegate> delegate;

@end
