// -----------------------------------------------------------------------------
// Copyright 2021-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "SgfSettingsModel.h"
#import "../utility/NSArrayAdditions.h"


@implementation SgfSettingsModel

// -----------------------------------------------------------------------------
/// @brief Initializes a SgfSettingsModel object with user defaults data.
///
/// @note This is the designated initializer of SgfSettingsModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  [self resetSyntaxCheckingLevelPropertiesToDefaultValues];
  self.encodingMode = SgfEncodingModeSingleEncoding;
  self.defaultEncoding = @"";
  self.forcedEncoding = @"";
  self.reverseVariationOrdering = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SgfSettingsModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.disabledMessages = nil;
  self.defaultEncoding = nil;
  self.forcedEncoding = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:sgfSettingsKey];
  self.loadSuccessType = [[dictionary valueForKey:loadSuccessTypeKey] intValue];
  self.enableRestrictiveChecking = [[dictionary valueForKey:enableRestrictiveCheckingKey] boolValue];
  self.disableAllWarningMessages = [[dictionary valueForKey:disableAllWarningMessagesKey] boolValue];
  self.disabledMessages = (NSArray*)[dictionary valueForKey:disabledMessagesKey];
  self.encodingMode = [[dictionary valueForKey:encodingModeKey] intValue];
  self.defaultEncoding = (NSString*)[dictionary valueForKey:defaultEncodingKey];
  self.forcedEncoding = (NSString*)[dictionary valueForKey:forcedEncodingKey];
  self.reverseVariationOrdering = [[dictionary valueForKey:reverseVariationOrderingKey] boolValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  // setValue:forKey:() allows for nil values, so we use that instead of
  // setObject:forKey:() which is less forgiving and would force us to check
  // for nil values.
  // Note: Use NSNumber to represent int and bool values as an object.
  [dictionary setValue:[NSNumber numberWithInt:self.loadSuccessType] forKey:loadSuccessTypeKey];
  [dictionary setValue:[NSNumber numberWithBool:self.enableRestrictiveChecking] forKey:enableRestrictiveCheckingKey];
  [dictionary setValue:[NSNumber numberWithBool:self.disableAllWarningMessages] forKey:disableAllWarningMessagesKey];
  [dictionary setValue:self.disabledMessages forKey:disabledMessagesKey];
  [dictionary setValue:[NSNumber numberWithInt:self.encodingMode] forKey:encodingModeKey];
  [dictionary setValue:self.defaultEncoding forKey:defaultEncodingKey];
  [dictionary setValue:self.forcedEncoding forKey:forcedEncodingKey];
  [dictionary setValue:[NSNumber numberWithBool:self.reverseVariationOrdering] forKey:reverseVariationOrderingKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:sgfSettingsKey];
}

// -----------------------------------------------------------------------------
/// @brief Discards the current user defaults and re-initializes this model with
/// registration domain defaults data.
// -----------------------------------------------------------------------------
- (void) resetToRegistrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults removeObjectForKey:sgfSettingsKey];
  [self readUserDefaults];
}

// -----------------------------------------------------------------------------
// See property documentation. This property is not synthesized.
// -----------------------------------------------------------------------------
- (int) syntaxCheckingLevel
{
  int syntaxCheckingLevel = customSyntaxCheckingLevel;

  switch (self.loadSuccessType)
  {
    case SgfLoadSuccessTypeWithCriticalWarningsOrErrors:
      if (! self.enableRestrictiveChecking &&
          self.disableAllWarningMessages &&
          [self.disabledMessages isEqualToArrayIgnoringOrder:[self defaultDisabledMessages]])
      {
        syntaxCheckingLevel = 1;
      }
      break;
    case SgfLoadSuccessTypeNoCriticalWarningsOrErrors:
      if (! self.enableRestrictiveChecking &&
          ! self.disableAllWarningMessages &&
          [self.disabledMessages isEqualToArrayIgnoringOrder:[self defaultDisabledMessages]])
      {
        syntaxCheckingLevel = 2;
      }
      break;
    case SgfLoadSuccessTypeNoWarningsOrErrors:
      if (self.enableRestrictiveChecking &&
          ! self.disableAllWarningMessages &&
          self.disabledMessages.count == 0)
      {
        syntaxCheckingLevel = 4;
      }
      else if (! self.enableRestrictiveChecking &&
               ! self.disableAllWarningMessages &&
               [self.disabledMessages isEqualToArrayIgnoringOrder:[self defaultDisabledMessages]])
      {
        syntaxCheckingLevel = 3;
      }
      break;
    default:
      break;
  }

  return syntaxCheckingLevel;
}

// -----------------------------------------------------------------------------
// See property documentation. This property is not synthesized.
// -----------------------------------------------------------------------------
- (void) setSyntaxCheckingLevel:(int)syntaxCheckingLevel
{
  [self resetSyntaxCheckingLevelPropertiesToDefaultValues];

  switch (syntaxCheckingLevel)
  {
    case 1:
      self.loadSuccessType = SgfLoadSuccessTypeWithCriticalWarningsOrErrors;
      self.disableAllWarningMessages = true;
      break;
    case 2:
      // The default values are all OK
      break;
    case 3:
      self.loadSuccessType = SgfLoadSuccessTypeNoWarningsOrErrors;
      break;
    case 4:
      self.loadSuccessType = SgfLoadSuccessTypeNoWarningsOrErrors;
      self.enableRestrictiveChecking = true;
      self.disabledMessages = [NSArray array];
      break;
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Syntax checking level %d is invalid", syntaxCheckingLevel];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Resets those properties to their default values that are related to
/// syntax checking level.
// -----------------------------------------------------------------------------
- (void) resetSyntaxCheckingLevelPropertiesToDefaultValues
{
  self.loadSuccessType = SgfLoadSuccessTypeNoCriticalWarningsOrErrors;
  self.enableRestrictiveChecking = false;
  self.disableAllWarningMessages = false;
  self.disabledMessages = [self defaultDisabledMessages];
}

// -----------------------------------------------------------------------------
/// @brief Returns an array with hardcoded message IDs that should be ignored
/// by default.
// -----------------------------------------------------------------------------
- (NSArray*) defaultDisabledMessages
{
  return @[@(SGFCMessageIDEmptyValueDeleted),
           @(SGFCMessageIDPropertyNotDefinedInFF),
           @(SGFCMessageIDEmptyNodeDeleted),
           @(SGFCMessageIDGameIsNotGo),
           @(SGFCMessageIDMoreThanOneGameTree)];
}

@end
