// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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


// System includes
#import <UIKit/UIKit.h>

// Forward declarations
@class HandicapSelectionController;


// -----------------------------------------------------------------------------
/// @brief The HandicapSelectionDelegate protocol must be implemented by the
/// delegate of HandicapSelectionController.
// -----------------------------------------------------------------------------
@protocol HandicapSelectionDelegate
/// @brief This method is invoked when the user has finished working with
/// @a controller. The implementation is responsible for dismissing the
/// modal @a controller.
///
/// If @a didMakeSelection is true, the user has made a selection; the selected
/// handicap can be queried from the HandicapSelectionController object's
/// property @a handicap. If @a didMakeSelection is false, the user has
/// cancelled the selection.
- (void) handicapSelectionController:(HandicapSelectionController*)controller didMakeSelection:(bool)didMakeSelection;
@end


// -----------------------------------------------------------------------------
/// @brief The HandicapSelectionController class is responsible for managing
/// the view that lets the user select a handicap value.
///
/// HandicapSelectionController expects to be displayed modally by a navigation
/// controller. For this reason it populates its own navigation item with
/// controls that are then expected to be displayed in the navigation bar of
/// the parent navigation controller.
///
/// HandicapSelectionController expects to be configured with a delegate that
/// can be informed of the result of data collection. For this to work, the
/// delegate must implement the protocol HandicapSelectionDelegate.
// -----------------------------------------------------------------------------
@interface HandicapSelectionController : UITableViewController
{
}

+ (HandicapSelectionController*) controllerWithDelegate:(id<HandicapSelectionDelegate>)delegate defaultHandicap:(int)handicap maximumHandicap:(int)maximumHandicap;

/// @brief This is the delegate that will be informed about the result of data
/// collection.
@property(nonatomic, assign) id<HandicapSelectionDelegate> delegate;
/// @brief The currently selected handicap.
@property(nonatomic, assign) int handicap;

@end
