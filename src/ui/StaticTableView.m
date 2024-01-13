// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "StaticTableView.h"
#import "AutoLayoutUtility.h"
#import "SpacerView.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for StaticTableView.
// -----------------------------------------------------------------------------
@interface StaticTableView()
@property(nonatomic, assign, readwrite) UITableView* tableView;
@property(nonatomic, retain) NSLayoutConstraint* heightConstraint;
@end


@implementation StaticTableView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a StaticTableView object.
///
/// @note This is the designated initializer of StaticTableView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect style:(UITableViewStyle)tableViewStyle
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.tableView = [[[UITableView alloc] initWithFrame:rect style:tableViewStyle] autorelease];
  [self addSubview:self.tableView];

  // To allow embedding StaticTableView into a view layout where there are no
  // other elements below it, we add an expandable spacer view below the table
  // view. The spacer view has an intrinsic content size of @e CGSizeZero and
  // resists expansion by Auto Layout as much as possible. This causes Auto
  // Layout to preferrably give available space to other views, but if there are
  // no such views then the spacer view will gobble it up.
  UIView* spacerView = [[[SpacerView alloc] initWithFrame:CGRectZero] autorelease];
  [spacerView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
  [self addSubview:spacerView];
  if (tableViewStyle == UITableViewStyleGrouped)
    spacerView.backgroundColor = [UIColor systemGroupedBackgroundColor];
  else
    spacerView.backgroundColor = [UIColor whiteColor];

  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  spacerView.translatesAutoresizingMaskIntoConstraints = NO;
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];
  viewsDictionary[@"tableView"] = self.tableView;
  viewsDictionary[@"spacerView"] = spacerView;
  [visualFormats addObject:@"H:|-0-[tableView]-0-|"];
  [visualFormats addObject:@"H:|-0-[spacerView]-0-|"];
  [visualFormats addObject:@"V:|-0-[tableView]-0-[spacerView]-0-|"];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self];

  CGFloat contentHeight = self.tableView.contentSize.height;
  self.heightConstraint = [NSLayoutConstraint constraintWithItem:self.tableView
                                                       attribute:NSLayoutAttributeHeight
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:nil
                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                      multiplier:1.0f
                                                        constant:contentHeight];
  self.heightConstraint.active = YES;

  [self.tableView addObserver:self
                   forKeyPath:@"contentSize"
                      options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior
                      context:NULL];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StaticTableView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.tableView = nil;
  self.heightConstraint = nil;
  [super dealloc];
}

#pragma mark - KVO overrides

// -----------------------------------------------------------------------------
/// @brief KVO method.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath
                       ofObject:(id)object
                         change:(NSDictionary*)change
                        context:(void *)context
{
  if ([keyPath isEqualToString:@"contentSize"])
  {
    CGFloat contentHeight = self.tableView.contentSize.height;
    if (self.heightConstraint.constant != contentHeight)
      self.heightConstraint.constant = contentHeight;
  }
}

@end
