// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "UiElementMetrics.h"
#import "../main/ApplicationDelegate.h"
#import "../utility/UIDeviceAdditions.h"

/// @brief Helper class used internally by UiElementMetrics.
@interface OffscreenTableListViewController : UITableViewController
{
}

@end


@implementation UiElementMetrics

+ (UIInterfaceOrientation) interfaceOrientation
{
  // Since this application supports only one window, and therefore only one
  // scene, we can simply obtain the window and its scene from the window owner,
  // which is the application delegate.
  //
  // A more generic approach would work something like this: Get the
  // connectedScenes from UIApplication, then check each scene whether it's a
  // UIWindowScene, then select the UIWindowScene which has a window that is
  // the key window.
  return [ApplicationDelegate sharedDelegate].window.windowScene.interfaceOrientation;
}

+ (bool) interfaceOrientationIsPortrait
{
  return UIInterfaceOrientationIsPortrait([UiElementMetrics interfaceOrientation]);
}

+ (CGFloat) horizontalSpacingSiblings
{
  // This hard-coded value was experimentally determined in iOS 7 using Auto
  // Layout, with this visual format "H:[view1]-[view2]"
  return 8.0f;
}

+ (CGFloat) verticalSpacingSiblings
{
  // This hard-coded value was experimentally determined in iOS 7 using Auto
  // Layout, with this visual format "V:[view1]-[view2]"
  return 8.0f;
}

+ (CGFloat) horizontalSpacingSuperview
{
  // This hard-coded value was experimentally determined in iOS 7 using Auto
  // Layout, with this visual format "H:|-[subview]". In iOS 8, Auto Layout
  // returns 0 for the same visual format.
  return 20.0f;
}

+ (CGFloat) verticalSpacingSuperview
{
  // This hard-coded value was experimentally determined in iOS 7 using Auto
  // Layout, with this visual format "V:|-[subview]" In iOS 8, Auto Layout
  // returns 0 for the same visual format.
  return 20.0f;
}

+ (int) switchWidth
{
  return 94;
}

+ (CGSize) tableViewCellSizeForDefaultType
{
  return [UiElementMetrics tableViewCellSizeForType:DefaultCellType];
}

+ (CGSize) tableViewCellSizeForType:(enum TableViewCellType)cellType
{
  static CGSize tableViewCellSize = { 0.0f, 0.0f };
  if (CGSizeEqualToSize(tableViewCellSize, CGSizeZero))
  {
    UITableViewCell* dummyCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
    tableViewCellSize = dummyCell.bounds.size;
  }

  switch (cellType)
  {
    case SubtitleCellType:
      // In iOS 10 and below, cells with UITableViewCellStyleSubtitle had the
      // same height as all other cell types. In iOS 11 this changed: Cells with
      // UITableViewCellStyleSubtitle now have an increased height.
      // Unfortunately the height increase can be observed only when a cell is
      // actually rendered on screen - rendering an off-screen cell, as we do
      // above, returns the same height for all cell types. Experimentally
      // determined in the simulator: The height is variable! On some devices
      // it is 57 (e.g. iPhone 6S Plus, iPhone XS Max, iPad Pro 12.9"), while
      // on others it is 58 (e.g. iPhone 5S, iPhone 7). Instead of hardcoding
      // one of these numbers we calculate the increased height by adding a
      // number that we assume to be the additional top/bottom margins. This
      // should make us less vulnerable to a change of the default cell height
      // in the future. Also experimentally determined: The default cell height
      // is 44.
      return CGSizeMake(tableViewCellSize.width, tableViewCellSize.height + 13);
    default:
      return tableViewCellSize;
  }
}

// The horizontal margin is the distance from the left or right edge of the
// table view cell to the left or right edge of the table view cell content
// view, i.e. the space that is used in a grouped table view to inset the
// content view.
+ (int) tableViewCellMarginHorizontal
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return 10;
  else
    return 45;
}

/// @brief Width is for a non-indented top-level cell.
+ (int) tableViewCellContentViewWidth
{
  return [UiElementMetrics tableViewCellSizeForDefaultType].width - 2 * [UiElementMetrics tableViewCellMarginHorizontal];
}

// For the top cell in a grouped table view, the content view frame.origin.y
// coordinate is 1 (probably due to the cell's border line at the top), for the
// bottom and in-between cells frame.origin.y is 0.
+ (int) tableViewCellContentViewHeight
{
  // This cannot be calculated reliably using a table view cell's content view
  // bounds, because cell.contentView.bounds.size.width changes when a cell
  // is reused.
  return 43;
}

