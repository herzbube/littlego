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
#import "HandleDocumentInteractionCommand.h"
#import "../archive/ArchiveViewModel.h"
#import "../main/ApplicationDelegate.h"
#import "../main/MainUtility.h"
#import "../utility/PathUtilities.h"


@implementation HandleDocumentInteractionCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  bool success = [self moveDocumentInteractionFileToArchive];
  if (success)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:archiveContentChanged object:nil];
    [MainUtility activateUIArea:UIAreaArchive];
  }
  return success;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (bool) moveDocumentInteractionFileToArchive
{
  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  if (! delegate.documentInteractionURL)
    return false;
  NSString* documentInteractionFilePath = [delegate.documentInteractionURL path];
  NSString* documentInteractionFileName = [documentInteractionFilePath lastPathComponent];
  // The file always has an .sgf extension, iOS makes sure of that. Tested
  // with a file downloaded via HTTP where the file has the proper MIME type,
  // but a non-standard extension (i.e. something else than .sgf). When the user
  // selects "Open in..." in Safari, the document interaction system passes the
  // file into the app with the extension .sgf tacked on.
  NSString* preferredGameName = [documentInteractionFileName stringByDeletingPathExtension];
  ArchiveViewModel* model = delegate.archiveViewModel;
  NSString* uniqueGameName = [model uniqueGameNameForName:preferredGameName];
  NSString* uniqueFilePath = [model filePathForGameWithName:uniqueGameName];
  NSError* error;
  BOOL success = [PathUtilities moveItemAtPath:documentInteractionFilePath overwritePath:uniqueFilePath error:&error];
  if (success)
  {
    NSString* message = [NSString stringWithFormat:@"The game has been imported and stored in the archive under this name:\n\n%@",
                         uniqueGameName];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Game imported"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    alert.tag = AlertViewTypeHandleDocumentInteractionCommandSucceeded;
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    [alert release];
    return true;
  }
  else
  {
    // We don't know what exactly went wrong, so we delete both files to be on
    // the safe side
    [PathUtilities deleteItemIfExists:documentInteractionFilePath];
    [PathUtilities deleteItemIfExists:uniqueFilePath];
    NSString* message = [NSString stringWithFormat:@"The game could not be imported. Reason for the failure: %@",
                         [error localizedDescription]];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Game not imported"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    alert.tag = AlertViewTypeHandleDocumentInteractionCommandFailed;
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    [alert release];
    return false;
  }
}

@end
