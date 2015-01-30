// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "GtpLogModel.h"
#import "GtpLogItem.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GtpLogModel.
// -----------------------------------------------------------------------------
@interface GtpLogModel()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSArray* itemList;
//@}
/// @name Private properties
//@{
/// @brief Stores GtpLogItem objects for which a GTP response is still
/// outstanding.
///
/// The array acts as a fifo queue. enqueueItemWithNoResponse() and
/// dequeueItemWithNoResponse() are used to modify the queue.
///
/// The assumption behind this is that the GTP engine also works as a queue: It
/// processes GTP commands in the order that they are submitted, and does not
/// start processing a new command before it has sent the response to the
/// preceding command.
///
/// Based on this assumption, GtpLogItem objects can simply be added to the
/// queue as the GTP command submissions are pouring in. Whenever a GTP response
/// is received, the GtpLogItem object at the front of the queue must be the
/// one with the command that the response belongs to.
@property(nonatomic, retain) NSMutableArray* itemQueueNoResponses;
@property(nonatomic, retain) NSDateFormatter* dateFormatter;
//@}
@end


@implementation GtpLogModel

// -----------------------------------------------------------------------------
/// @brief Initializes a GtpLogModel object.
///
/// @note This is the designated initializer of GtpLogModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gtpCommandWillBeSubmitted:)
                                               name:gtpCommandWillBeSubmittedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gtpResponseWasReceived:)
                                               name:gtpResponseWasReceivedNotification
                                             object:nil];

  self.itemList = [NSMutableArray arrayWithCapacity:0];
  self.gtpLogSize = 100;
  self.gtpLogViewFrontSideIsVisible = true;
  self.itemQueueNoResponses = [NSMutableArray arrayWithCapacity:0];

  self.dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
  [self.dateFormatter setLocale:[NSLocale currentLocale]];
  // Use medium format so that we can see seconds - this way we can better
  // gauge how long the engine takes for calculating its moves.
  [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
  [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpLogModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.itemList = nil;
  self.itemQueueNoResponses = nil;
  self.dateFormatter = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:gtpLogViewKey];
  self.gtpLogSize = [[dictionary valueForKey:gtpLogSizeKey] intValue];
  self.gtpLogViewFrontSideIsVisible = [[dictionary valueForKey:gtpLogViewFrontSideIsVisibleKey] boolValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithInt:self.gtpLogSize] forKey:gtpLogSizeKey];
  [dictionary setValue:[NSNumber numberWithBool:self.gtpLogViewFrontSideIsVisible] forKey:gtpLogViewFrontSideIsVisibleKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:gtpLogViewKey];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #gtpCommandWillBeSubmitted notification.
///
/// This method is executed in a secondary thread. Delegates processing of the
/// GtpCommand object associated with the notification to
/// updateLogWithGtpCommand:(). See class documentation for details.
// -----------------------------------------------------------------------------
- (void) gtpCommandWillBeSubmitted:(NSNotification*)notification
{
  GtpCommand* command = (GtpCommand*)[notification object];
  // Retain to make sure that object is still alive when it "arrives" in
  // the main thread
  [command retain];
  [self performSelector:@selector(gtpCommandWillBeSubmittedDelegate:)
               onThread:[NSThread mainThread]
             withObject:command
          waitUntilDone:NO];
}

