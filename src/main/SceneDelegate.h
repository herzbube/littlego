// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
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
#import "WindowProvider.h"

// Forward declarations
@protocol MagnifyingGlassOwner;


// -----------------------------------------------------------------------------
/// @brief The SceneDelegate class implements the role of the UIWindowScene
/// delegate. It supports the application's scene-based life cycle.
///
/// Currently there can be only one SceneDelegate object, and multiple scenes
/// (an iPad feature) are not supported.
///
/// @note It's not clear why the scene delegate needs to be a subclass of
/// UIResponder. This was taken over from the implementation example in TN3187
/// when the migration from the app-wide life cycle was done.
// -----------------------------------------------------------------------------
@interface SceneDelegate : UIResponder <UIWindowSceneDelegate, WindowProvider>
{
}

+ (SceneDelegate*) sharedDelegate;

@end

