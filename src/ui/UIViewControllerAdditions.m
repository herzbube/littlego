// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "UIViewControllerAdditions.h"


@implementation UIViewController(UIViewControllerAdditions)

// -----------------------------------------------------------------------------
/// @brief Displays an alert with title @a title, message @a message and a
/// single button labeled "Ok". The receiver of the message is the presenting
/// view controller.
///
/// Control immediately returns to the caller who invoked this method.
// -----------------------------------------------------------------------------
- (void) presentOkAlertWithTitle:(NSString*)title message:(NSString*)message
{
  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction* action) {}];
  [alertController addAction:okAction];

  [self presentViewController:alertController animated:YES completion:nil];
}

@end
