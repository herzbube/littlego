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
#import "../shared/LayoutManager.h"


@implementation UIViewController(UIViewControllerAdditions)

// -----------------------------------------------------------------------------
/// @brief Displays an alert with title @a title, message @a message and a
/// single button labeled "Ok". The receiver of the message is the presenting
/// view controller.
///
/// Control immediately returns to the caller who invoked this method.
// -----------------------------------------------------------------------------
- (void) presentOkAlertWithTitle:(NSString*)title
                         message:(NSString*)message
{
  [self presentOkAlertWithTitle:title message:message okHandler:nil];
}

// -----------------------------------------------------------------------------
/// @brief Displays an alert with title @a title, message @a message and a
/// single button labeled "Ok" which execute @a okHandler when pressed. The
/// receiver of the message is the presenting view controller.
///
/// @a okHandler may be @e nil to indicate that nothing should be done when the
/// button is pressed.
///
/// Control immediately returns to the caller who invoked this method.
// -----------------------------------------------------------------------------
- (void) presentOkAlertWithTitle:(NSString*)title
                         message:(NSString*)message
                       okHandler:(void (^)(UIAlertAction* action))okHandler
{
  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  if (! okHandler)
    okHandler = ^(UIAlertAction* action) {};
  UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleDefault
                                                   handler:okHandler];
  [alertController addAction:okAction];

  [self presentViewController:alertController animated:YES completion:nil];
}

// -----------------------------------------------------------------------------
/// @brief Displays an alert with title @a title, message @a message and two
/// buttons labeled "No" and "Yes" which execute @a yesHandler and @a noHandler,
/// respectively, when pressed. The receiver of the message is the presenting
/// view controller.
///
/// @a yesHandler and @a noHandler may be @e nil to indicate that nothing should
/// be done when the respective button is pressed.
///
/// The "no" button uses @e UIAlertActionStyleCancel.
///
/// Control immediately returns to the caller who invoked this method.
// -----------------------------------------------------------------------------
- (void) presentYesNoAlertWithTitle:(NSString*)title
                            message:(NSString*)message
                         yesHandler:(void (^)(UIAlertAction* action))yesHandler
                          noHandler:(void (^)(UIAlertAction* action))noHandler;
{
  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  if (! noHandler)
    noHandler = ^(UIAlertAction* action) {};
  UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"No"
                                                     style:UIAlertActionStyleCancel
                                                   handler:noHandler];
  [alertController addAction:noAction];

  if (! yesHandler)
    yesHandler = ^(UIAlertAction* action) {};
  UIAlertAction* yesAction = [UIAlertAction actionWithTitle:@"Yes"
                                                      style:UIAlertActionStyleDefault
                                                    handler:yesHandler];
  [alertController addAction:yesAction];

  [self presentViewController:alertController animated:YES completion:nil];
}

// -----------------------------------------------------------------------------
/// @brief Displays an alert with title @a title, message @a message and two
/// buttons labeled @a firstActionTitle and @a secondActionTitle which execute
/// @a firstActionHandler and @a secondActionHandler, respectively, when
/// pressed. The receiver of the message is the presenting view controller.
///
/// @a firstActionHandler and @a secondActionHandler may be @e nil to indicate
/// that nothing should be done when the respective button is pressed.
///
/// Both buttons use @e UIAlertActionStyleDefault.
///
/// Control immediately returns to the caller who invoked this method.
// -----------------------------------------------------------------------------
- (void) presentTwoButtonAlertWithTitle:(NSString*)title
                                message:(NSString*)message
                       firstActionTitle:(NSString*)firstActionTitle
                     firstActionHandler:(void (^)(UIAlertAction* action))firstActionHandler
                      secondActionTitle:(NSString*)secondActionTitle
                    secondActionHandler:(void (^)(UIAlertAction* action))secondActionHandler
{
  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  if (! firstActionHandler)
    firstActionHandler = ^(UIAlertAction* action) {};
  UIAlertAction* firstAction = [UIAlertAction actionWithTitle:firstActionTitle
                                                        style:UIAlertActionStyleDefault
                                                      handler:firstActionHandler];
  [alertController addAction:firstAction];

  if (! secondActionHandler)
    secondActionHandler = ^(UIAlertAction* action) {};
  UIAlertAction* secondAction = [UIAlertAction actionWithTitle:secondActionTitle
                                                         style:UIAlertActionStyleDefault
                                                       handler:secondActionHandler];
  [alertController addAction:secondAction];

  [self presentViewController:alertController animated:YES completion:nil];
}

