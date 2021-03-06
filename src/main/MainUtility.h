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


// Forward declarations
@protocol MagnifyingGlassOwner;


// -----------------------------------------------------------------------------
/// @brief The MainUtility class is a container for various utility functions
/// related to managing the main navigation of the application.
///
/// All functions in MainUtility are class methods, so there is no need to
/// create an instance of MainUtility.
// -----------------------------------------------------------------------------
@interface MainUtility : NSObject
{
}

+ (NSString*) titleStringForUIArea:(enum UIArea)uiArea;
+ (NSString*) iconResourceNameForUIArea:(enum UIArea)uiArea;
+ (UIViewController*) rootViewControllerForUIArea:(enum UIArea)uiArea;
+ (UIView*) rootViewForUIAreaPlay;
+ (NSString*) resourceNameForUIArea:(enum UIArea)uiArea;
+ (void) activateUIArea:(enum UIArea)uiArea;
+ (void) mainApplicationViewController:(UIViewController*)viewController didDisplayUIArea:(enum UIArea)uiArea;
+ (id<MagnifyingGlassOwner>) magnifyingGlassOwner;

@end
