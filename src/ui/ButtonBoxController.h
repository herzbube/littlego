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
@class ButtonBoxController;


// -----------------------------------------------------------------------------
/// @brief The data source of ButtonBoxController must adopt the
/// ButtonBoxControllerDataSource protocol.
// -----------------------------------------------------------------------------
@protocol ButtonBoxControllerDataSource <NSObject>
@required
- (int) numberOfRowsInButtonBoxController:(ButtonBoxController*)buttonBoxController;
- (int) numberOfColumnsInButtonBoxController:(ButtonBoxController*)buttonBoxController;
/// @brief The property @e indexPath.row is a one-dimensional index into the
/// button box grid, indicating which button is requested. Example for a button
/// box grid with 2 rows and 2 columns: index 0 = row/column 0/0, index 1 =
/// row/column 0/1, index 2 = row/column 1/0, index 3 = row/column 1/1.
- (UIButton*) buttonBoxController:(ButtonBoxController*)buttonBoxController buttonAtIndexPath:(NSIndexPath*)indexPath;
@end


// -----------------------------------------------------------------------------
/// @brief The ButtonBoxController class is responsible for displaying a
/// rectangular box that contains a grid of UIButton objects.
///
/// ButtonBoxController expects UIButtons to have a uniform size that is equal
/// to the standard size for toolbar/navigation bar button icons. Smaller
/// UIButtons should work, too.
// -----------------------------------------------------------------------------
@interface ButtonBoxController : UICollectionViewController <UICollectionViewDelegateFlowLayout>
{
}

@property(nonatomic, assign) id<ButtonBoxControllerDataSource> buttonBoxControllerDataSource;
@property(nonatomic, assign, readonly) CGSize buttonBoxSize;
@property(nonatomic, retain) UIColor* buttonTintColor;

@end
