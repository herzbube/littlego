// -----------------------------------------------------------------------------
// Copyright 2013-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "../main/SceneDelegate.h"
#import "../main/MainUtility.h"
#import "../ui/UIViewControllerAdditions.h"
#import "../utility/PathUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// HandleDocumentInteractionCommand.
// -----------------------------------------------------------------------------
@interface HandleDocumentInteractionCommand()
@property(nonatomic, retain) NSArray* documentInteractionUrls;
@end


@implementation HandleDocumentInteractionCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleDocumentInteractionCommand object.
///
/// @note This is the designated initializer of
/// HandleDocumentInteractionCommand.
// -----------------------------------------------------------------------------
- (id) initWithUrls:(NSArray*)documentInteractionUrls
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.documentInteractionUrls = documentInteractionUrls;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this HandleDocumentInteractionCommand
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.documentInteractionUrls = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  bool success = [self moveDocumentInteractionFilesToArchive];
  if (success)
  {
    // UI changes must be made in the main thread context
    [self performSelectorOnMainThread:@selector(activateUIAreaArchive) withObject:nil waitUntilDone:YES];
  }
  return success;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (bool) moveDocumentInteractionFilesToArchive
{
  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  ArchiveViewModel* model = delegate.archiveViewModel;

  NSString* successfullyImportedGameNames = @"";
  NSString* failedImportedGameNames = @"";

  for (NSURL* documentInteractionUrl in self.documentInteractionUrls)
  {
    // The document interaction system places the file in the application's
    // "Inbox" folder (.../Documents/Inbox). From there we have to move it to
    // our "Archive" folder (which is also located in the .../Documents folder).
    NSString* documentInteractionFilePath = [documentInteractionUrl path];
    NSString* documentInteractionFileName = [documentInteractionFilePath lastPathComponent];
    // The file always has an .sgf extension, iOS makes sure of that. Tested
    // with a file downloaded via HTTP where the file has the proper MIME type,
    // but a non-standard extension (i.e. something else than .sgf). When the user
    // selects "Open in..." in Safari, the document interaction system passes the
    // file into the app with the extension .sgf tacked on.
    NSString* preferredGameName = [documentInteractionFileName stringByDeletingPathExtension];
    NSString* uniqueGameName = [model uniqueGameNameForName:preferredGameName];
    NSString* uniqueFilePath = [model filePathForGameWithName:uniqueGameName];
    NSError* error;
    BOOL success = [PathUtilities moveItemAtPath:documentInteractionFilePath overwritePath:uniqueFilePath error:&error];
    if (success)
    {
      successfullyImportedGameNames = [successfullyImportedGameNames stringByAppendingFormat:@"\n- %@",
                                       uniqueGameName];
    }
    else
    {
      // We don't know what exactly went wrong, so we delete both files to be on
      // the safe side
      [PathUtilities deleteItemIfExists:documentInteractionFilePath];
      [PathUtilities deleteItemIfExists:uniqueFilePath];

      failedImportedGameNames = [failedImportedGameNames stringByAppendingFormat:@"\n- %@: %@",
                                       uniqueGameName, [error localizedDescription]];
    }
  }

  NSString* alertMessage = @"";
  if (successfullyImportedGameNames.length > 0)
  {
    alertMessage = [alertMessage stringByAppendingFormat:@"The following games have been imported and stored in the archive:\n%@",
                    successfullyImportedGameNames];
    if (failedImportedGameNames.length > 0)
    {
      alertMessage = [alertMessage stringByAppendingString:@"\n\n"];
    }
  }

  bool allImportsWereSuccessful = true;
  if (failedImportedGameNames.length > 0)
  {
    alertMessage = [alertMessage stringByAppendingFormat:@"The following games could not be imported:\n%@",
                    failedImportedGameNames];
    allImportsWereSuccessful = false;
  }

  [self performSelectorOnMainThread:@selector(showAlert:) withObject:alertMessage waitUntilDone:YES];

  return allImportsWereSuccessful;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for moveDocumentInteractionFilesToArchive().
// -----------------------------------------------------------------------------
- (void) showAlert:(NSString*)alertMessage
{
  [[SceneDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:@"Game import results"
                                                                            message:alertMessage];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (void) activateUIAreaArchive
{
  [[NSNotificationCenter defaultCenter] postNotificationName:archiveContentChanged object:nil];
  [MainUtility activateUIArea:UIAreaArchive];
}

@end
