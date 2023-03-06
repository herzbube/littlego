// -----------------------------------------------------------------------------
// Copyright 2015-2022 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The AutoLayoutUtility class is a container for various utility
/// functions related to Auto Layout.
///
/// All functions in AutoLayoutUtility are class methods, so there is no need to
/// create an instance of AutoLayoutUtility.
// -----------------------------------------------------------------------------
@interface AutoLayoutUtility : NSObject
{
}

+ (NSArray*) fillSuperview:(UIView*)superview
               withSubview:(UIView*)subview;
+ (NSArray*) fillSuperview:(UIView*)superview
               withSubview:(UIView*)subview
                   margins:(UIEdgeInsets)margins;
+ (NSArray*) fillSafeAreaOfSuperview:(UIView*)superview
                         withSubview:(UIView*)subview;
+ (NSArray*) centerSubview:(UIView*)subview
               inSuperview:(UIView*)superview;
+ (NSLayoutConstraint*) centerSubview:(UIView*)subview
                          inSuperview:(UIView*)superview
                               onAxis:(UILayoutConstraintAxis)axis;
+ (NSArray*) alignFirstView:(UIView*)firstView
             withSecondView:(UIView*)secondView
                    onEdges:(UIRectEdge)edges
           constraintHolder:(UIView*)constraintHolder;
+ (NSLayoutConstraint*) alignFirstView:(UIView*)firstView
                        withSecondView:(UIView*)secondView
                           onAttribute:(NSLayoutAttribute)attribute
                      constraintHolder:(UIView*)constraintHolder;
+ (NSLayoutConstraint*) alignFirstView:(UIView*)firstView
                        withSecondView:(UIView*)secondView
                           onAttribute:(NSLayoutAttribute)attribute
                          withConstant:(CGFloat)constant
                      constraintHolder:(UIView*)constraintHolder;
+ (NSLayoutConstraint*) alignFirstView:(UIView*)firstView
                        withSecondView:(UIView*)secondView
                           onAttribute:(NSLayoutAttribute)attribute
                        withMultiplier:(CGFloat)multiplier
                      constraintHolder:(UIView*)constraintHolder;
+ (NSLayoutConstraint*) alignFirstView:(UIView*)firstView
                        withSecondView:(UIView*)secondView
                           onAttribute:(NSLayoutAttribute)attribute
                        withMultiplier:(CGFloat)multiplier
                          withConstant:(CGFloat)constant
                      constraintHolder:(UIView*)constraintHolder;
+ (NSLayoutConstraint*) alignFirstView:(UIView*)firstView
                        withSecondView:(UIView*)secondView
                           onAttribute:(NSLayoutAttribute)attribute
                        withMultiplier:(CGFloat)multiplier
                          withConstant:(CGFloat)constant
                          withPriority:(UILayoutPriority)priority
                      constraintHolder:(UIView*)constraintHolder;
+ (NSArray*) alignFirstView:(UIView*)firstView
             withSecondView:(UIView*)secondView
            onSafeAreaEdges:(UIRectEdge)edges;
+ (NSLayoutConstraint*) alignFirstView:(UIView*)firstView
                        withSecondView:(UIView*)secondView
           onSafeAreaLayoutGuideAnchor:(NSLayoutAttribute)attribute;
+ (NSLayoutConstraint*) makeSquare:(UIView*)view
              widthDependsOnHeight:(bool)widthDependsOnHeight
                  constraintHolder:(UIView*)constraintHolder;
+ (NSLayoutConstraint*) setAspectRatio:(CGFloat)multiplier
                         widthToHeight:(bool)widthToHeight
                                ofView:(UIView*)view
                      constraintHolder:(UIView*)constraintHolder;
+ (NSArray*) installVisualFormats:(NSArray*)visualFormats
                        withViews:(NSDictionary*)viewsDictionary
                           inView:(UIView*)view;
+ (NSArray*) createConstraintsWithVisualFormats:(NSArray*)visualFormats
                                          views:(NSDictionary*)viewsDictionary;
+ (CGFloat) horizontalSpacingSiblings;
+ (CGFloat) verticalSpacingSiblings;
+ (CGFloat) horizontalSpacingSuperview;
+ (CGFloat) verticalSpacingSuperview;
+ (CGFloat) horizontalSpacingTableViewCell;
+ (CGFloat) verticalSpacingTableViewCell;

@end