// -----------------------------------------------------------------------------
/// @brief Displays an alert with title @a title, message @a message and two
/// buttons labeled @a destructiveActionTitle and "Cancel" which execute
/// @a destructiveHandler and @a cancelHandler, respectively, when pressed.
/// The receiver of the message is the presenting view controller.
///
/// @a destructiveHandler and @a cancelHandler may be @e nil to indicate that
/// nothing should be done when the respective button is pressed.
///
/// The destructive action button uses @e UIAlertActionStyleDestructive, the
/// "Cancel" button uses @e UIAlertActionStyleCancel.
///
/// If the device's idiom is @e UIUserInterfaceIdiomPhone the alert uses
/// @e UIAlertControllerStyleActionSheet instead of the usual
/// @e UIAlertControllerStyleAlert.
///
/// Control immediately returns to the caller who invoked this method.
// -----------------------------------------------------------------------------
- (void) presentDestructiveAlertWithTitle:(NSString*)title
                                  message:(NSString*)message
                   destructiveActionTitle:(NSString*)destructiveActionTitle
                       destructiveHandler:(void (^)(UIAlertAction* action))destructiveHandler
                            cancelHandler:(void (^)(UIAlertAction* action))cancelHandler
{
  UIAlertControllerStyle alertControllerStyle;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    alertControllerStyle = UIAlertControllerStyleActionSheet;
  else
    alertControllerStyle = UIAlertControllerStyleAlert;
  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:alertControllerStyle];

  if (! cancelHandler)
    cancelHandler = ^(UIAlertAction* action) {};
  UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:cancelHandler];
  [alertController addAction:cancelAction];

  if (! destructiveHandler)
    destructiveHandler = ^(UIAlertAction* action) {};
  UIAlertAction* destructiveAction = [UIAlertAction actionWithTitle:destructiveActionTitle
                                                              style:UIAlertActionStyleDestructive
                                                            handler:destructiveHandler];
  [alertController addAction:destructiveAction];

  [self presentViewController:alertController animated:YES completion:nil];
}

// -----------------------------------------------------------------------------
/// @brief Creates a new UINavigationController using @a rootViewController as
/// the navigation stack's root view controller. Presents the navigation
/// controller in the automatic style.
///
/// Control immediately returns to the caller who invoked this method.
///
/// The caller is responsible for dismissing the presented navigation
/// controller.
// -----------------------------------------------------------------------------
- (void) presentNavigationControllerWithRootViewController:(UIViewController*)rootViewController
{
  [self presentNavigationControllerWithRootViewController:rootViewController
                                        usingPopoverStyle:false
                                        popoverSourceView:nil];
}

// -----------------------------------------------------------------------------
/// @brief Creates a new UINavigationController using @a rootViewController as
/// the navigation stack's root view controller. Presents the navigation
/// controller either in a popover pointing to @a sourceView if
/// @a usePopoverStyle is true, or in the automatic style if @a usePopoverStyle
/// is false.
///
/// Control immediately returns to the caller who invoked this method.
///
/// The caller is responsible for dismissing the presented navigation
/// controller.
// -----------------------------------------------------------------------------
- (void) presentNavigationControllerWithRootViewController:(UIViewController*)rootViewController
                                         usingPopoverStyle:(bool)usePopoverStyle
                                         popoverSourceView:(UIView*)sourceView;
{
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:rootViewController];
  navigationController.delegate = [LayoutManager sharedManager];

  if (usePopoverStyle)
  {
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    if (navigationController.popoverPresentationController)
    {
      navigationController.popoverPresentationController.sourceView = sourceView;
      navigationController.popoverPresentationController.sourceRect = sourceView.bounds;
    }
  }
  else
  {
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  }

  [self presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
}

@end
