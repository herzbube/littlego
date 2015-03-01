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
#import "UiElementMetrics.h"
#import "UIColorAdditions.h"


// TODO xxx
// - Suppress selections
// - Suppress highlights
// - Suppress edit menu
// (see "Designing Your Data Source and Delegate")


#pragma mark - ButtonBoxCell declaration and implementation

// -----------------------------------------------------------------------------
/// @brief The ButtonBoxCell class is a private class used by
/// ButtonBoxController to host a single UIButton.
// -----------------------------------------------------------------------------
@interface ButtonBoxCell : UICollectionViewCell
{
}

@property(nonatomic, retain) UIButton* button;
@property(nonatomic, retain) NSArray* autoLayoutConstraints;

@end


@implementation ButtonBoxCell
- (id) initWithFrame:(CGRect)rect
{
  self = [super initWithFrame:rect];
  if (! self)
    return nil;
  self.button = nil;
  self.autoLayoutConstraints = nil;
  return self;
}

- (void) dealloc
{
  [self removeButtonIfSet];
  [super dealloc];
}

- (void) setupWithButton:(UIButton*)button
{
  self.button = button;
  [self.contentView addSubview:self.button];
  self.button.translatesAutoresizingMaskIntoConstraints = false;
  self.autoLayoutConstraints = [AutoLayoutUtility centerSubview:self.button inSuperview:self.contentView];
}

- (void) removeButtonIfSet
{
  if (self.autoLayoutConstraints)
  {
    [self.contentView removeConstraints:self.autoLayoutConstraints];
    self.autoLayoutConstraints = nil;
  }
  if (self.button)
  {
    // Button may have already been added as a subview to a different cell, so
    // we must not remove it from its superview unless it's still associated
    // with this cell
    if (self.button.superview == self.contentView)
      [self.button removeFromSuperview];
    self.button = nil;
  }
}

- (void) prepareForReuse
{
  [self removeButtonIfSet];
  [super prepareForReuse];
}

@end


#pragma mark - ButtonBoxController declaration and implementation

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
@property(nonatomic, assign) CGFloat rowSpacingFactor;
@property(nonatomic, assign) CGFloat verticalMarginFactor;
@end


