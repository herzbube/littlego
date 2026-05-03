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
#import "FilesystemMonitor.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for FilesystemMonitor.
// -----------------------------------------------------------------------------
@interface FilesystemMonitor()
@property(nonatomic, retain) NSURL* url;
@property(nonatomic, assign) id<FilesystemMonitorDelegate> delegate;
@property(nonatomic, assign) int fileDescriptor;
@property(nonatomic, retain) dispatch_source_t source;
@property(nonatomic, assign, readwrite) bool isMonitoringStarted;
@property(nonatomic, assign) bool stopMonitoringInitiated;
@property(nonatomic, assign) bool restartMonitoringInitiated;
@property(nonatomic, assign) bool cancelMonitoringInitiated;
@property(nonatomic, retain) dispatch_semaphore_t stopMonitoringSemaphore;
@end


@implementation FilesystemMonitor

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a FilesystemMonitor object with @a url.
///
/// @note This is the designated initializer of FilesystemMonitor.
// -----------------------------------------------------------------------------
- (id) initWithURL:(NSURL*)url delegate:(id<FilesystemMonitorDelegate>)delegate;
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.url = url;
  self.delegate = delegate;

  self.fileDescriptor = 0;
  self.source = nil;

  self.isMonitoringStarted = false;
  self.stopMonitoringInitiated = false;
  self.restartMonitoringInitiated = false;
  self.cancelMonitoringInitiated = false;
  // Dispatch objects are built as Objective-C types and therefore participate
  // in memory management. dispatch_semaphore_create() returns an object with
  // a retain count 1, therefore we have to autorelease it before storing it in
  // a property declared with "retain".
  self.stopMonitoringSemaphore = [dispatch_semaphore_create(0) autorelease];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this FilesystemMonitor object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.url = nil;
  self.delegate = nil;

  // Dispatch objects are built as Objective-C types and therefore participate
  // in memory management. Setting properties declared with "retain" to nil
  // therefore releases the underlying dispatch objects.
  self.source = nil;
  self.stopMonitoringSemaphore = nil;

  [super dealloc];
}

#pragma mark - Starting/stopping monitoring

// -----------------------------------------------------------------------------
/// @brief Starts monitoring the URL specified during initialization. Returns
/// @e true if monitoring could be started, otherwise returns @e false. Does
/// nothing if monitoring is already started but still returns @e true.
///
/// Monitoring cannot be started if the URL specified during initialization
/// refers to a non-existing filesystem entry.
///
/// Once monitoring is started, it must also be stopped, otherwise this
/// FilesystemMonitor can never be deallocated.
// -----------------------------------------------------------------------------
- (bool) startMonitoring
{
  @synchronized(self)
  {
    if (self.isMonitoringStarted)
      return true;

    self.fileDescriptor = open(self.url.path.fileSystemRepresentation, O_EVTONLY);
    if (self.fileDescriptor == -1)
    {
      DDLogError(@"%@: start monitoring failed, open() returned an invalid file descriptor for %@, errno = %d", self, self.url, errno);
      return false;
    }

    dispatch_queue_t mainQueue = dispatch_get_main_queue();

    dispatch_source_vnode_flags_t events = (DISPATCH_VNODE_ATTRIB |
                                            DISPATCH_VNODE_DELETE |
                                            DISPATCH_VNODE_EXTEND |
                                            DISPATCH_VNODE_LINK |
                                            DISPATCH_VNODE_RENAME |
                                            DISPATCH_VNODE_REVOKE |
                                            DISPATCH_VNODE_WRITE);
    // Dispatch objects are built as Objective-C types and therefore participate
    // in memory management. dispatch_source_create() returns an object with
    // a retain count 1, therefore we have to autorelease it before storing it
    // in a property declared with "retain".
    self.source = [dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                          self.fileDescriptor,
                                          events,
                                          mainQueue) autorelease];

    // This event handler asynchronously notifies the delegate. Because we used
    // the main queue when creating self.source, and the main queue is bound to
    // the main thread, the handler will be executed on the main thread.
    // Note: The code block has a reference to self, so FilesystemMonitor can
    // only be deallocated after monitoring has stopped.
    dispatch_source_set_event_handler(self.source, ^{
      dispatch_source_vnode_flags_t eventTypes = dispatch_source_get_data(self.source);
      [self notifyDelegate:eventTypes];
    });

    // This cancel handler is invoked asynchronously whenever someone calls
    // dispatch_source_cancel(). Observed in simulator:
    // - When using the main queue, the cancel handler is executed on the main
    //   thread
    // - When using the default queue (DISPATCH_QUEUE_PRIORITY_DEFAULT), the
    //   cancel handler is not executed on the main thread.
    // Note: The code block has a reference to self, so FilesystemMonitor can
    // only be deallocated after monitoring has stopped.
    dispatch_source_set_cancel_handler(self.source, ^{
      [self handleCancelingMonitoring];
    });

    // Start the actual monitoring
    dispatch_resume(self.source);

    self.isMonitoringStarted = true;
    return true;
  }
}

