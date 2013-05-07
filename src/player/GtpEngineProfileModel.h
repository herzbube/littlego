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


// Forward declarations
@class GtpEngineProfile;


// -----------------------------------------------------------------------------
/// @brief The GtpEngineProfileModel class manages GtpEngineProfile objects and
/// provides clients with access to those objects. Data that makes up
/// GtpEngineProfile objects is read from and written to the user defaults
/// system.
// -----------------------------------------------------------------------------
@interface GtpEngineProfileModel : NSObject
{
}

- (id) init;
- (void) readUserDefaults;
- (void) writeUserDefaults;
- (NSString*) profileNameAtIndex:(int)index;
- (void) add:(GtpEngineProfile*)profile;
- (void) remove:(GtpEngineProfile*)profile;
- (GtpEngineProfile*) profileWithUUID:(NSString*)uuid;
- (GtpEngineProfile*) defaultProfile;
- (GtpEngineProfile*) activeProfile;

@property(nonatomic, assign) int profileCount;
@property(nonatomic, retain) NSArray* profileList;

@end
