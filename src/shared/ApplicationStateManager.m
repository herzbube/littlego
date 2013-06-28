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


// Project includes
#import "ApplicationStateManager.h"
#import "../command/CommandProcessor.h"
#import "../command/applicationstate/RestoreApplicationStateCommand.h"
#import "../command/applicationstate/SaveApplicationStateCommand.h"
#import "../command/backup//RestoreGameCommand.h"
#import "../command/game/NewGameCommand.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ApplicationStateManager.
// -----------------------------------------------------------------------------
@interface ApplicationStateManager()
/// @brief Is protected by @synchronized(self)
@property(nonatomic, assign) int numberOfOutstandingCommits;
/// @brief Is protected by @synchronized(self)
@property(nonatomic, assign) bool applicationStateIsDirty;
/// @brief Is created during initialization, so no need for atomic.
@property(nonatomic, retain) NSLock* applicationStateSaveLock;
/// @brief Does not need protection, is accessed only by methods that are
/// guaranteed to be executed in the context of the same thread.
@property(nonatomic, assign) bool applicationStateSaveLockAcquiredForBackground;
/// @brief Does not need protection, the entire restore process is guaranteed
/// to be executed synchronously.
@property(nonatomic, assign) bool applicationStateRestoreInProgress;
@end


@implementation ApplicationStateManager

// -----------------------------------------------------------------------------
/// @brief Shared instance of ApplicationStateManager.
// -----------------------------------------------------------------------------
static ApplicationStateManager* sharedManager = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared ApplicationStateManager object.
// -----------------------------------------------------------------------------
+ (ApplicationStateManager*) sharedManager
{
  @synchronized(self)
  {
    if (! sharedManager)
      sharedManager = [[ApplicationStateManager alloc] init];
    return sharedManager;
  }
}

