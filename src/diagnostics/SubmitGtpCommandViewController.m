// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "../gtp/GtpCommand.h"
#import "../main/ApplicationDelegate.h"
#import "../ui/AutoLayoutUtility.h"
#import "../ui/EditTextController.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiUtilities.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// SubmitGtpCommandViewController.
// -----------------------------------------------------------------------------
@interface SubmitGtpCommandViewController()
@property(nonatomic, retain) GtpCommandModel* model;
@property(nonatomic, retain) UITextField* textField;
@property(nonatomic, retain) UITableView* tableView;
@end


@implementation SubmitGtpCommandViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor.
// -----------------------------------------------------------------------------
+ (SubmitGtpCommandViewController*) controller
{
  SubmitGtpCommandViewController* controller = [[SubmitGtpCommandViewController alloc] initWithNibName:nil bundle:nil];
  if (controller)
  {
    [controller autorelease];
    controller.model = [ApplicationDelegate sharedDelegate].gtpCommandModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SubmitGtpCommandViewController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.model = nil;
  self.textField = nil;
  self.tableView = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self setupTextField];
  [self setupTableView];
  [self setupNavigationItem];
  [self setupAutoLayoutConstraints];
}

#pragma mark - Setup text field

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupTextField
{
  self.textField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.textField];
  [self configureTextField];
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) configureTextField
{
  self.textField.placeholder = @"Enter new command, or select from the list";
  self.textField.borderStyle = UITextBorderStyleRoundedRect;
  self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
  self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
  self.textField.adjustsFontSizeToFitWidth = YES;
  self.textField.minimumFontSize = 12;
  self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  self.textField.spellCheckingType = UITextSpellCheckingTypeNo;

  self.textField.delegate = self;
}

#pragma mark - Setup text view

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupTableView
{
  self.tableView = [[[UITableView alloc] initWithFrame:CGRectZero
                                                 style:UITableViewStylePlain] autorelease];
  [self.view addSubview:self.tableView];
  [self configureTableView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) configureTableView
{
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
}

#pragma mark - Setup other view stuff

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupNavigationItem
{
  self.navigationItem.title = @"New command";
  UIBarButtonItem* submitButton = [[[UIBarButtonItem alloc] initWithTitle:@"Submit"
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(submitCommand:)] autorelease];
  self.navigationItem.rightBarButtonItem = submitButton;
  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:self.textField.text];
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.edgesForExtendedLayout = UIRectEdgeNone;

  self.textField.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.textField, @"textField",
                                   self.tableView, @"tableView",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-[textField]-|",
                            @"H:|-0-[tableView]-0-|",
                            // We want the text field to be offset from the
                            // superview's top edge. We can't use AutoLayout's
                            // default (i.e. visual format "V:|-[textField]")
                            // for this because starting with iOS 8 this default
                            // has become 0.
                            [NSString stringWithFormat:@"V:|-%f-[textField]-[tableView]-|", [UiElementMetrics verticalSpacingSuperview]],
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.view];
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return 1;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.model.commandCount;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
  // Cast is required because NSInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31)
  // commands.
  cell.textLabel.text = [self.model commandStringAtIndex:(int)indexPath.row];
  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  // Cast is required because NSInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31)
  // commands.
  self.textField.text = [self.model commandStringAtIndex:(int)indexPath.row];
  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:self.textField.text];
}

#pragma mark - UITextFieldDelegate overrides

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

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Submits a GTP command using the text entered by the user as the
/// command text.
// -----------------------------------------------------------------------------
- (void) submitCommand:(id)sender
{
  GtpCommand* command = [GtpCommand command:self.textField.text];
  command.waitUntilDone = false;
  [command submit];
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if @a text is acceptable as valid input.
// -----------------------------------------------------------------------------
- (bool) isTextAcceptable:(NSString*)aText
{
  return (aText.length > 0);
}

@end
