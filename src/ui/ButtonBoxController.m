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
#import "ButtonBoxController.h"
#import "AutoLayoutUtility.h"
#import "ButtonBoxCell.h"
#import "UiElementMetrics.h"
#import "UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ButtonBoxController.
// -----------------------------------------------------------------------------
@interface ButtonBoxController()
@property(nonatomic, retain) NSString* reuseIdentifierCell;
@property(nonatomic, retain) NSString* reuseIdentifierSeparatorView;
@property(nonatomic, assign) CGSize buttonSize;
@property(nonatomic, assign) CGFloat rowSpacing;
@property(nonatomic, assign) CGFloat columnSpacing;
@property(nonatomic, assign) UIEdgeInsets margins;
@property(nonatomic, assign) CGSize sectionSeparatorSize;
@property(nonatomic, assign) UIEdgeInsets sectionInsets;
@end


@implementation ButtonBoxController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an ButtonBoxController object that manages a button box
/// that extends in @a scrollDirection.
///
/// @note This is the designated initializer of ButtonBoxController.
// -----------------------------------------------------------------------------
- (id) initWithScrollDirection:(UICollectionViewScrollDirection)scrollDirection
{
  UICollectionViewFlowLayout* flowLayout = [[[UICollectionViewFlowLayout alloc] init] autorelease];

  // Call designated initializer of superclass (UICollectionViewController)
  self = [super initWithCollectionViewLayout:flowLayout];
  if (! self)
    return nil;
  _scrollDirection = scrollDirection;
  self.reuseIdentifierCell = @"ButtonBoxCell";
  self.reuseIdentifierSeparatorView = @"ButtonBoxSeparatorView";
  self.buttonBoxControllerDataSource = nil;
  self.buttonBoxControllerDelegate = nil;
  self.buttonTintColor = [UIColor blackColor];

  CGFloat rowSpacingFactor;
  CGFloat columnSpacingFactor;
  CGFloat horizontalMarginFactor;
  CGFloat verticalMarginFactor;
  if (scrollDirection == UICollectionViewScrollDirectionHorizontal)
  {
    rowSpacingFactor = 1.0f;
    columnSpacingFactor = 2.0f;
    horizontalMarginFactor = 2.0f;
    verticalMarginFactor = 1.0f;
  }
  else
  {
    rowSpacingFactor = 2.0f;
    columnSpacingFactor = 1.0f;
    horizontalMarginFactor = 1.0f;
    verticalMarginFactor = 2.0f;
  }

  // Need to use the same width all the time, otherwise there is no grid effect
  // Height can vary, flow layout will use the largest height for the line.
  self.buttonSize = [UiElementMetrics toolbarIconSize];
  self.rowSpacing = [UiElementMetrics verticalSpacingSiblings] * rowSpacingFactor;
  self.columnSpacing = [UiElementMetrics horizontalSpacingSiblings] * columnSpacingFactor;
  self.sectionInsets = UIEdgeInsetsMake([UiElementMetrics verticalSpacingSiblings] * verticalMarginFactor,
                                        [UiElementMetrics horizontalSpacingSiblings] * horizontalMarginFactor,
                                        [UiElementMetrics verticalSpacingSiblings] * verticalMarginFactor,
                                        [UiElementMetrics horizontalSpacingSiblings] * horizontalMarginFactor);
  self.sectionSeparatorSize = CGSizeMake(1, 1);

  flowLayout.scrollDirection = self.scrollDirection;
  flowLayout.itemSize = self.buttonSize;
  if (scrollDirection == UICollectionViewScrollDirectionHorizontal)
  {
    // The flow layout switches its interpretation of "lines" when the scroll
    // direction is horizontal: It uses the "line spacing" to separate what we
    // think of as "columns" in our box model.
    flowLayout.minimumLineSpacing = self.columnSpacing;
    flowLayout.minimumInteritemSpacing = self.rowSpacing;
  }
  else
  {
    // When the scroll direction is vertical, the flow layout's interpretation
    // of "lines" is natural, i.e. it matches our own concept of "rows".
    flowLayout.minimumLineSpacing = self.rowSpacing;
    flowLayout.minimumInteritemSpacing = self.columnSpacing;
  }

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ButtonBoxController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.reuseIdentifierCell = nil;
  self.reuseIdentifierSeparatorView = nil;
  self.buttonBoxControllerDataSource = nil;
  self.buttonBoxControllerDelegate = nil;
  self.buttonTintColor = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [self.collectionView registerClass:[ButtonBoxCell class]
          forCellWithReuseIdentifier:self.reuseIdentifierCell];
  [self.collectionView registerClass:[UICollectionReusableView class]
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                 withReuseIdentifier:self.reuseIdentifierSeparatorView];
  // Important so that buttons switch to their highlighted appearance
  // immediately
  self.collectionView.delaysContentTouches = NO;
  // Take background color from superview
  self.collectionView.backgroundColor = [UIColor clearColor];
}

