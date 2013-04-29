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
/// @brief The ApplicationStateManager class is responsible for saving the
/// application state at the appropriate time.
///
/// The application state is saved as an NSCoding archive that represents the
/// in-memory objects of GoGame and its associated object cluster. The
/// appropriate time to save the application state is when GoGame and its
/// associated objects are in a consistent state (e.g. not in the middle of
/// playing a move; or not in the middle of changing the board position; etc.).
///
/// The following pieces of knowledge and their holders can be distinguished:
/// - Command classes and other agents have the knowledge 1) that they do modify
///   the application state, 2) when they start with these modifications, and
///   3) when they are finished with these modifications
/// - GoGame and other classes in the Go package know what data is changed
///
/// ApplicationStateManager is the mediator between these knowledge holders. By
/// notifying ApplicationStateManager appropriately, these knowledge holders
/// allow ApplicationStateManager to figure out the right moment when it is safe
/// to save the application state (a so-called "save point"), and also what
/// parts need to be saved.
///
/// These are the mechanics:
/// - An agent (e.g. a command) first invokes beginSavePoint. It does so
///   @b before it starts to modify any application state data. Invoking
///   beginSavePoint indicates to ApplicationStateManager that application state
///   data is now potentially inconsistent and must not be saved until further
///   notice.
/// - The agent then invokes commitSavePoint. It does so @b after it has
///   finished modifying all application state data. Invoking commitSavePoint
///   indicates to ApplicationStateManager that application state data is now
///   consistent again and can be saved.
/// - ApplicationStateManager keeps track of how many beginSavePoint messages
///   it receives. It will save the application state (i.e. create a save point)
///   only after it receives a matching number of commitSavePoint messages. This
///   allows agents to be nested, without individual agents having to know
///   about this, or about each other.
/// - GoGame and its associated object cluster notify ApplicationStateManager
///   when they are changed. This allows ApplicationStateManager to keep track
///   of what needs to be saved when it finally creates the save point.
///
/// @note The last point has not been fully implemented yet, at the moment
/// ApplicationStateManager will just save the entire application state whenever
/// any change is reported by GoGame et al.
///
/// These are the advantages of the system:
/// - Reduces complexity because agents do not have to know about each other,
///   or about the overall grand scheme.
/// - More important still, the overall system becomes more flexible and
///   friendly to change. For instance, it is no longer a problem if commands
///   that previously were executed standalone are suddenly executed nested.
///
///
/// @par Multi-threading
///
/// ApplicationStateManager is thread-safe, i.e. agents can invoke
/// beginSavePoint and commitSavePoint in the context of any thread. When a
/// matching number of commitSavePoint messages have been received, a save point
/// is created and the application state is saved immediately, in the context of
/// whatever thread has invoked commitSavePoint. Not using any delay is the only
/// way how ApplicationStateManager can guarantee that a save point is created
/// without any interruption by some other agent invoking beginSavePoint.
///
/// If an agent invokes beginSavePoint from another thread context while
/// ApplicationStateManager is in the process of saving the application state,
/// that agent is blocked until the process is complete.
///
///
/// @par Application foreground and background
///
/// The application delegate notifies ApplicationStateManager when the
/// application goes to the background or comes back to the foreground.
///
/// If the application goes to the background while ApplicationStateManager is
/// in the process of saving the application state, ApplicationStateManager
/// starts a background operation that allows it to complete the process.
///
/// If the application goes to the background while ApplicationStateManager is
/// not in the process of saving the application state, but there are still
/// some agents that hold unfinished save points, ApplicationStateManager makes
/// sure that the state-saving process is not initiated in the middle of the
/// going-to-background process. Agents are still allowed to invoke
/// commitSavePoint, but if this would result in saving the application state
/// the invoking thread is blocked.
///
/// When the application comes back to the foreground, everything continues as
/// normal: A thread that was blocked because it tried to save the application
/// state from within commitSavePoint is unblocked. Agents that hold unfinished
/// save points simply resume their operation.
///
/// If the application is killed while it is in the background, any unfinished
/// save points are lost.
///
///
/// @par Application launch
///
/// The application delegate notifies ApplicationStateManager when the
/// application launches.
///
/// If ApplicationStateManager detects an NSCoding archive that represents the
/// saved application state, it restores that state. During a restore operation
/// ApplicationStateManager ignores all requests to create a save point and to
/// set any dirty flags.
///
/// Nothing special happens if the application goes to the background while a
/// restore operation is in progress. When the application comes back to the
/// foreground, the restore operation simply resumes where it was suspended.
///
///
/// @par ApplicationStateManager life-cycle
///
/// ApplicationStateManager is a singleton. Its shared instance is created
/// when the manager is accessed for the first time, and deallocated when the
/// application terminates.
// -----------------------------------------------------------------------------
@interface ApplicationStateManager : NSObject
{
}

+ (ApplicationStateManager*) sharedManager;
+ (void) releaseSharedManager;

- (void) beginSavePoint;
- (void) commitSavePoint;
- (void) restoreApplicationState;
- (void) applicationStateDidChange;
- (void) applicationDidEnterBackground;
- (void) applicationWillEnterForeground;

@end
