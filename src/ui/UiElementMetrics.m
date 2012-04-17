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


// Project includes
#import "UiElementMetrics.h"


@implementation UiElementMetrics

static UIViewController* m_interfaceOrientationSource;

+ (void) setInterfaceOrientationSource:(UIViewController*)interfaceOrientationSource
{
  m_interfaceOrientationSource = interfaceOrientationSource;
}

+ (int) screenWidth
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(m_interfaceOrientationSource.interfaceOrientation);
  if (isPortraitOrientation)
    return [UIScreen mainScreen].bounds.size.width;
  else
    return [UIScreen mainScreen].bounds.size.height;
}

+ (int) screenHeight
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(m_interfaceOrientationSource.interfaceOrientation);
  if (isPortraitOrientation)
    return [UIScreen mainScreen].bounds.size.height;
  else
    return [UIScreen mainScreen].bounds.size.width;
}

/// @brief Frame of application screen area (i.e. entire screen minus status
/// bar if visible)
+ (CGRect) applicationFrame
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(m_interfaceOrientationSource.interfaceOrientation);
  if (isPortraitOrientation)
    return [UIScreen mainScreen].applicationFrame;
  else
  {
    CGRect applicationFrame = [UIScreen mainScreen].applicationFrame;
    CGRect applicationFrameWithOrientation = CGRectMake(applicationFrame.origin.x,
                                                        applicationFrame.origin.y,
                                                        applicationFrame.size.height,
                                                        applicationFrame.size.width);
    return applicationFrameWithOrientation;
  }
}

+ (int) statusBarHeight
{
  return 20;
}

// It's recommended not to set bar heights programmatically, but heck, why not
// if we already do it for everything else?
+ (int) navigationBarHeight
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(m_interfaceOrientationSource.interfaceOrientation);
    if (! isPortraitOrientation)
      return 32;
  }
  return 44;
}

+ (int) toolbarHeight
{
  return [UiElementMetrics navigationBarHeight];
}

+ (int) tabBarHeight
{
  return 49;
}

+ (int) spacingHorizontal
{
  return 8;
}

+ (int) spacingVertical
{
  return 8;
}

+ (int) labelHeight
{
  return 21;
}

+ (int) sliderHeight
{
  return 23;
}

+ (int) switchWidth
{
  return 94;
}

+ (int) textFieldHeight
{
  return 31;
}

+ (int) activityIndicatorWidthAndHeight
{
  return 20;
}

+ (int) viewMarginHorizontal
{
  // Use the same margin as a table view
  return [UiElementMetrics tableViewCellMarginHorizontal];
}

+ (int) viewMarginVertical
{
  // Use the same margin as a table view
  return [UiElementMetrics tableViewMarginVertical];
}

// The vertical margin of a table view is the distance from the top or bottom
// edge of the table view to the top or bottom edge of the top-most or
// bottom-most table view element (e.g. a cell, or a header/footer).
+ (int) tableViewMarginVertical
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return 10;
  else
    return 30;
}

+ (int) tableViewCellWidth
{
  return [UiElementMetrics screenWidth];
}

+ (int) tableViewCellHeight:(bool)topOrBottomCell
{
  // The top and bottom cells in a grouped table view have height 45, any cells
  // in between have height 44. It's probably safe to assume that the additional
  // points come from the top and bottom border lines.
  if (topOrBottomCell)
    return 44;
  else
    return 43;
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
  return [UiElementMetrics tableViewCellWidth] - 2 * [UiElementMetrics tableViewCellMarginHorizontal];
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

+ (int) tableViewCellContentViewAvailableHeight
{
  return [UiElementMetrics tableViewCellContentViewHeight] - 2 * [UiElementMetrics tableViewCellContentDistanceFromEdgeVertical];
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

+ (int) englishKeyboardHeight
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(m_interfaceOrientationSource.interfaceOrientation);
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    if (isPortraitOrientation)
      return 216;
    else
      return 162;
  }
  else
  {
    if (isPortraitOrientation)
      return 264;
    else
      return 352;
  }
}

@end