#pragma mark - UICollectionViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDataSource method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return [self.buttonBoxControllerDataSource numberOfSectionsInButtonBoxController:self];
}

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDataSource method.
// -----------------------------------------------------------------------------
- (NSInteger) collectionView:(UICollectionView*)collectionView
      numberOfItemsInSection:(NSInteger)section
{
  int numberOfRows = [self.buttonBoxControllerDataSource buttonBoxController:self numberOfRowsInSection:section];
  int numberOfColumns = [self.buttonBoxControllerDataSource buttonBoxController:self numberOfColumnsInSection:section];
  return (numberOfRows * numberOfColumns);
}

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDataSource method.
// -----------------------------------------------------------------------------
- (UICollectionViewCell*) collectionView:(UICollectionView*)collectionView
                  cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  ButtonBoxCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.reuseIdentifierCell
                                                                  forIndexPath:indexPath];
  UIButton* button = [self.buttonBoxControllerDataSource buttonBoxController:self
                                                           buttonAtIndexPath:indexPath];;
  button.tintColor = self.buttonTintColor;
  [cell setupWithButton:button];
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDataSource method.
// -----------------------------------------------------------------------------
- (UICollectionReusableView*) collectionView:(UICollectionView*)collectionView
           viewForSupplementaryElementOfKind:(NSString*)kind
                                 atIndexPath:(NSIndexPath*)indexPath
{
  UICollectionReusableView* separatorView = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                    withReuseIdentifier:self.reuseIdentifierSeparatorView
                                                                                           forIndexPath:indexPath];
  separatorView.backgroundColor = [UIColor blackColor];
  return separatorView;
}

#pragma mark - UICollectionViewDelegateFlowLayout overrides

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDelegateFlowLayout method.
// -----------------------------------------------------------------------------
- (CGSize) collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
  if (0 == section)
    return CGSizeZero;
  else
    return self.sectionSeparatorSize;
}

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDelegateFlowLayout method.
// -----------------------------------------------------------------------------
- (UIEdgeInsets) collectionView:(UICollectionView*)collectionView
                         layout:(UICollectionViewLayout*)collectionViewLayout
         insetForSectionAtIndex:(NSInteger)section
{
  return self.sectionInsets;
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Getter implementation for property @e buttonBoxSize.
///
/// Reasons why we implement this getter:
/// - We need information from the data source to calculate a value for this
///   property.
/// - We don't want to call data source methods prematurely, so we wait until
///   the last possible moment - which is when this property is queried.
// -----------------------------------------------------------------------------
- (CGSize) buttonBoxSize
{
  UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)self.collectionViewLayout;

  int maximumNumberOfRows = 0;
  int maximumNumberOfColumns = 0;
  int numberOfSections = [self.buttonBoxControllerDataSource numberOfSectionsInButtonBoxController:self];
  for (int section = 0; section < numberOfSections; ++section)
  {
    int numberOfRows = [self.buttonBoxControllerDataSource buttonBoxController:self numberOfRowsInSection:section];
    int numberOfColumns = [self.buttonBoxControllerDataSource buttonBoxController:self numberOfColumnsInSection:section];
    if (flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal)
    {
      maximumNumberOfRows = MAX(numberOfRows, maximumNumberOfRows);
      maximumNumberOfColumns += numberOfColumns;
    }
    else
    {
      maximumNumberOfRows += numberOfRows;
      maximumNumberOfColumns = MAX(numberOfColumns, maximumNumberOfColumns);
    }
  }
  CGSize buttonBoxSize = CGSizeZero;
  if (flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal)
  {
    buttonBoxSize.width += (self.buttonSize.width * maximumNumberOfColumns +
                            self.columnSpacing * (maximumNumberOfColumns - numberOfSections) +
                            (self.sectionInsets.left + self.sectionInsets.right) * numberOfSections+
                            self.sectionSeparatorSize.width * (numberOfSections - 1));
    buttonBoxSize.height += (self.buttonSize.height * maximumNumberOfRows +
                             self.rowSpacing * (maximumNumberOfRows - 1) +
                             self.sectionInsets.top + self.sectionInsets.bottom);
  }
  else
  {
    buttonBoxSize.width += (self.buttonSize.width * maximumNumberOfColumns +
                            self.columnSpacing * (maximumNumberOfColumns - 1) +
                            self.sectionInsets.left + self.sectionInsets.right);
    buttonBoxSize.height += (self.buttonSize.height * maximumNumberOfRows +
                             self.rowSpacing * (maximumNumberOfRows - numberOfSections) +
                             (self.sectionInsets.top + self.sectionInsets.bottom) * numberOfSections +
                             self.sectionSeparatorSize.height * (numberOfSections - 1));
  }
  return buttonBoxSize;
}

// -----------------------------------------------------------------------------
/// @brief Reloads the data displayed by the button box managed by this
/// controller.
///
/// The data source must provide updated values when this method is invoked, so
/// that the property @e buttonBoxSize returns the correct value when the
/// delegate invokes its getter.
// -----------------------------------------------------------------------------
- (void) reloadData
{
  if (self.buttonBoxControllerDelegate)
    [self.buttonBoxControllerDelegate buttonBoxButtonsWillChange];
  [self.collectionView reloadData];
}

@end