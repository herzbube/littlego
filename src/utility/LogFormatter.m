// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "LogFormatter.h"

//// System includes
//#import <UIKit/UIKit.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LogFormatter.
// -----------------------------------------------------------------------------
@interface LogFormatter()
@property(nonatomic, assign) enum LogFormatStyle logFormatStyle;
@property(nonatomic, retain) NSString* processID;
@property(nonatomic, retain) NSDateFormatter* dateFormatter;
@end


@implementation LogFormatter

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a LogFormatter object that uses style
/// #LogFormatStyleWithTimestamp.
// -----------------------------------------------------------------------------
- (id) init
{
  return [self initWithLogFormatStyle:LogFormatStyleWithTimestamp];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a LogFormatter object that uses the specified style
/// @a logFormatStyle.
///
/// @note This is the designated initializer of LogFormatter.
// -----------------------------------------------------------------------------
- (id) initWithLogFormatStyle:(enum LogFormatStyle)logFormatStyle
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.logFormatStyle = logFormatStyle;

  int processIDAsInteger = [[NSProcessInfo processInfo] processIdentifier];
  self.processID = [NSString stringWithFormat:@"%d", processIDAsInteger];

  if (self.logFormatStyle == LogFormatStyleWithTimestamp)
  {
    // Duplicate formatter setup in DDLogFileFormatterDefault. Unfortunately
    // there's no sensible way to extract the NSDateFormatter object from an
    // DDLogFileFormatterDefault instance, so we have to hardcode this.
    self.dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [self.dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
    [self.dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [self.dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [self.dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
  }
  else
  {
    self.dateFormatter = nil;
  }

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LogFormatter object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.processID = nil;
  self.dateFormatter = nil;
  [super dealloc];
}

#pragma mark - DDLogFormatter overrides

// -----------------------------------------------------------------------------
/// @brief DDLogFormatter protocol method.
// -----------------------------------------------------------------------------
- (NSString*) formatLogMessage:(DDLogMessage*)logMessage
{
  NSString* logLevel;
  switch (logMessage->_flag)
  {
    case DDLogFlagError    : logLevel = @"E"; break;
    case DDLogFlagWarning  : logLevel = @"W"; break;
    case DDLogFlagInfo     : logLevel = @"I"; break;
    case DDLogFlagDebug    : logLevel = @"D"; break;
    case DDLogFlagVerbose  : logLevel = @"V"; break;
    default                : logLevel = @"?"; break;
  }

  if (self.logFormatStyle == LogFormatStyleWithTimestamp)
  {
    NSString* dateAndTime = [self.dateFormatter stringFromDate:logMessage->_timestamp];

    return [NSString stringWithFormat:@"%@ | %@ | %@ | %@ | %@",
            dateAndTime,
            self.processID,
            logMessage->_threadID,
            logLevel,
            logMessage->_message];
  }
  else
  {
    return [NSString stringWithFormat:@"%@ | %@ | %@ | %@",
            self.processID,
            logMessage->_threadID,
            logLevel,
            logMessage->_message];
  }
}

@end
