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
#import "ButtonBoxCell.h"
#import "AutoLayoutUtility.h"
#import "UiElementMetrics.h"
#import "UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ButtonBoxCell.
// -----------------------------------------------------------------------------
@interface ButtonBoxCell()
@property(nonatomic, retain) UIButton* button;
@property(nonatomic, retain) NSArray* autoLayoutConstraints;
@end


@implementation ButtonBoxCell

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an ButtonBoxCell object.
///
/// @note This is the designated initializer of ButtonBoxCell.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  self = [super initWithFrame:rect];
  if (! self)
    return nil;
  self.button = nil;
  self.autoLayoutConstraints = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ButtonBoxCell object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // Do NOT invoke removeButtonIfSet - in fact do NOT mess with the view
  // hierarchy or auto layout constraints at all, otherwise an autorelease
  // may be queued by iOS
  self.autoLayoutConstraints = nil;
  self.button = nil;
  [super dealloc];
}

#pragma mark - UICollectionViewCell overrides

// -----------------------------------------------------------------------------
/// @brief UICollectionViewCell method.
// -----------------------------------------------------------------------------
- (void) prepareForReuse
{
  [self removeButtonIfSet];
  [super prepareForReuse];
}

#pragma mark - Button handling

// -----------------------------------------------------------------------------
/// @brief Adds @a button to the view hierarchy of this cell.
// -----------------------------------------------------------------------------
- (void) setupWithButton:(UIButton*)button
{
  self.button = button;
  [self.contentView addSubview:self.button];
  self.button.translatesAutoresizingMaskIntoConstraints = false;
  self.autoLayoutConstraints = [AutoLayoutUtility centerSubview:self.button inSuperview:self.contentView];
}

// -----------------------------------------------------------------------------
/// @brief Removes the button that is currently set from the view hierarchy of
/// this cell.
// -----------------------------------------------------------------------------
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

@end
