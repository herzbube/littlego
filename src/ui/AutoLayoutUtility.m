// -----------------------------------------------------------------------------
// Copyright 2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "AutoLayoutUtility.h"


@implementation AutoLayoutUtility

// -----------------------------------------------------------------------------
/// @brief Adds Auto Layout constraints to @a superview that specify that
/// @a subview completely fills @a superview, i.e. that the subview's frame is
/// the same as the superview's bounds.
// -----------------------------------------------------------------------------
+ (void) fillSuperview:(UIView*)superview withSubview:(UIView*)subview
{
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObject:subview
                                                              forKey:@"subview"];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-0-[subview]-0-|",
                            @"V:|-0-[subview]-0-|",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:superview];
}

// -----------------------------------------------------------------------------
/// @brief Adds Auto Layout constraints to the view of @a viewController that
/// specify that @a subview completely fills the area between the top and bottom
/// layout guide of @a viewController.
// -----------------------------------------------------------------------------
+ (void) fillAreaBetweenGuidesOfViewController:(UIViewController*)viewController
                                   withSubview:(UIView*)subview
{
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   subview, @"subview",
                                   viewController.topLayoutGuide, @"topGuide",
                                   viewController.bottomLayoutGuide, @"bottomGuide",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-0-[subview]-0-|",
                            @"V:[topGuide]-0-[subview]-0-[bottomGuide]",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:viewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Adds Auto Layout constraints to @a superview that specify that
/// @a subview is horizontally and vertically centered in @a superview.
// -----------------------------------------------------------------------------
+ (void) centerSubview:(UIView*)subview inSuperview:(UIView*)superview
{
  [AutoLayoutUtility alignFirstView:subview
                     withSecondView:superview
                        onAttribute:NSLayoutAttributeCenterX
                   constraintHolder:superview];
  [AutoLayoutUtility alignFirstView:subview
                     withSecondView:superview
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:superview];
}

// -----------------------------------------------------------------------------
/// @brief Creates an Auto Layout constraint that aligns two views @a firstView
/// and @a secondView on the attribute @a attribute. The constraint is added to
/// @a constraintHolder.
///
/// Align means that the two views will have the same value for the specified
/// attribute. For instance, if @a attribute is NSLayoutAttributeLeft, then the
/// two views are left-aligned. A little less intuitive: If @a attribute is
/// NSLayoutAttributeWidth or NSLayoutAttributeHeight, then the two views have
/// the same width or height.
// -----------------------------------------------------------------------------
+ (void) alignFirstView:(UIView*)firstView
         withSecondView:(UIView*)secondView
              onAttribute:(NSLayoutAttribute)attribute
       constraintHolder:(UIView*)constraintHolder
{
  NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:firstView
                                                                attribute:attribute
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:secondView
                                                                attribute:attribute
                                                               multiplier:1.0f
                                                                 constant:0.0f];
  [constraintHolder addConstraint:constraint];
}

// -----------------------------------------------------------------------------
/// @brief Adds one Auto Layout constraint to @a view for each visual format
/// string found in @a visualFormats. The views referred to by the visual
/// format strings must be present in @a viewsDictionary.
// -----------------------------------------------------------------------------
+ (void) installVisualFormats:(NSArray*)visualFormats
                    withViews:(NSDictionary*)viewsDictionary
                       inView:(UIView*)view
{
  for (NSString* visualFormat in visualFormats)
  {
    NSArray* constraint = [NSLayoutConstraint constraintsWithVisualFormat:visualFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:viewsDictionary];

    [view addConstraints:constraint];
  }
}

@end
