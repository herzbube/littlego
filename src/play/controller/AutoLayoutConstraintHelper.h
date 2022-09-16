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
/// @brief The AutoLayoutConstraintHelper class is a container for helper
/// functions related to managing Auto Layout constraints on the #UIAreaPlay.
///
/// All functions in AutoLayoutConstraintHelper are class methods, so there is
/// no need to create an instance of AutoLayoutUtility.
// -----------------------------------------------------------------------------
@interface AutoLayoutConstraintHelper : NSObject
{
}

+ (void) updateAutoLayoutConstraints:(NSMutableArray*)constraints
                         ofBoardView:(UIView*)boardView
                             forAxis:(UILayoutConstraintAxis)axis
                    constraintHolder:(UIView*)constraintHolder;

@end
