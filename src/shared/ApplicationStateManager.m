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
/// @brief Is protected by applicationStateSaveLock
@property(nonatomic, assign) bool applicationStateSaveInProgress;
/// @brief Is protected by applicationStateSaveLock
@property(nonatomic, assign) UIBackgroundTaskIdentifier applicationStateSaveBackgroundTask;
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
  self.applicationStateSaveInProgress = false;
  self.applicationStateSaveBackgroundTask = UIBackgroundTaskInvalid;
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
    // TODO Should be invoked by classes in the Go package
    [self applicationStateDidChange];
  }
}

// -----------------------------------------------------------------------------
/// @brief Concludes the process of creating a save point. This method must be
/// invoked to balance a previous invocation of beginSavePoint.
///
/// The applicaton state is not yet saved if other commitSavePoint messages are
/// still outstanding.
///
/// See class documentation for details.
///
/// Raises an @e NSRangeException if this method is invoked without a previous
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
    {
      [self saveApplicationState];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) throwIfNumberOfOutstandingCommitsIsZero
{
  if (0 == self.numberOfOutstandingCommits)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Unbalanced call to commitSavePoint, number of outstanding commits is already 0"];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) saveApplicationState
{
  if (! self.applicationStateIsDirty)
    return;

  // Blocks if the lock is already acquired by applicationDidEnterBackground.
  // If the block occurs, we remain blocked until applicationWillEnterForeground
  // releases the lock.
  [self.applicationStateSaveLock lock];
  self.applicationStateSaveInProgress = true;
  [self.applicationStateSaveLock unlock];
  // If applicationDidEnterBackground is invoked now that the flag has been set,
  // applicationDidEnterBackground will create a background task that will spin
  // and keep the application running until we tell it to stop.

  self.applicationStateIsDirty = false;
  [[[[SaveApplicationStateCommand alloc] init] autorelease] submit];

  [self.applicationStateSaveLock lock];
  self.applicationStateSaveInProgress = false;
  if (UIBackgroundTaskInvalid != self.applicationStateSaveBackgroundTask)
  {
    UIApplication* application = [UIApplication sharedApplication];
    [application endBackgroundTask:self.applicationStateSaveBackgroundTask];
    self.applicationStateSaveBackgroundTask = UIBackgroundTaskInvalid;
  }
  [self.applicationStateSaveLock unlock];
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
// -----------------------------------------------------------------------------
- (void) restoreApplicationState
{
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
/// @brief Notifies this ApplicationStateManager that the application state
/// changed and needs to be saved when the next save point is created.
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
  [self.applicationStateSaveLock lock];
  if (self.applicationStateSaveInProgress)
  {
    // The job of the expiration handler is to end the background task in an
    // orderly fashion. If the handler does not return quickly, the application
    // will be killed by the OS. It is *NOT* possible for the expiration handler
    // to request more time by starting another background task (if it tries,
    // the application is killed). Requesting more time is the job of the
    // background task itself. UIApplication.backgroundTimeRemaining helps to
    // find out when this is necessary.
    //
    // In an experiment made with the iOS 4.2 simulator it took approximately
    // 10 minutes for the expiration handler to be invoked. The current
    // background task implementation should never take that long, therefore
    // there is no handling at all for requesting more time. The expiration
    // handler simply shuts down the background task and hopes for the best,
    // namely that the application comes back to the foreground and the state
    // saving process can continue. If this does not happen, we might be in
    // trouble if a half-baked NScoding archive were written on disk...
    void (^expirationHandler) (void) =
    ^(void)
    {
      DDLogError(@"ApplicationStateManager: Background task expiration handler invoked");
      [self.applicationStateSaveLock lock];
      if (UIBackgroundTaskInvalid != self.applicationStateSaveBackgroundTask)
      {
        UIApplication* app = [UIApplication sharedApplication];
        [app endBackgroundTask:self.applicationStateSaveBackgroundTask];
        self.applicationStateSaveBackgroundTask = UIBackgroundTaskInvalid;
      }
      [self.applicationStateSaveLock unlock];
    };
    UIApplication* app = [UIApplication sharedApplication];
    self.applicationStateSaveBackgroundTask = [app beginBackgroundTaskWithExpirationHandler:expirationHandler];
    [self.applicationStateSaveLock unlock];
  }
  else
  {
    // Do NOT unlock self.applicationStateSaveLock! If saveApplicationState is
    // called now, it will block and can't start to write the application state
    // while the application is in the middle of going to the background. If
    // saveApplicationState were allowed to start writing, it would probably be
    // interrupted halfway through when the system suspends the application.
    // This might leave us with a half-baked NSCoding archive on disk. If the
    // application were then killed, the next launch would try to restore from
    // this half-baked archive - definitely not good!
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
