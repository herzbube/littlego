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
#import "SgfUtilities.h"

@implementation SgfUtilities

// -----------------------------------------------------------------------------
/// @brief Returns true if the load operation that resulted in @a readResult
/// is successful when @a loadSuccessType is active. Returns false if the load
/// operation was not successful.
// -----------------------------------------------------------------------------
+ (bool) isLoadOperationSuccessful:(SGFCDocumentReadResult*)readResult
               withLoadSuccessType:(enum SgfLoadSuccessType)loadSuccessType
{
  if (! readResult.isSgfDataValid)
    return false;

  // It doesn't matter what kind of messages we have - all are acceptable
  if (loadSuccessType == SgfLoadSuccessTypeWithCriticalWarningsOrErrors)
    return true;

  NSArray* parseResult = readResult.parseResult;

  // It doesn't matter what kind of messages we have - none are acceptable
  if (loadSuccessType == SgfLoadSuccessTypeNoWarningsOrErrors)
    return (parseResult.count == 0);

  for (SGFCMessage* message in readResult.parseResult)
  {
    if (message.isCriticalMessage)
      return false;
  }

  return true;
}

@end
