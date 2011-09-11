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
#import "SaveGameCommand.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for SaveGameCommand.
// -----------------------------------------------------------------------------
@interface SaveGameCommand()
- (void) dealloc;
- (void) gtpResponseReceived:(NSNotification*)notification;
@end


@implementation SaveGameCommand

@synthesize fileName;


// -----------------------------------------------------------------------------
/// @brief Initializes a SaveGameCommand object.
///
/// @note This is the designated initializer of SaveGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithFile:(NSString*)aFileName
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.fileName = aFileName;
  m_gtpCommand = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CommandBase object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.fileName = nil;
  if (m_gtpCommand)
  {
    [m_gtpCommand release];
    m_gtpCommand = nil;
  }
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (! self.fileName)
    return false;

  // Add ourselves as observers before we submit the command
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gtpResponseReceived:)
                                               name:gtpResponseReceivedNotification
                                             object:nil];
  // Make sure that this command object survives until it gets the notification.
  // If the notification never arrives there will be a memory leak :-(
  [self retain];

  NSString* commandString = [NSString stringWithFormat:@"savesgf %@", sgfTemporaryFileName];
  m_gtpCommand = [[GtpCommand command:commandString] retain];
  [m_gtpCommand submit];

  // TODO It would be better if we could wait for the GtpResponse before
  // returning! For instance, this would enable the calling party to block the
  // user interface until the game has been saved. At the moment, the user is
  // able to go on playing while game saving is in progress...
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #gtpResponseReceived notification.
// -----------------------------------------------------------------------------
- (void) gtpResponseReceived:(NSNotification*)notification
{
  GtpResponse* response = [notification object];
  if (m_gtpCommand != response.command)
    return;

  // We got what we wanted, we are no longer interested in notifications
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  // Balance the retain message in doIt() to trigger deallocation
  [self autorelease];

  // Was GTP command successful?
  if (! response.status)
  {
    assert(0);
    return;
  }

  // Get rid of another file of the same name (otherwise the subsequent move
  // operation fails)
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:self.fileName])
  {
    BOOL success = [fileManager removeItemAtPath:self.fileName error:nil];
    if (! success)
    {
      assert(0);
      return;
    }
  }

  BOOL success = [fileManager moveItemAtPath:sgfTemporaryFileName toPath:self.fileName error:nil];
  if (! success)
  {
    assert(0);
    return;
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:gameSavedToArchive object:self.fileName];
  [[NSNotificationCenter defaultCenter] postNotificationName:archiveContentChanged object:nil];
}

@end
