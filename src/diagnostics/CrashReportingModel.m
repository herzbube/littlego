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
#import "CrashReportingModel.h"


@implementation CrashReportingModel

// -----------------------------------------------------------------------------
/// @brief Initializes a CrashReportingModel object with user defaults data.
///
/// @note This is the designated initializer of CrashReportingModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.collectCrashData = true;
  self.automaticReport = false;
  self.allowContact = false;
  self.contactEmail = @"";

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CrashReportingModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.contactEmail = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:crashReportingKey];

  self.collectCrashData = [[dictionary valueForKey:collectCrashDataKey] boolValue];
  self.automaticReport = [[dictionary valueForKey:automaticReportCrashDataKey] boolValue];
  self.allowContact = [[dictionary valueForKey:allowContactCrashDataKey] boolValue];
  self.contactEmail = [dictionary valueForKey:contactEmailCrashDataKey];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithBool:self.collectCrashData] forKey:collectCrashDataKey];
  [dictionary setValue:[NSNumber numberWithBool:self.automaticReport] forKey:automaticReportCrashDataKey];
  [dictionary setValue:[NSNumber numberWithBool:self.allowContact] forKey:allowContactCrashDataKey];
  [dictionary setValue:self.contactEmail forKey:contactEmailCrashDataKey];
  
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:uiSettingsKey];
}

@end
