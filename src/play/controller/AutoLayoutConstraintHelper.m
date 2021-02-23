// -----------------------------------------------------------------------------
// Copyright 2015-2021 Patrick Näf (herzbube@herzbube.ch)
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

  // We align two of the board view's edges with two of the superview's edges.
  // The edges are those which delimit the superview's smaller dimension.
  // Aligning the edges 1) defines the board view's size in that dimension,
  // and 2) places the board view along that axis.
  NSLayoutAnchor* boardViewEdge1;
  NSLayoutAnchor* boardViewEdge2;
  NSLayoutAnchor* superviewEdge1;
  NSLayoutAnchor* superviewEdge2;
  // For the makeSquare... method we need to know if the width depends on the
  // height (i.e. the dimension to constrain is the height, and the width is
  // derived from the height), or if the dependency relationship is the other
  // way around. Making the board view square fully defines its size.
  bool widthDependsOnHeight;
  // The second part of placing the board view is to center it on the axis on
  // which it won't take up the entire extent of the superview. This evenly
  // distributes the remaining space not taken up by the board view. Other
  // content can then be placed into that space.
  UILayoutConstraintAxis centerConstraintAxis;
  if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
  {
    boardViewEdge1 = boardView.leftAnchor;
    boardViewEdge2 = boardView.rightAnchor;
    if (@available(iOS 11.0, *))
    {
      superviewEdge1 = superviewOfBoardView.safeAreaLayoutGuide.leftAnchor;
      superviewEdge2 = superviewOfBoardView.safeAreaLayoutGuide.rightAnchor;
    }
    else
    {
      superviewEdge1 = superviewOfBoardView.leftAnchor;
      superviewEdge2 = superviewOfBoardView.rightAnchor;
    }
    widthDependsOnHeight = false;
    centerConstraintAxis = UILayoutConstraintAxisVertical;
  }
  else
  {
    boardViewEdge1 = boardView.topAnchor;
    boardViewEdge2 = boardView.bottomAnchor;
    if (@available(iOS 11.0, *))
    {
      superviewEdge1 = superviewOfBoardView.safeAreaLayoutGuide.topAnchor;
      superviewEdge2 = superviewOfBoardView.safeAreaLayoutGuide.bottomAnchor;
    }
    else
    {
      superviewEdge1 = superviewOfBoardView.topAnchor;
      superviewEdge2 = superviewOfBoardView.bottomAnchor;
    }
    widthDependsOnHeight = true;
    centerConstraintAxis = UILayoutConstraintAxisHorizontal;
  }

  NSLayoutConstraint* aspectRatioConstraint = [AutoLayoutUtility makeSquare:boardView
                                                       widthDependsOnHeight:widthDependsOnHeight
                                                           constraintHolder:superviewOfBoardView];
  [constraints addObject:aspectRatioConstraint];

  NSLayoutConstraint* constraintEdge1 = [boardViewEdge1 constraintEqualToAnchor:superviewEdge1];
  NSLayoutConstraint* constraintEdge2 = [boardViewEdge2 constraintEqualToAnchor:superviewEdge2];
  constraintEdge1.active = YES;
  constraintEdge2.active = YES;
  [constraints addObject:constraintEdge1];
  [constraints addObject:constraintEdge2];

  NSLayoutConstraint* centerConstraint = [AutoLayoutUtility centerSubview:boardView
                                                              inSuperview:superviewOfBoardView
                                                                   onAxis:centerConstraintAxis];
  [constraints addObject:centerConstraint];
}

@end
