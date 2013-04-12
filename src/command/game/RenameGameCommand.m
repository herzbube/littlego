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
#import "RenameGameCommand.h"
#import "../../main/ApplicationDelegate.h"
#import "../../archive/ArchiveGame.h"
#import "../../archive/ArchiveViewModel.h"


@implementation RenameGameCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a RenameGameCommand object.
///
/// @note This is the designated initializer of RenameGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithGame:(ArchiveGame*)aGame newName:(NSString*)aNewName
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.game = aGame;
  self.theNewName = aNewName;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this RenameGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;
  self.theNewName = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  NSString* newFileName = [self.theNewName stringByAppendingString:@".sgf"];
  if ([self.game.fileName isEqualToString:newFileName])
    return true;

  ArchiveViewModel* model = [ApplicationDelegate sharedDelegate].archiveViewModel;
  NSString* oldPath = [model.archiveFolder stringByAppendingPathComponent:self.game.fileName];
  NSString* newPath = [model.archiveFolder stringByAppendingPathComponent:newFileName];

  NSFileManager* fileManager = [NSFileManager defaultManager];
  BOOL success = [fileManager moveItemAtPath:oldPath toPath:newPath error:nil];
  DDLogVerbose(@"%@: Moved file %@ to %@, result = %d", [self shortDescription], oldPath, newPath, success);
  if (success)
  {
    // Must update the ArchiveGame before posting the notification. Reason: The
    // notification triggers an update cycle which tries to match ArchiveGame
    // objects to filesystem entries via their file names.
    self.game.fileName = newFileName;
    [[NSNotificationCenter defaultCenter] postNotificationName:archiveContentChanged object:nil];
  }
  return success;
}

@end