@implementation ButtonBoxController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an ButtonBoxController object.
///
/// @note This is the designated initializer of ButtonBoxController.
// -----------------------------------------------------------------------------
- (id) init
{
  UICollectionViewFlowLayout* flowLayout = [[[UICollectionViewFlowLayout alloc] init] autorelease];
  // Call designated initializer of superclass (UICollectionViewController)
  self = [super initWithCollectionViewLayout:flowLayout];
  if (! self)
    return nil;
  self.reuseIdentifierCell = @"ButtonBoxCell";
  self.reuseIdentifierSeparatorView = @"ButtonBoxSeparatorView";
  self.buttonBoxControllerDataSource = nil;
  self.buttonBoxControllerDelegate = nil;
//  self.buttonTintColor = [UIColor blueColor];
//  self.buttonTintColor = [UIColor darkTangerineColor];
//  self.buttonTintColor = [UIColor bleuDeFranceColor];
//  self.buttonTintColor = [UIColor mayaBlueColor];
//  self.buttonTintColor = [UIColor nonPhotoBlueColor];
  self.buttonTintColor = [UIColor blackColor];

  // Need to use the same width all the time, otherwise there is no grid effect
  // Height can vary, flow layout will use the largest height for the line.
  self.buttonSize = [UiElementMetrics toolbarIconSize];
  self.rowSpacing = [UiElementMetrics verticalSpacingSiblings];
  self.columnSpacing = [UiElementMetrics horizontalSpacingSiblings];
  self.margins = UIEdgeInsetsMake([UiElementMetrics verticalSpacingSiblings],
                                  [UiElementMetrics horizontalSpacingSiblings],
                                  [UiElementMetrics verticalSpacingSiblings],
                                  [UiElementMetrics horizontalSpacingSiblings]);
  self.sectionSeparatorSize = CGSizeMake(0, 1);
  self.rowSpacingFactor = 2.0f;
  self.verticalMarginFactor = 2.0f;

  flowLayout.itemSize = self.buttonSize;
  flowLayout.minimumLineSpacing = self.rowSpacing * self.rowSpacingFactor;
  flowLayout.minimumInteritemSpacing = self.columnSpacing;
//  flowLayout.sectionInset = self.margins;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ButtonBoxController
/// object.
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
  // Let external client determine any background colors
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

#pragma mark - Getter implementations

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
    if (flowLayout.scrollDirection == UICollectionViewScrollDirectionVertical)
    {
      maximumNumberOfRows += numberOfRows;
      maximumNumberOfColumns = MAX(numberOfColumns, maximumNumberOfColumns);
    }
    else
    {
      maximumNumberOfRows = MAX(numberOfRows, maximumNumberOfRows);
      maximumNumberOfColumns += numberOfColumns;
    }
  }
  CGSize buttonBoxSize = CGSizeZero;
  if (flowLayout.scrollDirection == UICollectionViewScrollDirectionVertical)
  {
    buttonBoxSize.width += (maximumNumberOfColumns * self.buttonSize.width +
                            (maximumNumberOfColumns - 1) * self.columnSpacing +
                            self.margins.left + self.margins.right);
    buttonBoxSize.height += (maximumNumberOfRows * self.buttonSize.height +
                             (maximumNumberOfRows - numberOfSections) * self.rowSpacing * self.rowSpacingFactor +
                             numberOfSections * (self.margins.top + self.margins.bottom) * self.verticalMarginFactor +
                             (numberOfSections - 1) * self.sectionSeparatorSize.height);
  }
  else
  {
    buttonBoxSize.width += (maximumNumberOfColumns * self.buttonSize.width +
                            (maximumNumberOfColumns - numberOfSections) * self.columnSpacing +
                            numberOfSections * (self.margins.left + self.margins.right) +
                            (numberOfSections - 1) * self.sectionSeparatorSize.width);
    buttonBoxSize.height += (maximumNumberOfRows * self.buttonSize.height +
                             (maximumNumberOfRows - 1) * self.rowSpacing * self.rowSpacingFactor +
                             (self.margins.top + self.margins.bottom) * self.verticalMarginFactor);
  }
  return buttonBoxSize;
}

- (CGSize) collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
  if (0 == section)
    return CGSizeZero;
  else
    return self.sectionSeparatorSize;
}

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

- (UIEdgeInsets) collectionView:(UICollectionView*)collectionView
                         layout:(UICollectionViewLayout*)collectionViewLayout
         insetForSectionAtIndex:(NSInteger)section
{
//  int numberOfSections = [self.buttonBoxControllerDataSource numberOfSectionsInButtonBoxController:self];
  UIEdgeInsets sectionInsets = UIEdgeInsetsZero;
  sectionInsets = self.margins;
  sectionInsets.top *= self.verticalMarginFactor;
  sectionInsets.bottom *= self.verticalMarginFactor;

//  sectionInsets.left = [UiElementMetrics horizontalSpacingSiblings];
//  sectionInsets.right = [UiElementMetrics horizontalSpacingSiblings];
//  if (0 == section)
//    sectionInsets.top = [UiElementMetrics verticalSpacingSiblings];
//  else
//    sectionInsets.top = [UiElementMetrics verticalSpacingSiblings];
//
//  if ((section + 1) == numberOfSections)
//    sectionInsets.bottom = [UiElementMetrics verticalSpacingSiblings];
//  else
//    sectionInsets.bottom = [UiElementMetrics verticalSpacingSiblings];

  return sectionInsets;
}

// data source must provide updated values when this method is invoked, so that
/// buttonBoxSize returns the correct value when the delegate invokes its getter
- (void) reloadData
{
  if (self.buttonBoxControllerDelegate)
    [self.buttonBoxControllerDelegate buttonBoxButtonsWillChange];
  [self.collectionView reloadData];
}

@end