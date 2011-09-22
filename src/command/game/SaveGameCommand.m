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
#import "SaveGameCommand.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../ApplicationDelegate.h"
#import "../../archive/ArchiveViewModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for SaveGameCommand.
// -----------------------------------------------------------------------------
@interface SaveGameCommand()
- (void) dealloc;
@end


@implementation SaveGameCommand

@synthesize fileName;


// -----------------------------------------------------------------------------
/// @brief Initializes a SaveGameCommand object.
///
/// @note This is the designated initializer of SaveGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithFile:(NSString*)aFileName
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.fileName = aFileName;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SaveGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.fileName = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (! self.fileName)
    return false;
  ArchiveViewModel* model = [ApplicationDelegate sharedDelegate].archiveViewModel;
  if (! model)
    return false;

  // The GTP engine saves its file into the temporary directory, but the final
  // destination is in the archive folder
  NSString* temporaryDirectory = NSTemporaryDirectory();
  NSString* sgfTemporaryFilePath = [temporaryDirectory stringByAppendingPathComponent:sgfTemporaryFileName];
  NSString* filePath = [model.archiveFolder stringByAppendingPathComponent:self.fileName];

  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* oldCurrentDirectory = [fileManager currentDirectoryPath];
  [fileManager changeCurrentDirectoryPath:temporaryDirectory];
  // Use the file *NAME* without the path
  NSString* commandString = [NSString stringWithFormat:@"savesgf %@", sgfTemporaryFileName];
  GtpCommand* command = [GtpCommand command:commandString];
  command.waitUntilDone = true;
  [command submit];

  // Switch back as soon as possible; from now on operations use the full path
  // to the temporary file
  [fileManager changeCurrentDirectoryPath:oldCurrentDirectory];

  if (! command.response.status)
  {
    [fileManager removeItemAtPath:sgfTemporaryFilePath error:nil];
    assert(0);
    return false;
  }

  // Get rid of another file of the same name (otherwise the subsequent move
  // operation fails)
  if ([fileManager fileExistsAtPath:filePath])
  {
    BOOL success = [fileManager removeItemAtPath:filePath error:nil];
    if (! success)
    {
      [fileManager removeItemAtPath:sgfTemporaryFilePath error:nil];
      assert(0);
      return false;
    }
  }

  BOOL success = [fileManager moveItemAtPath:sgfTemporaryFilePath toPath:filePath error:nil];
  if (! success)
  {
    [fileManager removeItemAtPath:sgfTemporaryFilePath error:nil];
    assert(0);
    return false;
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:gameSavedToArchive object:self.fileName];
  [[NSNotificationCenter defaultCenter] postNotificationName:archiveContentChanged object:nil];
  return true;
}

@end