+ (int) tableViewCellContentViewAvailableWidth
{
  return [UiElementMetrics tableViewCellContentViewWidth] - 2 * [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal];
}

+ (int) tableViewCellContentDistanceFromEdgeHorizontal
{
  return 10;  // the same on iPhone and iPad
}

+ (int) tableViewCellContentDistanceFromEdgeVertical
{
  return 11;
}

+ (int) tableViewCellDisclosureIndicatorWidth
{
  return 20;
}

+ (CGSize) tableViewHeaderViewSizeForStyle:(UITableViewStyle)tableViewStyle
{
  if (tableViewStyle == UITableViewStylePlain)
  {
    static CGSize tableViewHeaderViewSizePlain = { 0.0f, 0.0f };
    if (CGSizeEqualToSize(tableViewHeaderViewSizePlain, CGSizeZero))
      tableViewHeaderViewSizePlain = [UiElementMetrics tableViewHeaderFooterViewSizeForStyle:tableViewStyle forHeaderView:true];
    return tableViewHeaderViewSizePlain;
  }
  else
  {
    static CGSize tableViewHeaderViewSizeGrouped = { 0.0f, 0.0f };
    if (CGSizeEqualToSize(tableViewHeaderViewSizeGrouped, CGSizeZero))
      tableViewHeaderViewSizeGrouped = [UiElementMetrics tableViewHeaderFooterViewSizeForStyle:tableViewStyle forHeaderView:true];
    return tableViewHeaderViewSizeGrouped;
  }
}

+ (CGSize) tableViewFooterViewSizeForStyle:(UITableViewStyle)tableViewStyle
{
  if (tableViewStyle == UITableViewStylePlain)
  {
    static CGSize tableViewFooterViewSizePlain = { 0.0f, 0.0f };
    if (CGSizeEqualToSize(tableViewFooterViewSizePlain, CGSizeZero))
      tableViewFooterViewSizePlain = [UiElementMetrics tableViewHeaderFooterViewSizeForStyle:tableViewStyle forHeaderView:false];
    return tableViewFooterViewSizePlain;
  }
  else
  {
    static CGSize tableViewFooterViewSizeGrouped = { 0.0f, 0.0f };
    if (CGSizeEqualToSize(tableViewFooterViewSizeGrouped, CGSizeZero))
      tableViewFooterViewSizeGrouped = [UiElementMetrics tableViewHeaderFooterViewSizeForStyle:tableViewStyle forHeaderView:false];
    return tableViewFooterViewSizeGrouped;
  }
}

+ (CGSize) tableViewHeaderFooterViewSizeForStyle:(UITableViewStyle)tableViewStyle forHeaderView:(bool)headerView
{
  OffscreenTableListViewController* offscreenTableListViewController =
    [[[OffscreenTableListViewController alloc] initWithStyle:tableViewStyle] autorelease];

  UITableView* offscreenTableView = offscreenTableListViewController.tableView;
  // Give the table view an arbitrary non-zero size, otherwise it will not
  // render any header/footer views. Assumption: The frame must be large enough
  // so that the full header/footer view height fits into it.
  offscreenTableView.frame = CGRectMake(0, 0, 1000, 1000);
  [offscreenTableView layoutIfNeeded];

  UITableViewHeaderFooterView* headerFooterView;
  if (headerView)
    headerFooterView = [offscreenTableView headerViewForSection:0];
  else
    headerFooterView = [offscreenTableView footerViewForSection:0];

  CGSize headerFooterViewSize = headerFooterView.contentView.bounds.size;
  return headerFooterViewSize;
}

+ (int) splitViewControllerLeftPaneWidth
{
  return 320;
}

+ (CGSize) toolbarIconSize
{
  // This is the size (in points) recommended by the HIG for navigation and
  // toolbar icons
  return CGSizeMake(22.0f, 22.0f);
}

@end

// -----------------------------------------------------------------------------
// Implementation of internal helper class
// -----------------------------------------------------------------------------

@implementation OffscreenTableListViewController

#pragma mark - UITableViewDataSource overrides

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  return 1;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  return @"foo";
}

- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  return @"foo";
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSString* identifier = @"foo";

  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  if (cell != nil)
    return cell;

  cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                 reuseIdentifier:identifier] autorelease];

  cell.textLabel.text = @"foo";
  cell.detailTextLabel.text = @"foo";

  return cell;
}

@end
