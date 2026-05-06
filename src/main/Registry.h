// -----------------------------------------------------------------------------
// Copyright 2025-2026 Patrick Näf (herzbube@herzbube.ch)
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
@class ApplicationDelegate;
@class SceneDelegate;
@protocol MagnifyingGlassOwner;
@protocol ModelProvider;
@protocol PlayerClockService;
@protocol WindowProvider;


// -----------------------------------------------------------------------------
/// @brief The Registry class lets clients register (= store) references to
/// notable objects, so that these references can then later be retrieved. This
/// implements the Registry pattern. The goal is to reduce coupling between
/// parts of the application.
///
/// The Registry class provides a dedicated property for each notable object
/// that can be registered. A notable object reference is registered simply by
/// using the property setter, and the object reference is retrieved by using
/// the property getter. To unregister an object reference, invoke the setter
/// with value @e nil.
///
/// When an object reference is registered, Registry does @b not become the
/// owner of that object. It also does @b not send a retain() message to the
/// object. When an object that was previously registered will be deallocated,
/// it is the responsibility of the object owner to unregister the object
/// reference before it becomes invalid.
///
/// Registry is a singleton. Its shared instance is created when the registry is
/// accessed for the first time, and deallocated when the application
/// terminates.
// -----------------------------------------------------------------------------
@interface Registry : NSObject
{
}

+ (Registry*) sharedRegistry;
+ (void) releaseSharedRegistry;

@property(nonatomic, assign) ApplicationDelegate* applicationDelegate;
@property(nonatomic, assign) SceneDelegate* sceneDelegate;
@property(nonatomic, assign) id<ModelProvider> modelProvider;
@property(nonatomic, assign) id<MagnifyingGlassOwner> magnifyingGlassOwner;
@property(nonatomic, assign) id<WindowProvider> windowProvider;
@property(nonatomic, assign) id<PlayerClockService> playerClockService;

@end
