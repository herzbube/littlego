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

+ (int) navigationBarHeight
{
  return 44;  // same as toolbar height
}

+ (int) toolbarHeight
{
  return 44;  // same as navigation bar height
}

+ (int) tabBarHeight
{
  return 49;
}

+ (int) viewWithStatusBarHeight
{
  return [UiElementMetrics screenHeight] - [UiElementMetrics statusBarHeight];
}

+ (int) viewWithNavigationBarHeight
{
  return [UiElementMetrics viewWithStatusBarHeight] - [UiElementMetrics navigationBarHeight];
}

+ (int) viewWithTabBarHeight
{
  return [UiElementMetrics viewWithStatusBarHeight] - [UiElementMetrics tabBarHeight];
}

+ (int) viewWithNavigationAndTabBarHeight
{
  return [UiElementMetrics viewWithNavigationBarHeight] - [UiElementMetrics tabBarHeight];
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

+ (int) activityIndicatorWidthAndHeight
{
  return 20;
}

/// @brief Width is for a non-indented top-level cell.
+ (int) tableViewCellContentViewWidth
{
  // This cannot be calculated reliably using a table view's content view
  // bounds, because self.contentView.bounds.size.width changes when a cell
  // is reused.
  return [UiElementMetrics screenWidth] - 2 * [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal];
}

+ (int) tableViewCellContentViewHeight
{
  // A dynamic calculation would use cell.contentView.bounds.size.height;
  return 44;
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
  return 10;
}

+ (int) tableViewCellContentDistanceFromEdgeVertical
{
  return 11;
}

+ (int) tableViewCellDisclosureIndicatorWidth
{
  return 20;
}

@end
