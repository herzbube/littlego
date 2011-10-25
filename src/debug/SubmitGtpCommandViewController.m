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
#import "SubmitGtpCommandViewController.h"
#import "GtpCommandModel.h"
#import "../ApplicationDelegate.h"
#import "../ui/EditTextController.h"
#import "../ui/TableViewCellFactory.h"
#import "../gtp/GtpCommand.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for
/// SubmitGtpCommandViewController.
// -----------------------------------------------------------------------------
@interface SubmitGtpCommandViewController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
//@}
/// @name UIPickerViewDataSource protocol
//@{
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)pickerView;
- (NSInteger) pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component;
//@}
/// @name UIPickerViewDelegate protocol
//@{
- (NSString*) pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
- (void) pickerView:(UIPickerView*)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component;
//@}
/// @name UITextFieldDelegate protocol method.
//@{
- (BOOL) textField:(UITextField*)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
- (BOOL) textFieldShouldClear:(UITextField*)aTextField;
- (BOOL) textFieldShouldReturn:(UITextField*)aTextField;
//@}
/// @name Action methods
//@{
- (void) submitCommand:(id)sender;
//@}
/// @name Private helpers
//@{
- (void) setupNavigationItem;
- (bool) isTextAcceptable:(NSString*)aText;
//@}
@end


@implementation SubmitGtpCommandViewController

@synthesize textField;
@synthesize model;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a SubmitGtpCommandViewController
/// instance that loads its view from a .nib file.
// -----------------------------------------------------------------------------
+ (SubmitGtpCommandViewController*) controller
{
  SubmitGtpCommandViewController* controller = [[SubmitGtpCommandViewController alloc] initWithNibName:@"SubmitGtpCommandView" bundle:nil];
  if (controller)
    [controller autorelease];
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SubmitGtpCommandViewController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.model = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
  self.model = delegate.gtpCommandModel;

  [self setupNavigationItem];
}

// -----------------------------------------------------------------------------
/// @brief Called when the controller’s view is released from memory, e.g.
/// during low-memory conditions.
///
/// Releases additional objects (e.g. by resetting references to retained
/// objects) that can be easily recreated when viewDidLoad() is invoked again
/// later.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the navigation item of this view controller.
// -----------------------------------------------------------------------------
- (void) setupNavigationItem
{
  UIBarButtonItem* submitButton = [[UIBarButtonItem alloc] initWithTitle:@"Submit"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(submitCommand:)];
  self.navigationItem.rightBarButtonItem = submitButton;
  [submitButton release];
  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:self.textField.text];

  self.navigationItem.title = @"New command";
}

// -----------------------------------------------------------------------------
/// @brief UIPickerViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)pickerView
{
  return 1;
}

// -----------------------------------------------------------------------------
/// @brief UIPickerViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component
{
  return self.model.commandCount;
}

// -----------------------------------------------------------------------------
/// @brief UIPickerViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (NSString*) pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
  return [model commandStringAtIndex:row];
}

// -----------------------------------------------------------------------------
/// @brief UIPickerViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) pickerView:(UIPickerView*)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
  self.textField.text = [model commandStringAtIndex:row];
  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:self.textField.text];
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
///
/// An alternative to using the delegate protocol is to listen for notifications
/// sent by the text field.
// -----------------------------------------------------------------------------
- (BOOL) textField:(UITextField*)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
  // Compose the string as it would look like if the proposed change had already
  // been made
  NSString* newText = [aTextField.text stringByReplacingCharactersInRange:range withString:string];
  // Make sure that, if the text is not acceptable input, the view cannot be
  // left except by cancelling
  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:newText];
  // Accept all changes, even those that make the text not acceptable input
  // -> the user must simply continue editing until the text becomes acceptable
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) textFieldShouldClear:(UITextField*)aTextField
{
  self.navigationItem.rightBarButtonItem.enabled = NO;
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) textFieldShouldReturn:(UITextField*)aTextField
{
  if (! [self isTextAcceptable:aTextField.text])
    return NO;
  [self submitCommand:nil];
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Displays EditTextController to allow the user to add a new GTP
/// command to the list of canned commands.
// -----------------------------------------------------------------------------
- (void) submitCommand:(id)sender
{
  [[GtpCommand command:self.textField.text] submit];
  [self.navigationController popViewControllerAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a text is acceptable as valid input.
// -----------------------------------------------------------------------------
- (bool) isTextAcceptable:(NSString*)aText
{
  return (aText.length > 0);
}

@end