// -----------------------------------------------------------------------------
/// @brief Delegate method of gtpCommandWillBeSubmitted:(). This method is
/// executed in the main thread. See class documentation for details.
// -----------------------------------------------------------------------------
- (void) gtpCommandWillBeSubmittedDelegate:(GtpCommand*)command
{
  // Undo retain message sent to the command object by
  // gtpCommandWillBeSubmitted:()
  [command autorelease];

  [self addItemToLog:command];
  [self trimLog];
  [[NSNotificationCenter defaultCenter] postNotificationName:gtpLogContentChanged
                                                      object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #gtpResponseWasReceived notification.
// -----------------------------------------------------------------------------
- (void) gtpResponseWasReceived:(NSNotification*)notification
{
  GtpResponse* response = (GtpResponse*)[notification object];
  // Retain to make sure that object is still alive when it "arrives" in
  // the main thread
  [response retain];
  [self performSelector:@selector(gtpResponseWasReceivedDelegate:)
               onThread:[NSThread mainThread]
             withObject:response
          waitUntilDone:NO];
}

// -----------------------------------------------------------------------------
/// @brief Delegate method of gtpCommandWillBeSubmitted:(). This method is
/// executed in the main thread. See class documentation for details.
// -----------------------------------------------------------------------------
- (void) gtpResponseWasReceivedDelegate:(GtpResponse*)response
{
  // Undo retain message sent to the response object by
  // gtpResponseWasReceived:()
  [response autorelease];

  GtpLogItem* logItem = [self dequeueItemWithNoResponse];
  assert(logItem != nil);
  if (! logItem)
    DDLogError(@"%@: GtpLogItem object is nil", self);

  // Check if the item was kicked out of the log while the response was still
  // outstanding. Stuff like clearing the log, or a massive amount of trimming,
  // might have happened.
  if (! [_itemList containsObject:logItem])
  {
    DDLogInfo(@"Discarding GTP response");
    return;
  }

  logItem.hasResponse = true;
  logItem.responseStatus = response.status;
  logItem.parsedResponseString = [response parsedResponse];
  logItem.rawResponseString = response.rawResponse;

  [[NSNotificationCenter defaultCenter] postNotificationName:gtpLogItemChanged
                                                      object:logItem];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (int) itemCount
{
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) log
  // items.
  return (int)_itemList.count;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setGtpLogSize:(int)newSize
{
  assert(newSize >= 1);
  if (newSize < 1)
  {
    DDLogError(@"%@: Attempting to set illegal log size %d", self, newSize);
    return;
  }

  int oldSize = _gtpLogSize;
  _gtpLogSize = newSize;

  if (newSize < oldSize)
  {
    [self trimLog];
    [[NSNotificationCenter defaultCenter] postNotificationName:gtpLogContentChanged
                                                        object:nil];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the log item object located at position @a index in the
/// itemList array.
// -----------------------------------------------------------------------------
- (GtpLogItem*) itemAtIndex:(int)index
{
  return [_itemList objectAtIndex:index];
}

// -----------------------------------------------------------------------------
/// @brief Adds an item that represents @a command to the log.
// -----------------------------------------------------------------------------
- (void) addItemToLog:(GtpCommand*)command
{
  GtpLogItem* logItem = [[GtpLogItem alloc] init];
  [(NSMutableArray*)_itemList addObject:logItem];  // _itemList has ownership
  [logItem release];

  [self enqueueItemWithNoResponse:logItem];

  logItem.commandString = command.command;
  logItem.timeStamp = [self.dateFormatter stringFromDate:[NSDate date]];
}

// -----------------------------------------------------------------------------
/// @brief Removes as many of the oldest items from the log as are needed to
/// bring the log size down to its maximum allowed size (property
/// @e gtpLogSize).
///
/// Does nothing if the log size currently does not exceed the limit.
// -----------------------------------------------------------------------------
- (void) trimLog
{
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) log
  // items.
  int numberOfItemsToDiscard = (int)_itemList.count - self.gtpLogSize;
  if (numberOfItemsToDiscard <= 0)
    return;

  NSRange rangeToRemove;
  rangeToRemove.location = 0;  // oldest items are at the front of the array
  rangeToRemove.length = numberOfItemsToDiscard;
  [(NSMutableArray*)_itemList removeObjectsInRange:rangeToRemove];
}

// -----------------------------------------------------------------------------
/// @brief Adds @a item to the end of the queue with log items for which the
/// response is still outstanding.
// -----------------------------------------------------------------------------
- (void) enqueueItemWithNoResponse:(GtpLogItem*)logItem
{
  [_itemQueueNoResponses addObject:logItem];
}

// -----------------------------------------------------------------------------
/// @brief Removes an item from the front of the queue with log items for which
/// the response is still outstanding, then returns that item.
///
/// Returns nil if the queue is currently empty.
// -----------------------------------------------------------------------------
- (GtpLogItem*) dequeueItemWithNoResponse
{
  if (_itemQueueNoResponses.count == 0)
    return nil;
  GtpLogItem* logItem = [_itemQueueNoResponses objectAtIndex:0];
  [_itemQueueNoResponses removeObjectAtIndex:0];
  return logItem;
}

// -----------------------------------------------------------------------------
/// @brief Removes all items from the queue with items for which the GTP
/// response is still outstanding.
// -----------------------------------------------------------------------------
- (void) clearItemQueueWithNoResponse
{
  [_itemQueueNoResponses removeAllObjects];
}

// -----------------------------------------------------------------------------
/// @brief Clears the entire log, i.e. all log items are removed.
// -----------------------------------------------------------------------------
- (void) clearLog
{
  [(NSMutableArray*)_itemList removeAllObjects];
  // Note: _itemQueueNoResponses is not modified by design! If we were removing
  // items from that queue, outstanding responses might become associated with
  // the wrong GtpLogItem objects when they come in.

  [[NSNotificationCenter defaultCenter] postNotificationName:gtpLogContentChanged
                                                      object:nil];
}

@end
