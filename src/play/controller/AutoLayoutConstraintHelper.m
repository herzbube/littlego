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
#import "AutoLayoutConstraintHelper.h"
#import "../../ui/AutoLayoutUtility.h"


@implementation AutoLayoutConstraintHelper

// -----------------------------------------------------------------------------
/// @brief Updates Auto Layout constraints that manage the size and placement of
/// @a boardView within its superview. The constraints are added to
/// @a constraintHolder (which may or may not be the superview itself).
///
/// @a constraints is expected to hold the current set of constraints that
/// resulted from a previous invocation of this method. The current set of
/// constraints is first removed from @a constraintHolder. @a constraints is
/// then emptied and a new set of constraints is calculated and added to
/// @a constraints. The new set is then added to @a constraintHolder.
///
/// The generated constraints satisfy the following layout requirements:
/// - The board view is square
/// - The board view size matches either the width or the height of the
///   superview, depending on which is the superview's smaller dimension. The
///   specified interface orientation @a interfaceOrientation, not the current
///   view size at the time this method is invoked, decides which is the smaller
///   dimension: A portrait orientation means that the width is smaller, a
///   landscape orientation means that the height is smaller. The reason for
///   this approach is that during interface orientation changes the superview's
///   current size may not be accurate.
/// - The board view is horizontally or vertically centered within its
///   superview, the axis depending on which is the superview's larger
///   dimension. The logic that determines the larger dimension is the inverse
///   of the logic that determines the smaller dimension.
// -----------------------------------------------------------------------------
+ (void) updateAutoLayoutConstraints:(NSMutableArray*)constraints
                         ofBoardView:(UIView*)boardView
             forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
                    constraintHolder:(UIView*)constraintHolder;
{
  [constraintHolder removeConstraints:constraints];
  [constraints removeAllObjects];

  UIView* superviewOfBoardView = boardView.superview;

  // Choose whichever is the superview's smaller dimension. We know that the
  // board view is constrained to be square, so we need to constrain only one
  // dimension to define the view size.
  NSLayoutAttribute dimensionToConstrain;
  // For the makeSquare... method we need to know if the width depends on the
  // height (i.e. the dimension to constrain is the height, and the width is
  // derived from the height), or if the dependency relationship is the other
  // way around.
  bool widthDependsOnHeight;
  // We also need to place the board view. The first part is to align it to one
  // of the superview edges from which it can freely flow to take up the entire
  // extent of the superview.
  NSLayoutAttribute alignConstraintAxis;
  // The second part of placing the board view is to center it on the axis on
  // which it won't take up the entire extent of the superview. This evenly
  // distributes the remaining space not taken up by the board view. Other
  // content can then be placed into that space.
  UILayoutConstraintAxis centerConstraintAxis;
  if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
  {
    dimensionToConstrain = NSLayoutAttributeWidth;
    widthDependsOnHeight = false;
    alignConstraintAxis = NSLayoutAttributeLeft;
    centerConstraintAxis = UILayoutConstraintAxisVertical;
  }
  else
  {
    dimensionToConstrain = NSLayoutAttributeHeight;
    widthDependsOnHeight = true;
    alignConstraintAxis = NSLayoutAttributeTop;
    centerConstraintAxis = UILayoutConstraintAxisHorizontal;
  }

  NSLayoutConstraint* aspectRatioConstraint = [AutoLayoutUtility makeSquare:boardView
                                                       widthDependsOnHeight:widthDependsOnHeight
                                                           constraintHolder:superviewOfBoardView];
  [constraints addObject:aspectRatioConstraint];

  NSLayoutConstraint* dimensionConstraint = [AutoLayoutUtility alignFirstView:boardView
                                                               withSecondView:superviewOfBoardView
                                                                  onAttribute:dimensionToConstrain
                                                             constraintHolder:superviewOfBoardView];
  [constraints addObject:dimensionConstraint];

  NSLayoutConstraint* alignConstraint = [AutoLayoutUtility alignFirstView:boardView
                                                           withSecondView:superviewOfBoardView
                                                              onAttribute:alignConstraintAxis
                                                         constraintHolder:superviewOfBoardView];
  [constraints addObject:alignConstraint];

  NSLayoutConstraint* centerConstraint = [AutoLayoutUtility centerSubview:boardView
                                                              inSuperview:superviewOfBoardView
                                                                   onAxis:centerConstraintAxis];
  [constraints addObject:centerConstraint];
}

@end
