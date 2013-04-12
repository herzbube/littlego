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
#import "DeleteGameCommand.h"
#import "../../main/ApplicationDelegate.h"
#import "../../archive/ArchiveGame.h"
#import "../../archive/ArchiveViewModel.h"


@implementation DeleteGameCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a DeleteGameCommand object.
///
/// @note This is the designated initializer of DeleteGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithGame:(ArchiveGame*)aGame
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.game = aGame;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DeleteGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  ArchiveViewModel* model = [ApplicationDelegate sharedDelegate].archiveViewModel;
  NSString* filePath = [model.archiveFolder stringByAppendingPathComponent:self.game.fileName];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  BOOL success = [fileManager removeItemAtPath:filePath error:nil];
  DDLogVerbose(@"%@: Removed game file %@, result = %d", [self shortDescription], filePath, success);
  if (success)
    [[NSNotificationCenter defaultCenter] postNotificationName:archiveContentChanged object:nil];
  return success;
}

@end
