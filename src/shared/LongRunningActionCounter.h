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


// -----------------------------------------------------------------------------
/// @brief The LongRunningActionCounter class is a wrapper around a global
/// counter. The purpose of the counter is to keep track of the number of
/// long-running actions that are currently in progress.
/// LongRunningActionCounter is responsible for posting notifications when
/// certain events related to the counter occur.
///
///
/// @par Purpose of long-running actions
///
/// A long-running action is an operation that is known to trigger many UI
/// updates on the Play tab. When a long-running action starts, an interested
/// party may start to delay view updates (or other similar expensive
/// operations) until the long-running action ends. All UI updates that have
/// accumulated since the start of the action are then coalesced and performed
/// as a single UI update.
///
/// Long-running actions can be nested. UI updates will be delayed until the
/// outermost action ends.
///
/// The typical example for a long-running action is loading a game from the
/// archive. Without the concept of long-running actions, the entire Go board
/// would need to be redrawn for each move in the archived game being replayed.
///
///
/// @par Counter mechanics
///
/// When a long-running action starts, the party responsible for starting the
/// action must increment the counter encapsulated by the shared
/// LongRunningActionCounter object. Correspondingly, when the action ends the
/// responsible party must decrement the counter.
///
/// When the counter is incremented to 1, LongRunningActionCounter posts the
/// #longRunningActionStarts notification to the default NSNotificationCenter.
/// Observers may now start to delay UI updates.
///
/// When the counter is decremented to 0, LongRunningActionCounter posts the
/// #longRunningActionEnds notification to the default NSNotificationCenter.
/// Observers may now perform delayed UI updates and resume their regular UI
/// update regime.
///
/// Parties that increment or decrement the counter must do so at a time when
/// GoGame and its associated object cluster are in a consistent state.
/// This allows observers, when they are notified, to safely query GoGame and
/// its associated object cluster.
///
/// Observers can be created at any time during the application's life-cycle,
/// even at a time when a long-running action is in progress. Observers should
/// therefore query LongRunningActionCounter as part of their initialization
/// routine.
///
///
/// @par Multi-threading
///
/// The #longRunningActionStarts and #longRunningActionEnds notifications are
/// guaranteed to be delivered in the context of the main thread.
///
/// Parties that increment or decrement the counter may do so in the context
/// of any thread. However, if necessary LongRunningActionCounter will switch
/// to the main thread in order to post one of the notifications. The switch
/// is performed synchronously so that observers are guaranteed to find GoGame
/// and its associated object cluster in a consistent state.
///
/// @a attention No long-running actions must be started or stopped while the
/// #longRunningActionStarts and #longRunningActionEnds notifications are
/// delivered. LongRunningActionCounter does not gracefully handle a violation
/// of this rule, it immediately raises an exception.
///
///
/// @par LongRunningActionCounter life-cycle
///
/// LongRunningActionCounter is a singleton. Its shared instance is created
/// when the counter is accessed for the first time, and deallocated when the
/// application terminates.
// -----------------------------------------------------------------------------
@interface LongRunningActionCounter : NSObject
{
}

+ (LongRunningActionCounter*) sharedCounter;
+ (void) releaseSharedCounter;

- (void) increment;
- (void) decrement;

@property(atomic, assign, readonly) int counter;

@end