// -----------------------------------------------------------------------------
/// @brief Stops monitoring the URL specified during initialization. Does
/// nothing if monitoring is currently not started, or a stop monitoring request
/// is already ongoing.
///
/// Stopping the monitoring is actually an asynchronous operation, but this
/// method takes the necessary synchronization steps to make sure that when
/// control returns to the caller the monitoring has actually stopped. However,
/// the asynchronous nature of the stopping operation has some consequences:
/// - While the stopping operation is ongoing there is a chance that the
///   delegate may still receive notifications.
/// - Invoking startMonitoring() while the stopping operation is ongoing has
///   no effect, in particular it does not prevent the stopping operation from
///   completing. This scenario should be unlikely, though, because it would
///   require that startMonitoring() is invoked from a different thread than the
///   one from which stopMonitoring() was invoked.
// -----------------------------------------------------------------------------
- (void) stopMonitoring
{
  @synchronized(self)
  {
    if (! self.isMonitoringStarted || self.stopMonitoringInitiated)
      return;
    self.stopMonitoringInitiated = true;

    // Canceling could already be initiated, but because we have the
    // @synchronized lock we know that handleCancelingMonitoring() cannot
    // currently be executing.

    if (! self.cancelMonitoringInitiated)
    {
      self.cancelMonitoringInitiated = true;
      dispatch_source_cancel(self.source);
    }
  }

  // Waiting for the semaphore has to be done after we have relinquished the
  // @synchronized lock, so that handleCancelingMonitoring() can execute.
  [self waitForMonitoringToBeStopped];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for stopMonitoring().
// -----------------------------------------------------------------------------
- (void) waitForMonitoringToBeStopped
{
  if ([NSThread isMainThread])
  {
    // If this method is executing on the main thread, then we need to poll the
    // semaphore and give the main thread time in between each poll to run its
    // event loop. The reason is that GCD may schedule execution of
    // handleCancelingMonitoring() also on the main thread (in fact, we expect
    // GCD to schedule on the main thread because startMonitoring() used the
    // main GCD queue to set up monitoring).
    DDLogInfo(@"%@: waitForMonitoringToBeStopped executes on main thread and uses semaphore polling to wait", self);
    while (dispatch_semaphore_wait(self.stopMonitoringSemaphore, DISPATCH_TIME_NOW))
    {
      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    }
  }
  else
  {
    // If this method is not executing on the main thread, then we can use a
    // blocking call to wait for the semaphore to be signalled. The expectation
    // is that GCD will not schedule execution of handleCancelingMonitoring()
    // on the same non-main thread.
    DDLogInfo(@"%@: waitForMonitoringToBeStopped executes on non-main thread and uses blocking call to wait", self);
    dispatch_semaphore_wait(self.stopMonitoringSemaphore, DISPATCH_TIME_FOREVER);
  }
}

#pragma mark - Handler methods

// -----------------------------------------------------------------------------
/// @brief Notifies the delegate about all events in @a eventTypes.
///
/// This handler is invoked asynchronously.
///
/// Because startMonitoring() used the GCD main queue to set up monitoring, this
/// handler is expected to be invoked in the context of the main thread. This
/// is actually a requirement because FilesytemMonitor guarantees that the
/// delegate is notified on the main thread.
// -----------------------------------------------------------------------------
- (void) notifyDelegate:(dispatch_source_vnode_flags_t)eventTypes
{
  // Note that as a result of being notified, the delegate may decide (for
  // reasons of their own) to invoke startMonitoring() and/or stopMonitoring()
  // multiple times and in any order. Because @synchronized creates a recursive
  // lock, these methods will NOT be blocked by the @synchronized lock we
  // acquire here.
  @synchronized(self)
  {
    bool restartMonitoring = false;

    if (eventTypes & DISPATCH_VNODE_ATTRIB)
    {
      [self.delegate filesystemMonitor:self
                        changeOccurred:FilesystemMonitorChangeTypeMetadataChanged
                                   url:self.url];
    }

    if (eventTypes & DISPATCH_VNODE_DELETE)
    {
      // Mitigate deleting overwrites - see class documentation for details
      restartMonitoring = true;
      [self.delegate filesystemMonitor:self
                        changeOccurred:FilesystemMonitorChangeTypeDeleted
                                   url:self.url];
    }

    if (eventTypes & DISPATCH_VNODE_EXTEND)
    {
      [self.delegate filesystemMonitor:self
                        changeOccurred:FilesystemMonitorChangeTypeSizeChanged
                                   url:self.url];
    }

    if (eventTypes & DISPATCH_VNODE_LINK)
    {
      [self.delegate filesystemMonitor:self
                        changeOccurred:FilesystemMonitorChangeTypeObjectLinkCountChanged
                                   url:self.url];
    }

    if (eventTypes & DISPATCH_VNODE_RENAME)
    {
      // Monitoring will continue working after a rename, but self.url will
      // continue to refer to the old path. There is no way to obtain the new
      // path from self.fileDescriptor (fstat can provide the inode, but even
      // searching the whole filesystem for the inode may be inconclusive,
      // because an inode can have many filesystem entries - see hard links).
      [self.delegate filesystemMonitor:self
                        changeOccurred:FilesystemMonitorChangeTypeRenamed
                                   url:self.url];
    }

    if (eventTypes & DISPATCH_VNODE_REVOKE)
    {
      [self.delegate filesystemMonitor:self
                        changeOccurred:FilesystemMonitorChangeTypeRevoked
                                   url:self.url];
    }

    if (eventTypes & DISPATCH_VNODE_WRITE)
    {
      [self.delegate filesystemMonitor:self
                        changeOccurred:FilesystemMonitorChangeTypeDataChanged
                                   url:self.url];
    }

    if (restartMonitoring && ! self.restartMonitoringInitiated)
    {
      self.restartMonitoringInitiated = true;

      // Canceling could already be initiated, but because we have the
      // @synchronized lock we know that handleCancelingMonitoring() cannot
      // currently be executing.

      if (! self.cancelMonitoringInitiated)
      {
        self.cancelMonitoringInitiated = true;
        dispatch_source_cancel(self.source);
      }
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Handles the canceling of the monitoring.
///
/// This handler is invoked asynchronously.
///
/// Because startMonitoring() used the GCD main queue to set up monitoring, this
/// handler is expected to be invoked in the context of the main thread. This
/// is not a requirement though, the implementation of FilesystemMonitor can
/// also deal with this handler being invoked in the context of a non-main
/// thread.
// -----------------------------------------------------------------------------
- (void) handleCancelingMonitoring
{
  @synchronized (self)
  {
    // If monitoring was explicitly stopped, then we must not restart it again.
    // Both of these flags could be true if the delegate stopped monitoring
    // while it was being notified
    if (self.stopMonitoringInitiated && self.restartMonitoringInitiated)
      self.restartMonitoringInitiated = false;

    close(self.fileDescriptor);

    self.fileDescriptor = 0;
    self.source = nil;

    self.isMonitoringStarted = false;
    self.cancelMonitoringInitiated = false;

    if (self.stopMonitoringInitiated)
    {
      self.stopMonitoringInitiated = false;
      dispatch_semaphore_signal(self.stopMonitoringSemaphore);
    }
    // self.restartMonitoringInitiated must be true
    else
    {
      self.restartMonitoringInitiated = false;

      // Monitoring may not actually be started after this returns.
      [self startMonitoring];
    }
  }
}

@end
