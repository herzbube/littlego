// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The SoundHandling class triggers sound and vibration in reaction to
/// the computer player making a move.
///
/// Sound and/or vibration is triggered only if both of the following is true:
/// - The corresponding feature is turned on in the user preferences
/// - The player whose turn it is, is human. If both players are computer
///   players, or if the computer has just played on behalf of the human
///   player, then no sound and/or vibration is triggered.
///
/// Sound and vibration may be temporarily disabled to prevent any disturbances,
/// e.g. while the user is answering a phone call.
// -----------------------------------------------------------------------------
@interface SoundHandling : NSObject
{
}

- (id) init;

/// @brief If flag is set, no sound/vibration is triggered. Used to temporarily
/// disable disturbances, e.g. while the user is answering a phone call.
@property(getter=isDisabled) bool disabled;

@end
