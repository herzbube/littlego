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
@property(nonatomic, retain) NSString* reuseIdentifier;
@property(nonatomic, assign) CGSize buttonSize;
@property(nonatomic, assign) CGFloat rowSpacing;
@property(nonatomic, assign) CGFloat columnSpacing;
@property(nonatomic, assign) UIEdgeInsets margins;
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
  self.reuseIdentifier = @"ButtonBoxCell";
  self.buttonBoxControllerDataSource = nil;
  self.buttonTintColor = [UIColor blueColor];

  // Need to use the same width all the time, otherwise there is no grid effect
  // Height can vary, flow layout will use the largest height for the line.
  self.buttonSize = [UiElementMetrics toolbarIconSize];
  self.rowSpacing = [UiElementMetrics verticalSpacingSiblings];
  self.columnSpacing = [UiElementMetrics horizontalSpacingSiblings];
  self.margins = UIEdgeInsetsMake([UiElementMetrics verticalSpacingSiblings],
                                  [UiElementMetrics verticalSpacingSiblings],
                                  [UiElementMetrics horizontalSpacingSiblings],
                                  [UiElementMetrics horizontalSpacingSiblings]);

  flowLayout.itemSize = self.buttonSize;
  flowLayout.minimumLineSpacing = self.rowSpacing;
  flowLayout.minimumInteritemSpacing = self.columnSpacing;
  flowLayout.sectionInset = self.margins;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ButtonBoxController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [self.collectionView registerClass:[ButtonBoxCell class]
          forCellWithReuseIdentifier:self.reuseIdentifier];
  // Important so that buttons switch to their highlighted appearance
  // immediately
  self.collectionView.delaysContentTouches = NO;
}

#pragma mark - UICollectionViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDataSource method.
// -----------------------------------------------------------------------------
- (NSInteger) collectionView:(UICollectionView*)collectionView
      numberOfItemsInSection:(NSInteger)section
{
  int numberOfRows = [self.buttonBoxControllerDataSource numberOfRowsInButtonBoxController:self];
  int numberOfColumns = [self.buttonBoxControllerDataSource numberOfColumnsInButtonBoxController:self];
  return (numberOfRows * numberOfColumns);
}

// -----------------------------------------------------------------------------
/// @brief UICollectionViewDataSource method.
// -----------------------------------------------------------------------------
- (UICollectionViewCell*) collectionView:(UICollectionView*)collectionView
                  cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  // As per specification, this actually returns a UICollectionReusableView
  // object, not a UICollectionViewCell. UICollectionReusableView is a base
  // class of UICollectionViewCell, so we would need to downcast...
  ButtonBoxCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.reuseIdentifier
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
  int numberOfRows = [self.buttonBoxControllerDataSource numberOfRowsInButtonBoxController:self];
  int numberOfColumns = [self.buttonBoxControllerDataSource numberOfColumnsInButtonBoxController:self];
  return CGSizeMake(numberOfColumns * self.buttonSize.width + (numberOfColumns - 1) * self.columnSpacing + self.margins.left + self.margins.right,
                    numberOfRows * self.buttonSize.height + (numberOfRows - 1) * self.rowSpacing + self.margins.top + self.margins.bottom);
}

@end
