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


@interface GtpResponse()
- (NSString*) description;
@property(readwrite, retain) NSString* rawResponse;
@property(readwrite, retain) GtpCommand* command;
@end


@implementation GtpResponse

@synthesize rawResponse;
@synthesize command;

+ (GtpResponse*) response:(NSString*)response toCommand:(GtpCommand*)command
{
  GtpResponse* resp = [[GtpResponse alloc] init];
  if (resp)
  {
    resp.rawResponse = response;
    resp.command = command;
    [resp autorelease];
    NSLog(@"Received %@", resp);
  }
  return resp;
}

- (GtpResponse*) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.rawResponse = nil;
  self.command = nil;

  return self;
}

- (void) dealloc
{
  self.rawResponse = nil;
  self.command = nil;
  [super dealloc];
}

- (NSString*) description
{
  return [NSString stringWithFormat:@"GtpResponse(%p): %@", self, self.rawResponse];
}

- (NSString*) parsedResponse
{
  if (! self.rawResponse)
    return nil;
  // Remove status
  NSString* parsedResponse = [self.rawResponse substringFromIndex:2];
  return [[parsedResponse retain] autorelease];
}

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
