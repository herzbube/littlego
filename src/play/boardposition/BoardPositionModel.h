// -----------------------------------------------------------------------------
// Copyright 2012-2013 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The BoardPositionModel class provides user defaults data to its
/// clients that is related to board position viewing.
// -----------------------------------------------------------------------------
@interface BoardPositionModel : NSObject
{
}

- (id) init;
- (void) readUserDefaults;
- (void) writeUserDefaults;

@property(nonatomic, assign) bool discardFutureMovesAlert;
/// @brief This property is used to store the board position last viewed by the
/// user across application relaunches.
///
/// This property is updated to the current board position of the current
/// game in progress just before user defaults are written. This is guaranteed
/// to occur at the following times:
/// - When the application is suspended
/// - When the current game is backed up after a new move has been made
///
/// When the application terminates in any way, the value thus stored will be
/// read from from the user defaults when the application is launched the next
/// time. The value can then be used to restore the board position that was seen
/// before the application terminated.
///
/// @note Because this property is not updated on every change to the current
/// board position, an application crash may leave a stale value in the user
/// defaults on disk. A small amount of error handling is therefore necessary
/// when the board position is restored on application launch.
@property(nonatomic, assign) int boardPositionLastViewed;

@end
