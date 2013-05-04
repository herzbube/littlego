// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class NavigationBarController;
@class ScrollViewController;


// -----------------------------------------------------------------------------
/// @brief The PlayTabController class is the main view controller on the
/// "Play" tab.
///
/// PlayTabController arranges its child view controllers differently depending
/// on the device that runs the application.
// -----------------------------------------------------------------------------
@interface PlayTabController : UIViewController
{
}

@property(nonatomic, retain) NavigationBarController* navigationBarController;
@property(nonatomic, retain) ScrollViewController* scrollViewController;
@property(nonatomic, retain) UIViewController* boardPositionController;

@end
