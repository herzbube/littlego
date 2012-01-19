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
#import "UiUtilities.h"
#import "UiElementMetrics.h"


@implementation UiUtilities

// -----------------------------------------------------------------------------
/// @brief Calculates the row height for a table view cell of type @a type
/// whose label is about to be displayed containing @a text.
///
/// Supported cell types currently are #DefaultCellType and #SwitchCellType.
///
/// @a hasDisclosureIndicator is true if the cell displays a standard disclosure
/// indicator.
///
/// Assumptions that this method makes:
/// - The cell is not indented, i.e. the cell has the full width of the screen
/// - The label inside the cell uses the default label font and label font size
/// - The label uses UILineBreakModeWordWrap.
///
/// @note This method is intended to be called from inside a table view
/// delegate's tableView:heightForRowAtIndexPath:().
// -----------------------------------------------------------------------------
+ (CGFloat) tableView:(UITableView*)tableView heightForCellOfType:(enum TableViewCellType)type withText:(NSString*)text  hasDisclosureIndicator:(bool)hasDisclosureIndicator
{
  // Calculating the cell height for an empty text results in a value much too
  // small. We therefore return table view's default height for rows
  if (0 == text.length)
    return tableView.rowHeight;

  CGFloat labelWidth;
  switch (type)
  {
    case DefaultCellType:
    {
      // The label has the entire cell width
      labelWidth = [UiElementMetrics tableViewCellContentViewAvailableWidth];
      break;
    }
    case SwitchCellType:
    {
      // The label shares the cell with a UISwitch
      labelWidth = ([UiElementMetrics tableViewCellContentViewAvailableWidth]
                    - [UiElementMetrics switchWidth]
                    - [UiElementMetrics spacingHorizontal]);
      break;
    }
    default:
    {
      assert(0);
      return tableView.rowHeight;
    }
  }
  if (hasDisclosureIndicator)
    labelWidth -= [UiElementMetrics tableViewCellDisclosureIndicatorWidth];

  UIFont* labelFont = [UIFont systemFontOfSize:[UIFont labelFontSize]];
  CGSize constraintSize = CGSizeMake(labelWidth, MAXFLOAT);
  CGSize labelSize = [text sizeWithFont:labelFont
                      constrainedToSize:constraintSize
                          lineBreakMode:UILineBreakModeWordWrap];

  return labelSize.height + 2 * [UiElementMetrics tableViewCellContentDistanceFromEdgeVertical];
}

// -----------------------------------------------------------------------------
/// @brief Returns YES for portrait orientations on iPhone, and for all
/// orientations on iPad. Returns NO for all other situations.
///
/// This method implements application-wide orientation support. It can be
/// invoked by all view controller's shouldAutorotateToInterfaceOrientation:().
// -----------------------------------------------------------------------------
+ (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isLandscapeOrientation = UIInterfaceOrientationIsLandscape(interfaceOrientation);
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return isLandscapeOrientation ? NO : YES;
  else
    return YES;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new UITableView with style @a tableViewStyle, configures
/// @a viewController with the newly created table view, and configures the
/// table view to use the controller as delegate and data source (if the
/// controller adopts the appropriate protocols).
///
/// This method is useful for controllers that do not want to load their view
/// from a .nib file. It is intended to be called from a controller's
/// loadView().
///
/// This method does not invoke reloadData() on the newly created table view.
/// If this method is invoked from the controller's loadView(), and the
/// controller is a UITableViewController, the UITableViewController
/// implementation will automatically trigger data loading. In all other cases,
/// it is the controller's responsibility to trigger data loading at the
/// appropriate time.
// -----------------------------------------------------------------------------
+ (void) createTableViewWithStyle:(UITableViewStyle)tableViewStyle forController:(UIViewController*)viewController
{
  UITableView* tableView = [[UITableView alloc] initWithFrame:[UiElementMetrics applicationFrame]
                                                        style:tableViewStyle];
  
  // Connect controller with view
  // Note: If viewController is a UITableViewController, setting this property
  // automatically sets the controller's tableView property
  viewController.view = tableView;
  [tableView release];

  // Connect view with controller
  if ([viewController conformsToProtocol:@protocol(UITableViewDelegate)])
    tableView.delegate = (id<UITableViewDelegate>)viewController;
  if ([viewController conformsToProtocol:@protocol(UITableViewDataSource)])
    tableView.dataSource = (id<UITableViewDataSource>)viewController;
}

@end
