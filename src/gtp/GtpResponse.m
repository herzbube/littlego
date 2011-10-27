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
#import "GtpResponse.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GtpResponse.
// -----------------------------------------------------------------------------
@interface GtpResponse()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
/// @name Other methods
//@{
- (NSString*) description;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(readwrite, retain) NSString* rawResponse;
@property(readwrite, retain) GtpCommand* command;
//@}
@end


@implementation GtpResponse

@synthesize rawResponse;
@synthesize command;

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GtpResponse instance that wraps
/// the response string @a response, and is a response to @a command.
// -----------------------------------------------------------------------------
+ (GtpResponse*) response:(NSString*)response toCommand:(GtpCommand*)command
{
  GtpResponse* resp = [[GtpResponse alloc] init];
  if (resp)
  {
    resp.rawResponse = response;
    resp.command = command;
    [resp autorelease];
    DDLogInfo(@"Received %@", resp);
  }
  return resp;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GtpResponse object.
///
/// @note This is the designated initializer of GtpResponse.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.rawResponse = nil;
  self.command = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpResponse object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.rawResponse = nil;
  self.command = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GtpResponse object.
///
/// This method is invoked when GtpResponse needs to be represented as a string,
/// i.e. by NSLog, or when the debugger command "po" is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GtpResponse(%p): %@", self, rawResponse];
}

// -----------------------------------------------------------------------------
/// @brief Returns the parsed response string, which is the raw response without
/// the status prefix.
// -----------------------------------------------------------------------------
- (NSString*) parsedResponse
{
  if (! self.rawResponse)
    return nil;
  // Remove status
  NSString* parsedResponse = [self.rawResponse substringFromIndex:2];
  return [[parsedResponse retain] autorelease];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (bool) status
{
  if (! self.rawResponse)
    return false;
  NSString* statusString = [self.rawResponse substringWithRange:NSMakeRange(0, 1)];
  if (NSOrderedSame == [statusString compare:@"="])
    return true;
  else
    return false;
}

@end
