// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "../sgf/SaveSgfCommand.h"
#import "../../archive/ArchiveViewModel.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameDocument.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../ui/UIViewControllerAdditions.h"


@implementation SaveGameCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a SaveGameCommand object.
///
/// @note This is the designated initializer of SaveGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithSaveGame:(NSString*)aGameName gameAlreadyExists:(bool)gameAlreadyExists
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.gameName = aGameName;
  self.gameAlreadyExists = gameAlreadyExists;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SaveGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gameName = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  ArchiveViewModel* model = [ApplicationDelegate sharedDelegate].archiveViewModel;
  NSString* fileName = [self.gameName stringByAppendingString:@".sgf"];
  NSString* filePath = [model.archiveFolder stringByAppendingPathComponent:fileName];

  SaveSgfCommand* saveSgfCommand = [[[SaveSgfCommand alloc] initWithSgfFilePath:filePath sgfFileAlreadyExists:self.gameAlreadyExists] autorelease];
  bool success = [saveSgfCommand submit];
  if (success)
  {
    GoGame* game = [GoGame sharedGame];
    [game.document save:self.gameName];

    // We don't create a save point. If the application crashes before the
    // next save point is created by someone else, the change to GoGameDocument
    // will be lost.
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
  }
  else
  {
    [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:@"Failed to save game"
                                                                                    message:saveSgfCommand.errorMessage];
  }

  if (saveSgfCommand.destinationFolderWasTouched)
    [[NSNotificationCenter defaultCenter] postNotificationName:archiveContentChanged object:nil];

  return true;
}

@end
