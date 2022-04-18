// -----------------------------------------------------------------------------
// Copyright 2015-2019 Patrick Näf (herzbube@herzbube.ch)
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
- (NSString*) accessibilityIdentifierInButtonBoxController:(ButtonBoxController*)buttonBoxController;
- (int) numberOfSectionsInButtonBoxController:(ButtonBoxController*)buttonBoxController;
- (int) buttonBoxController:(ButtonBoxController*)buttonBoxController numberOfRowsInSection:(NSInteger)section;
- (int) buttonBoxController:(ButtonBoxController*)buttonBoxController numberOfColumnsInSection:(NSInteger)section;
/// @brief The @e row property of parameter @e indexPath is a one-dimensional
/// index into the button box grid, indicating which button is requested. The
/// meaning of the index changes depending on the direction in which the button
/// box extends (see property @e scrollDirection of @a buttonBoxController).
///
/// Example for a button box grid with 2 rows and 2 columns, when the button box
/// extends horizontally, i.e. in @e UICollectionViewScrollDirectionHorizontal):
/// - @e indexPath.row 0 = row/column 0/0
/// - @e indexPath.row 1 = row/column 1/0
/// - @e indexPath.row 2 = row/column 0/1
/// - @e indexPath.row 3 = row/column 1/1.
///
/// Example for a button box grid with 2 rows and 2 columns, when the button box
/// extends vertically, i.e. in @e UICollectionViewScrollDirectionVertical):
/// - @e indexPath.row 0 = row/column 0/0
/// - @e indexPath.row 1 = row/column 0/1
/// - @e indexPath.row 2 = row/column 1/0
/// - @e indexPath.row 3 = row/column 1/1.
- (UIButton*) buttonBoxController:(ButtonBoxController*)buttonBoxController buttonAtIndexPath:(NSIndexPath*)indexPath;
@end

// -----------------------------------------------------------------------------
/// @brief The delegate of ButtonBoxController must adopt the
/// ButtonBoxControllerDataDelegate protocol.
// -----------------------------------------------------------------------------
@protocol ButtonBoxControllerDataDelegate <NSObject>
@required
/// @brief Advises the delegate that the buttons displayed by the
/// ButtonBoxController view are about to change. The delegate may wish to
/// requery the controller's @a buttonBoxSize property to update the layout of
/// the view that integrates the ButtonBoxController view.
- (void) buttonBoxButtonsWillChange;
@end


// -----------------------------------------------------------------------------
/// @brief The ButtonBoxController class is responsible for displaying a
/// rectangular box that contains a number of sections, each of which displays
/// a grid of UIButton objects. The button box extends in horizontal or vertical
/// direction.
///
/// ButtonBoxController expects UIButtons to have a uniform size that is equal
/// to the standard size for toolbar/navigation bar button icons. Smaller
/// UIButtons should work, too.
///
/// @par The box model
///
/// - The button box extends either in horizontal or in vertical direction
/// - The button box consists of 0-n sections
/// - Sections are placed one after the other in the direction in which the
///   button box extends
/// - Each section consists of a grid of buttons
/// - Section grids are individually sized, i.e. different sections can have
///   grids with different sizes
/// - Each section is a box within the entire button box
/// - The section box has insets (or margins / padding, if you like)
/// - The insets are fixed in the direction in which the button box extends, and
///   variable in the other direction
/// - Each section is separated from the next by a horizontal or vertical
///   separator
///
/// The following scheme shows an example for a horizontally extending box with
/// the following characteristics:
/// - Sections = 2
/// - Section 1: Rows = 3, columns = 4
/// - Section 2: Rows = 1, columns = 2
/// - Left/right insets are fixed for all sections, top/bottom insets are
///   variable
///
/// @verbatim
/// +---------+-----+
/// |         |     |
/// | * * * * |     |
/// | * * * * | * * |
/// | * * * * |     |
/// |         |     |
/// +---------+-----+
/// @endverbatim
///
/// The following scheme shows an example for a vertically extending box with
/// the following characteristics:
/// - Sections = 2
/// - Section 1: Rows = 3, columns = 5
/// - Section 2: Rows = 2, columns = 1
/// - Top/bottom insets are fixed for all sections, left/right insets are
///   variable
///
/// @verbatim
/// +-----------+
/// |           |
/// | * * * * * |
/// | * * * * * |
/// | * * * * * |
/// |           |
/// +-----------+
/// |           |
/// |     *     |
/// |     *     |
/// |           |
/// +-----------+
/// @endverbatim
///
/// @todo ButtonBoxController has been tested for grids with 1 row and n columns
/// distributed across multiple sections (if horizontally extending), 1 column
/// and n rows distributed across multiple sections (if vertically extending)
/// and 2 rows and 2 columns in a single section (if vertically extending). The
/// current implementation may not work as documented by the above box model for
/// other configurations.
// -----------------------------------------------------------------------------
@interface ButtonBoxController : UICollectionViewController <UICollectionViewDelegateFlowLayout>
{
}

- (id) initWithScrollDirection:(UICollectionViewScrollDirection)scrollDirection;

- (void) reloadData;

@property(nonatomic, assign) id<ButtonBoxControllerDataSource> buttonBoxControllerDataSource;
@property(nonatomic, assign) id<ButtonBoxControllerDataDelegate> buttonBoxControllerDelegate;

/// @brief The direction in which the button box managed by this controller
/// extends.
@property(nonatomic, assign, readonly) UICollectionViewScrollDirection scrollDirection;

/// @brief The size of the button box managed by this controller. Accessing this
/// property will start querying the data source.
@property(nonatomic, assign, readonly) CGSize buttonBoxSize;

/// @brief The color used to tint buttons. The default is black.
@property(nonatomic, retain) UIColor* buttonTintColor;

@end
