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
#import "HandleDocumentInteraction.h"
#import "game/LoadGameCommand.h"
#import "../main/ApplicationDelegate.h"
#import "../utility/PathUtilities.h"


@implementation HandleDocumentInteraction

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  if (! delegate.documentInteractionURL)
    return false;
  // The NewGameController is GUI stuff, so it must be presented in the main
  // thread context. This command, however, may be executed by another command
  // that is asynchronous, i.e. execution in this case occurs in a secondary
  // thread.
  [self performSelectorOnMainThread:@selector(doItInMainThread) withObject:nil waitUntilDone:YES];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt(). doIt() always invokes this in the main
/// thread's context.
// -----------------------------------------------------------------------------
- (void) doItInMainThread
{
  NewGameController* newGameController = [[NewGameController controllerWithDelegate:self loadGame:true] retain];
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:newGameController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  [delegate.tabBarController presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
  [newGameController release];
  [self retain];
}

// -----------------------------------------------------------------------------
/// @brief NewGameDelegate protocol method
// -----------------------------------------------------------------------------
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  [appDelegate.tabBarController dismissViewControllerAnimated:YES completion:nil];
  if (didStartNewGame)
  {
    [appDelegate activateTab:TabTypePlay];
    if ([self moveDocumentInteractionFileToBackupFile])
      [self loadGameFromBackup];
    else
      [self deleteDocumentInteractionFile];
  }
  else
  {
    [self deleteDocumentInteractionFile];
  }
  [self autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for newGameController:didStartNewGame:().
// -----------------------------------------------------------------------------
- (bool) moveDocumentInteractionFileToBackupFile
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  NSString* documentInteractionFilePath = [appDelegate.documentInteractionURL path];
  NSString* backupFilePath = [PathUtilities backupFilePath:sgfBackupFileName];
  NSError* error;
  BOOL success = [PathUtilities moveItemAtPath:documentInteractionFilePath overwritePath:backupFilePath error:&error];
  if (success)
  {
    return true;
  }
  else
  {
    NSString* message = [NSString stringWithFormat:@"Internal error: Failed to move .sgf file, reason: %@",
                         [error localizedDescription]];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Failed to load game"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    alert.tag = AlertViewTypeHandleDocumentInteractionFailed;
    [alert show];
    [alert release];
    return false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for newGameController:didStartNewGame:().
// -----------------------------------------------------------------------------
- (void) loadGameFromBackup
{
  NSString* backupFilePath = [PathUtilities backupFilePath:sgfBackupFileName];
  LoadGameCommand* command = [[[LoadGameCommand alloc] initWithFilePath:backupFilePath] autorelease];
  command.restoreMode = true;
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for newGameController:didStartNewGame:().
// -----------------------------------------------------------------------------
- (void) deleteDocumentInteractionFile
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  NSString* documentInteractionFilePath = [appDelegate.documentInteractionURL path];
  [PathUtilities deleteItemIfExists:documentInteractionFilePath];
}

@end
