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


@implementation GtpResponse

@synthesize response;
@synthesize command;

+ (GtpResponse*) response:(NSString*)response
{
  GtpResponse* resp = [[GtpResponse alloc] init];
  if (resp)
  {
    resp.response = response;
    resp.command = nil;
    [resp autorelease];
  }
  return resp;
}

- (GtpResponse*) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.response = nil;
  self.command = nil;

  return self;
}

- (void) dealloc
{
  self.response = nil;
  self.command = nil;
  [super dealloc];
}

@end
