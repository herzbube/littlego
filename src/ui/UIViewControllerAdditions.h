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


// Forward declarations
@class NSString;


// -----------------------------------------------------------------------------
/// @brief The UIViewControllerAdditions category enhances UIViewController by
/// adding a number of useful methods.
// -----------------------------------------------------------------------------
@interface UIViewController(UIViewControllerAdditions)

- (void) presentOkAlertWithTitle:(NSString*)title
                         message:(NSString*)message;
- (void) presentOkAlertWithTitle:(NSString*)title
                         message:(NSString*)message
                       okHandler:(void (^)(UIAlertAction* action))okHandler;
- (void) presentYesNoAlertWithTitle:(NSString*)title
                            message:(NSString*)message
                         yesHandler:(void (^)(UIAlertAction* action))yesHandler
                          noHandler:(void (^)(UIAlertAction* action))noHandler;
- (void) presentTwoButtonAlertWithTitle:(NSString*)title
                                message:(NSString*)message
                       firstActionTitle:(NSString*)firstActionTitle
                     firstActionHandler:(void (^)(UIAlertAction* action))firstActionHandler
                      secondActionTitle:(NSString*)secondActionTitle
                    secondActionHandler:(void (^)(UIAlertAction* action))secondActionHandler;
- (void) presentDestructiveAlertWithTitle:(NSString*)title
                                  message:(NSString*)message
                   destructiveActionTitle:(NSString*)destructiveActionTitle
                       destructiveHandler:(void (^)(UIAlertAction* action))destructiveHandler
                            cancelHandler:(void (^)(UIAlertAction* action))cancelHandler;
- (void) presentNavigationControllerWithRootViewController:(UIViewController*)rootViewController;
- (void) presentNavigationControllerWithRootViewController:(UIViewController*)rootViewController
                                         usingPopoverStyle:(bool)usePopoverStyle
                                         popoverSourceView:(UIView*)sourceView
                                      popoverBarButtonItem:(UIBarButtonItem*)barButtonItem;

@end
