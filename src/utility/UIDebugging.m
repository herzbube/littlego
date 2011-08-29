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
#import "UIDebugging.h"
#import "UIColorAdditions.h"

// System includes
#import <UIKit/UIKit.h>


@implementation UIDebugging

// -----------------------------------------------------------------------------
/// @brief Inspects @a view, printing the view's characteristics (e.g. its
/// frame) with NSLog to the debug output.
// -----------------------------------------------------------------------------
+ (void) inspect:(UIView*)view
{
  NSLog(@"Inspecting view %d: %@", view, view.description);
}

// -----------------------------------------------------------------------------
/// @brief Invokes inspect:withSubviews:() for @a view and all of its direct
/// subviews.
// -----------------------------------------------------------------------------
+ (void) inspectWithSubviews:(UIView*)view
{
  [self inspect:view];
  NSArray* subviews = view.subviews;
  NSLog(@"Inspecting %d subviews of view %d", subviews.count, view);
  for (UIView* subview in subviews)
    [self inspect:subview];
}

// -----------------------------------------------------------------------------
/// @brief Invokes inspect:withSubviews:() for @a view and the entire view
/// hierarchy below @a view.
// -----------------------------------------------------------------------------
+ (void) inspectWithTree:(UIView*)view
{
  [self inspect:view];
  NSArray* subviews = view.subviews;
  NSLog(@"Inspecting %d subviews of view %d", subviews.count, view);
  for (UIView* subview in subviews)
    [self inspectWithTree:subview];
}

@end
