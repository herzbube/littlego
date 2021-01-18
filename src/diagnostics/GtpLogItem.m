// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "GtpLogItem.h"
#import "../ui/UiUtilities.h"
#import "../utility/NSStringAdditions.h"


@implementation GtpLogItem

// -----------------------------------------------------------------------------
/// @brief Initializes a GtpLogItem object.
///
/// @note This is the designated initializer of GtpLogItem.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.commandString = nil;
  self.timeStamp = nil;
  self.hasResponse = false;
  self.responseStatus = false;
  self.parsedResponseString = nil;
  self.rawResponseString = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;

  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;
  self.commandString = [decoder decodeObjectForKey:gtpLogItemCommandStringKey];
  self.timeStamp = [decoder decodeObjectForKey:gtpLogItemTimeStampKey];
  self.hasResponse = [decoder decodeBoolForKey:gtpLogItemHasResponseKey];
  self.responseStatus = [decoder decodeBoolForKey:gtpLogItemResponseStatusKey];
  self.parsedResponseString = [decoder decodeObjectForKey:gtpLogItemParsedResponseStringKey];
  self.rawResponseString = [decoder decodeObjectForKey:gtpLogItemRawResponseStringKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpLogItem object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.commandString = nil;
  self.timeStamp = nil;
  self.parsedResponseString = nil;
  self.rawResponseString = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns an image that is appropriate for representing the GTP
/// response status of this GtpLogItem in a table view cell.
// -----------------------------------------------------------------------------
- (UIImage*) imageRepresentingResponseStatus
{
  // Image objects are allocated on-demand, but only one object per response
  // status since we potentially have a large number of table view cells.
  // Once created the image objects are retained indefinitely.
  static UIImage* noStatusImage = 0;
  static UIImage* successImage = 0;
  static UIImage* failureImage = 0;

  if (! self.hasResponse)
  {
    if (! noStatusImage)
      noStatusImage = [[@"?" imageWithFont:nil drawShadow:true] retain];
    return noStatusImage;
  }
  else
  {
    if (self.responseStatus)
    {
      if (! successImage)
        successImage = [[UiUtilities circularTableCellViewIndicatorWithColor:[UIColor greenColor]] retain];
      return successImage;
    }
    else
    {
      if (! failureImage)
        failureImage = [[UiUtilities circularTableCellViewIndicatorWithColor:[UIColor redColor]] retain];
      return failureImage;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.commandString forKey:gtpLogItemCommandStringKey];
  [encoder encodeObject:self.timeStamp forKey:gtpLogItemTimeStampKey];
  [encoder encodeBool:self.hasResponse forKey:gtpLogItemHasResponseKey];
  [encoder encodeBool:self.responseStatus forKey:gtpLogItemResponseStatusKey];
  [encoder encodeObject:self.parsedResponseString forKey:gtpLogItemParsedResponseStringKey];
  [encoder encodeObject:self.rawResponseString forKey:gtpLogItemRawResponseStringKey];
}

@end