// -----------------------------------------------------------------------------
/// @brief Releases the shared ApplicationStateManager object.
// -----------------------------------------------------------------------------
+ (void) releaseSharedManager
{
  @synchronized(self)
  {
    if (sharedManager)
    {
      [sharedManager release];
      sharedManager = nil;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Initializes a ApplicationStateManager object.
///
/// @note This is the designated initializer of ApplicationStateManager.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.numberOfOutstandingCommits = 0;
  self.applicationStateIsDirty = false;
  self.applicationStateSaveLock = [[[NSLock alloc] init] autorelease];
  self.applicationStateSaveLockAcquiredForBackground = false;
  self.applicationStateRestoreInProgress = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ApplicationStateManager object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.applicationStateSaveLock = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Begins the process of creating a save point. Invocation of this
/// method must be balanced by also invoking commitSavePoint.
///
/// See class documentation for details.
// -----------------------------------------------------------------------------
- (void) beginSavePoint
{
  if (self.applicationStateRestoreInProgress)
    return;
  @synchronized(self)
  {
    self.numberOfOutstandingCommits++;
  }
}

// -----------------------------------------------------------------------------
/// @brief Concludes the process of creating a save point. This method must be
/// invoked to balance a previous invocation of beginSavePoint.
///
/// Invokes saveApplicationState if no other commitSavePoint messages are
/// outstanding.
///
/// See class documentation for details.
///
/// Raises an @e NSGenericException if this method is invoked without a previous
/// invocation of beginSavePoint.
// -----------------------------------------------------------------------------
- (void) commitSavePoint
{
  if (self.applicationStateRestoreInProgress)
    return;
  @synchronized(self)
  {
    [self throwIfNumberOfOutstandingCommitsIsZero];
    self.numberOfOutstandingCommits--;
    if (0 == self.numberOfOutstandingCommits)
      [self saveApplicationState];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) throwIfNumberOfOutstandingCommitsIsZero
{
  if (0 == self.numberOfOutstandingCommits)
  {
    NSString* errorMessage = @"Unbalanced call to commitSavePoint, number of outstanding commits is already 0";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Saves the application state to an NSCoding archive if
/// applicationStateDidChange has been invoked since the last state save.
///
/// Raises an @e NSGenericException if this method is invoked while there are
/// still outstanding commitSavePoint messages.
// -----------------------------------------------------------------------------
- (void) saveApplicationState
{
  if (self.applicationStateRestoreInProgress)
    return;
  @synchronized(self)
  {
    [self throwIfNumberOfOutstandingCommitsIsNotZero];
    if (! self.applicationStateIsDirty)
      return;

    // Blocks if the lock was acquired and not released by
    // applicationDidEnterBackground. If the block occurs, we remain blocked
    // until applicationWillEnterForeground releases the lock.
    [self.applicationStateSaveLock lock];
    // We don't need to hold the lock, @synchronized(self) further up already
    // protects us against interference from applicationDidEnterBackground
    [self.applicationStateSaveLock unlock];

    self.applicationStateIsDirty = false;
    [[[[SaveApplicationStateCommand alloc] init] autorelease] submit];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) throwIfNumberOfOutstandingCommitsIsNotZero
{
  if (0 != self.numberOfOutstandingCommits)
  {
    NSString* errorMessage = @"Attempt to save the application state while there are still outstanding commits";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Restores the application state to a previously saved state,
///
/// The procedure is as follows:
/// - The previously saved application state consists of two files: A primary
///   NSCoding archive file, and a secondary .sgf file.
/// - ApplicationStateManager first tries to restore the application state from
///   the NSCoding archive. If this succeeds it ignores the .sgf file.
/// - If restoring from the NSCoding archive fails, ApplicationStateManager
///   falls back to the .sgf file: It performs a LoadGameCommand to at least
///   recover the moves stored in the .sgf file. All the other aspects of the
///   application state that are beyond the raw game moves cannot be restored
///   in this fallback scenario (e.g. the board position that the user was
///   viewing, any scoring mode information, the GoGameDocument dirty flag).
///
/// The main reason why the fallback scenario exists is so that a game can be
/// restored after the application was upgraded to a new version via App Store,
/// and that new app version uses a different NSCoding version. Having a
/// different NSCoding version makes the backup NSCoding archive useless because
/// it is incompatible with the new app version. The .sgf file, on the other
/// hand, is expected to remain readable at all times.
///
/// Raises an @e NSGenericException if this method is not invoked in the context
/// of the command processor secondary thread. Reason: This method expects to
/// run from start to end fully synchronously. This happens only if this method
/// is invoked in the context of the command processor secondary thread, i.e. if
/// if it is executed by an asynchronous command. Why: This method indirectly
/// executes LoadGameCommand, which is an asynchronous command, and asynchronous
/// commands happen to run synchronously only if they are executed by another
/// asynchronous command.
// -----------------------------------------------------------------------------
- (void) restoreApplicationState
{
  [self throwIfCurrentThreadIsNotCommandProcessorThread];
  self.applicationStateRestoreInProgress = true;
  bool success = [[[[RestoreApplicationStateCommand alloc] init] autorelease] submit];
  if (! success)
  {
    success = [[[[RestoreGameCommand alloc] init] autorelease] submit];
    if (! success)
      [[[[NewGameCommand alloc] init] autorelease] submit];
  }
  self.applicationStateRestoreInProgress = false;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) throwIfCurrentThreadIsNotCommandProcessorThread
{
  if (! [CommandProcessor sharedProcessor].currentThreadIsCommandProcessorThread)
  {
    NSString* errorMessage = @"restoreApplicationState must be invoked in the context of the CommandProcessor secondary thread";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Notifies this ApplicationStateManager that the application state has
/// changed and needs to be saved when saveApplicationState is invoked the next
/// time.
// -----------------------------------------------------------------------------
- (void) applicationStateDidChange
{
  if (self.applicationStateRestoreInProgress)
    return;
  @synchronized(self)
  {
    self.applicationStateIsDirty = true;
  }
}

// -----------------------------------------------------------------------------
/// @brief Notifies this ApplicationStateManager that the application has just
/// entered the background and will be suspended soon after this method returns.
// -----------------------------------------------------------------------------
- (void) applicationDidEnterBackground
{
  // Blocks if someone is in the middle of beginSavePoint, commitSavePoint,
  // saveApplicationState or applicationStateDidChange. At the maximum we have
  // to wait for the application state to be saved.
  @synchronized(self)
  {
    if (self.numberOfOutstandingCommits > 0)
    {
      // We don't start a background task because we don't want to wait until
      // all outstanding commits have been made: If the user suspends the app
      // while it is in the middle of doing something, the user possibly wants
      // to prevent the app from finishing its task.
    }
    else
    {
      if (self.applicationStateIsDirty)
      {
        // No outstanding commits, but the dirty flag is set? This can only mean
        // that some agent has meant to delay state saving, so let's do this
        // now.
        [self saveApplicationState];
      }
    }

    // We need to make sure that saveApplicationState is not executed after we
    // release the lock acquired by @synchronized(self). For this purpose
    // we acquire self.applicationStateSaveLock and do NOT release it. If
    // saveApplicationState is called now, it will block and can't start to
    // write the application state while the application is in the middle of
    // going to the background. If saveApplicationState were allowed to start
    // writing, it would probably be interrupted halfway through when the
    // system suspends the application. This might leave us with a half-baked
    // NSCoding archive on disk. If the application were then killed, the next
    // launch would try to restore from this half-baked archive - definitely
    // not good!
    [self.applicationStateSaveLock lock];
    self.applicationStateSaveLockAcquiredForBackground = true;
  }
}

// -----------------------------------------------------------------------------
/// @brief Notifies this ApplicationStateManager that the application has just
/// come back to the foreground and will resume its regular operation soon after
/// this method returns.
// -----------------------------------------------------------------------------
- (void) applicationWillEnterForeground
{
  // Assume that applicationWillEnterForeground is invoked in the context of
  // the same thread that also invokes applicationDidEnterBackground, so that
  // we can safely access the following flag
  if (self.applicationStateSaveLockAcquiredForBackground)
  {
    // Unlocking will unblock saveApplicationState if it was blocked
    [self.applicationStateSaveLock unlock];
  }
}

@end
