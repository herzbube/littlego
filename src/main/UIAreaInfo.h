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


// -----------------------------------------------------------------------------
/// @brief The UIAreaInfo category adds a property to UIViewController that
/// allows to associate the view controller with an UIArea value.
// -----------------------------------------------------------------------------
@interface UIViewController(UIAreaInfo)

/// @brief The UIArea value associated with this view controller. If not
/// explicitly set the default value of this property is #UIAreaUnknown.
@property(nonatomic, assign) enum UIArea uiArea;

@end
