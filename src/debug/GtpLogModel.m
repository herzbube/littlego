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


// Project includes
#import "GtpLogModel.h"
#import "GtpLogItem.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GtpLogModel.
// -----------------------------------------------------------------------------
@interface GtpLogModel()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Notification responders
//@{
- (void) gtpCommandWillBeSubmitted:(NSNotification*)notification;
- (void) gtpResponseWasReceived:(NSNotification*)notification;
//@}
/// @name Private helpers
//@{
- (void) addItemToLog:(GtpCommand*)command;
- (void) trimLog;
- (void) enqueueItemWithNoResponse:(GtpLogItem*)logItem;
- (GtpLogItem*) dequeueItemWithNoResponse;
- (void) clearItemQueueWithNoResponse;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(readwrite, retain) NSArray* itemList;
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
@property(retain) NSMutableArray* itemQueueNoResponses;
@property(retain) NSDateFormatter* dateFormatter;
//@}
@end


@implementation GtpLogModel

@synthesize itemList;
@synthesize gtpLogSize;
@synthesize gtpLogViewFrontSideIsVisible;
@synthesize itemQueueNoResponses;
@synthesize dateFormatter;


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
  [dateFormatter setLocale:[NSLocale currentLocale]];
  [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
  [dateFormatter setDateStyle:NSDateFormatterShortStyle];

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
  NSDictionary* dictionary = [userDefaults dictionaryForKey:debugViewKey];
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
  [userDefaults setObject:dictionary forKey:debugViewKey];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #gtpCommandWillBeSubmitted notification.
// -----------------------------------------------------------------------------
- (void) gtpCommandWillBeSubmitted:(NSNotification*)notification
{
  GtpCommand* command = (GtpCommand*)[notification object];
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
  GtpLogItem* logItem = [self dequeueItemWithNoResponse];
  assert(logItem != nil);

  // Check if the item was kicked out of the log while the response was still
  // outstanding. Stuff like clearing the log, or a massive amount of trimming,
  // might have happened.
  if (! [itemList containsObject:logItem])
  {
    NSLog(@"Discarding GTP response");
    return;
  }

  GtpResponse* response = (GtpResponse*)[notification object];
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
  return itemList.count;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setGtpLogSize:(int)newSize
{
  assert(newSize >= 1);
  if (newSize < 1)
    return;

  int oldSize = gtpLogSize;
  gtpLogSize = newSize;

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
  return [itemList objectAtIndex:index];
}

// -----------------------------------------------------------------------------
/// @brief Adds an item that represents @a command to the log.
// -----------------------------------------------------------------------------
- (void) addItemToLog:(GtpCommand*)command
{
  GtpLogItem* logItem = [[GtpLogItem alloc] init];
  [(NSMutableArray*)itemList addObject:logItem];  // itemList has ownership
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
  int numberOfItemsToDiscard = itemList.count - self.gtpLogSize;
  if (numberOfItemsToDiscard <= 0)
    return;

  NSRange rangeToRemove;
  rangeToRemove.location = 0;  // oldest items are at the front of the array
  rangeToRemove.length = numberOfItemsToDiscard;
  [(NSMutableArray*)itemList removeObjectsInRange:rangeToRemove];
}

// -----------------------------------------------------------------------------
/// @brief Adds @a item to the end of the queue with log items for which the
/// response is still outstanding.
// -----------------------------------------------------------------------------
- (void) enqueueItemWithNoResponse:(GtpLogItem*)logItem
{
  [itemQueueNoResponses addObject:logItem];
}

// -----------------------------------------------------------------------------
/// @brief Removes an item from the front of the queue with log items for which
/// the response is still outstanding, then returns that item.
///
/// Returns nil if the queue is currently empty.
// -----------------------------------------------------------------------------
- (GtpLogItem*) dequeueItemWithNoResponse
{
  if (itemQueueNoResponses.count == 0)
    return nil;
  GtpLogItem* logItem = [itemQueueNoResponses objectAtIndex:0];
  [itemQueueNoResponses removeObjectAtIndex:0];
  return logItem;
}

// -----------------------------------------------------------------------------
/// @brief Removes all items from the queue with items for which the GTP
/// response is still outstanding.
// -----------------------------------------------------------------------------
- (void) clearItemQueueWithNoResponse
{
  [itemQueueNoResponses removeAllObjects];
}

// -----------------------------------------------------------------------------
/// @brief Clears the entire log, i.e. all log items are removed.
// -----------------------------------------------------------------------------
- (void) clearLog
{
  [(NSMutableArray*)itemList removeAllObjects];
  // Note: itemQueueNoResponses is not modified by design! If we were removing
  // items from that queue, outstanding responses might become associated with
  // the wrong GtpLogItem objects when they come in.

  [[NSNotificationCenter defaultCenter] postNotificationName:gtpLogContentChanged
                                                      object:nil];
}

@end
