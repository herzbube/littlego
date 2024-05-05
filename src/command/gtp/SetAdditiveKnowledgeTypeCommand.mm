// -----------------------------------------------------------------------------
// Copyright 2013-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "SetAdditiveKnowledgeTypeCommand.h"
#import "../../utility/UIDeviceAdditions.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"


@implementation SetAdditiveKnowledgeTypeCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:gtpEngineConfigurationKey];
  int additiveKnowledgeMemoryThreshold = [[dictionary valueForKey:additiveKnowledgeMemoryThresholdKey] intValue];
  int physicalMemoryMegabytes = [UIDevice physicalMemoryMegabytes];
  DDLogVerbose(@"%@: Physical memory = %d, additive knowledge memory threshold = %d",
               [self shortDescription],
               physicalMemoryMegabytes,
               additiveKnowledgeMemoryThreshold);

  enum AdditiveKnowledgeType additiveKnowledgeType;
  if (physicalMemoryMegabytes >= additiveKnowledgeMemoryThreshold)
    additiveKnowledgeType = AdditiveKnowledgeTypeGreenpeep;
  else
    additiveKnowledgeType = AdditiveKnowledgeTypeRulebased;

  NSString* commandString = [self commandStringForKnowledgeType:additiveKnowledgeType];
  if (! commandString)
    return false;
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];

  return command.response.status;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GTP command required to configure the GTP engine with the
/// additive knowlege type @a additiveKnowledgeType. Returns nil if
/// @a additiveKnowledgeType has an unsupported value.
// -----------------------------------------------------------------------------
- (NSString*) commandStringForKnowledgeType:(enum AdditiveKnowledgeType)additiveKnowledgeType
{
  NSString* additiveKnowledgeTypeAsString;
  switch (additiveKnowledgeType)
  {
    case AdditiveKnowledgeTypeNone:
      additiveKnowledgeTypeAsString = @"none";
      break;
    case AdditiveKnowledgeTypeGreenpeep:
      additiveKnowledgeTypeAsString = @"greenpeep";
      break;
    case AdditiveKnowledgeTypeRulebased:
      additiveKnowledgeTypeAsString = @"rulebased";
      break;
    case AdditiveKnowledgeTypeBoth:
      additiveKnowledgeTypeAsString = @"both";
      break;
    default:
      DDLogError(@"%@: Unexpected additive knowledge type %d", [self shortDescription], additiveKnowledgeType);
      assert(0);
      return nil;
  }
  return [NSString stringWithFormat:@"uct_param_policy knowledge_type %@", additiveKnowledgeTypeAsString];
}

@end
