// -----------------------------------------------------------------------------
// Copyright 2014-2016 Patrick Näf (herzbube@herzbube.ch)
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
#import "ArchiveUtility.h"
#import "../ui/UIViewControllerAdditions.h"


@implementation ArchiveUtility

// -----------------------------------------------------------------------------
/// @brief Validates @a name whether it can be used as the name of an archived
/// game.
///
/// This method should be used to validate user input before the input is used
/// to actually save a game.
// -----------------------------------------------------------------------------
+ (enum ArchiveGameNameValidationResult) validateGameName:(NSString*)name
{
  // TODO Change this check for illegal characters to also use NSPredicate.
  // Note that in a first attempt, the following predicate format string did
  // not work: @"SELF MATCHES '[/\\\\|]+'"
  NSCharacterSet* illegalCharacterSet = [NSCharacterSet characterSetWithCharactersInString:illegalArchiveGameNameCharacters];
  NSRange range = [name rangeOfCharacterFromSet:illegalCharacterSet];
  if (range.location != NSNotFound)
    return ArchiveGameNameValidationResultIllegalCharacters;

  NSString* predicateFormatString = [NSString stringWithFormat:@"SELF MATCHES '^(\\\\.|\\\\.\\\\.|%@)$'", inboxFolderName];
  NSPredicate* predicateReservedWords = [NSPredicate predicateWithFormat:predicateFormatString];
  if ([predicateReservedWords evaluateWithObject:name])
    return ArchiveGameNameValidationResultReservedWord;

  return ArchiveGameNameValidationResultValid;
}

// -----------------------------------------------------------------------------
/// @brief Displays an alert with a generic error message that matches
/// @a validationResult. Returns immediately without waiting for the user
/// dismissing the alert.
// -----------------------------------------------------------------------------
+ (void) showAlertForFailedGameNameValidation:(enum ArchiveGameNameValidationResult)validationResult
                               alertPresenter:(UIViewController*)presenter
{
  NSString* alertTitle;
  NSString* alertMessage;
  switch (validationResult)
  {
    case ArchiveGameNameValidationResultIllegalCharacters:
    {
      alertTitle = @"Illegal characters in game name";
      alertMessage = [NSString stringWithFormat:@"The name you entered contains one or more of the following illegal characters: %@. Please remove the character(s) and try again.", illegalArchiveGameNameCharacters];
      break;
    }
    case ArchiveGameNameValidationResultReservedWord:
    {
      alertTitle = @"Illegal game name";
      alertMessage = @"The name you entered is a reserved word and cannot be used for saving games.";
      break;
    }
    default:
    {
      DDLogError(@"%@: Unexpected validation result %d", self, validationResult);
      assert(0);
      return;
    }
  }

  [presenter presentOkAlertWithTitle:alertTitle message:alertMessage];
}

@end
