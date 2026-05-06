// -----------------------------------------------------------------------------
// Copyright 2011-2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../main/ModelProvider.h"
#import "../../main/Registry.h"
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
  // The model update will replace the fileName property value in self.game.
  // To make sure that the old NSString object is not deallocated we do
  // a retain/autorelease here.
  NSString* oldFileName = [[self.game.fileName retain] autorelease];
  NSString* newFileName = [self.theNewName stringByAppendingString:@".sgf"];
  if ([oldFileName isEqualToString:newFileName])
    return true;

  ArchiveViewModel* model = [Registry sharedRegistry].modelProvider.archiveViewModel;
  bool success = [model archiveGame:self.game willBeRenamedTo:newFileName];
  if (! success)
  {
    DDLogError(@"%@: Model update failed, old file name = %@, new file name = %@", [self shortDescription], oldFileName, newFileName);
    return false;
  }

  NSString* oldPath = [model.archiveFolder stringByAppendingPathComponent:oldFileName];
  NSString* newPath = [model.archiveFolder stringByAppendingPathComponent:newFileName];
  DDLogVerbose(@"%@: Renaming file %@ to %@", [self shortDescription], oldPath, newPath);

  NSFileManager* fileManager = [NSFileManager defaultManager];
  success = [fileManager moveItemAtPath:oldPath toPath:newPath error:nil];
  if (success)
    return true;

  DDLogError(@"%@: Filesystem rename failed, result = %d", [self shortDescription], success);

  // Since the filesystem operation failed, we also have to undo the model
  // update
  success = [model archiveGame:self.game willBeRenamedTo:oldFileName];
  if (! success)
    DDLogError(@"%@: Revert of model update failed", [self shortDescription]);

  return false;
}

@end
