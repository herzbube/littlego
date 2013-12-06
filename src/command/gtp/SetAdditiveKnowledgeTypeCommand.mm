// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
  int additiveKnowledgeMemoryThreshold = [[userDefaults valueForKey:additiveKnowledgeMemoryThresholdKey] intValue];
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

  NSString* commandString = [NSString stringWithFormat:@"uct_param_policy knowledge_type %d", additiveKnowledgeType];
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];

  return command.response.status;
}

@end
