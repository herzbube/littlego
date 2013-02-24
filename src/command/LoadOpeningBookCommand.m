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
#import "LoadOpeningBookCommand.h"
#import "../main/ApplicationDelegate.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"


@implementation LoadOpeningBookCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* bookFilePath = [[ApplicationDelegate sharedDelegate].resourceBundle pathForResource:openingBookResource ofType:nil];
  if (! [fileManager fileExistsAtPath:bookFilePath])
  {
    DDLogError(@"%@: Opening book file not found: %@", [self shortDescription], bookFilePath);
    return false;
  }
  NSString* bookFileName = [bookFilePath lastPathComponent];
  NSString* bookFileFolder = [bookFilePath stringByDeletingLastPathComponent];

  NSString* oldCurrentDirectory = [fileManager currentDirectoryPath];
  [fileManager changeCurrentDirectoryPath:bookFileFolder];
  DDLogVerbose(@"%@: Working directory changed to %@", [self shortDescription], bookFileFolder);

  NSString* commandString = [NSString stringWithFormat:@"book_load %@", bookFileName];
  GtpCommand* command = [GtpCommand command:commandString];
  command.waitUntilDone = true;
  [command submit];

  [fileManager changeCurrentDirectoryPath:oldCurrentDirectory];
  DDLogVerbose(@"%@: Working directory changed to %@", [self shortDescription], oldCurrentDirectory);

  return command.response.status;
}

@end
