// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "../main/ApplicationDelegate.h"
#import "../ui/EditTextController.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiUtilities.h"
#import "../utility/UIColorAdditions.h"
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
- (void) loadView;
- (void) viewDidLoad;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
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
- (CGRect) mainViewFrame;
- (CGRect) textFieldViewFrame;
- (CGRect) tableViewFrame;
- (void) setupNavigationItem;
- (bool) isTextAcceptable:(NSString*)aText;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) UITextField* textField;
//@}
@end


@implementation SubmitGtpCommandViewController

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a SubmitGtpCommandViewController
/// instance that loads its view from a .nib file.
// -----------------------------------------------------------------------------
+ (SubmitGtpCommandViewController*) controller
{
  SubmitGtpCommandViewController* controller = [[SubmitGtpCommandViewController alloc] initWithNibName:nil bundle:nil];
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
/// @brief Creates the view that this controller manages.
// -----------------------------------------------------------------------------
- (void) loadView
{
  CGRect mainViewFrame = [self mainViewFrame];
  self.view = [[[UIView alloc] initWithFrame:mainViewFrame] autorelease];
  CGRect textFieldViewFrame = [self textFieldViewFrame];
  self.textField = [[[UITextField alloc] initWithFrame:textFieldViewFrame] autorelease];
  [self.view addSubview:self.textField];
  CGRect tableViewFrame = [self tableViewFrame];
  UITableView* tableView = [[[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStyleGrouped] autorelease];
  [self.view addSubview:tableView];

  self.textField.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin);
  tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

  self.textField.delegate = self;
  tableView.delegate = self;
  tableView.dataSource = self;

  self.textField.placeholder = @"Enter new command, or select from the list";
  self.textField.borderStyle = UITextBorderStyleRoundedRect;
  self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
  self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
  self.textField.adjustsFontSizeToFitWidth = YES;
  self.textField.minimumFontSize = 12;
  self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  self.textField.spellCheckingType = UITextSpellCheckingTypeNo;

  tableView.backgroundView = nil;
  [UiUtilities addGroupTableViewBackgroundToView:self.view];
}

// -----------------------------------------------------------------------------
/// @brief Calculates the frame of this controller's main view, taking into
/// account the current interface orientation. Assumes that super views have
/// the correct bounds.
// -----------------------------------------------------------------------------
- (CGRect) mainViewFrame
{
  int mainViewX = 0;
  int mainViewY = 0;
  int mainViewWidth = [UiElementMetrics screenWidth];
  int mainViewHeight = ([UiElementMetrics screenHeight]
                        - [UiElementMetrics tabBarHeight]
                        - [UiElementMetrics navigationBarHeight]
                        - [UiElementMetrics statusBarHeight]);
  return CGRectMake(mainViewX, mainViewY, mainViewWidth, mainViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief Calculates the frame of the text field view, taking into account the
/// current interface orientation. Assumes that super views have the correct
/// bounds.
// -----------------------------------------------------------------------------
- (CGRect) textFieldViewFrame
{
  CGSize superViewSize = self.view.bounds.size;
  int textFieldViewX = [UiElementMetrics viewMarginHorizontal];
  int textFieldViewY = [UiElementMetrics viewMarginVertical];
  int textFieldViewWidth = superViewSize.width - 2 * [UiElementMetrics viewMarginHorizontal];
  int textFieldViewHeight = [UiElementMetrics textFieldHeight];
  return CGRectMake(textFieldViewX, textFieldViewY, textFieldViewWidth, textFieldViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief Calculates the frame of the table view, taking into account the
/// current interface orientation. Assumes that super views have the correct
/// bounds.
// -----------------------------------------------------------------------------
- (CGRect) tableViewFrame
{
  CGSize superViewSize = self.view.bounds.size;
  int tableViewX = 0;
  int tableViewY = ([UiElementMetrics viewMarginVertical]
                    + self.textField.bounds.size.height
                    + [UiElementMetrics spacingVertical]);
  int tableViewWidth = superViewSize.width;
  int tableViewHeight = (superViewSize.height
                         - tableViewY
                         - [UiElementMetrics viewMarginHorizontal]);
  return CGRectMake(tableViewX, tableViewY, tableViewWidth, tableViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  self.model = delegate.gtpCommandModel;

  [self setupNavigationItem];
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the navigation item of this view controller.
// -----------------------------------------------------------------------------
- (void) setupNavigationItem
{
  UIBarButtonItem* submitButton = [[[UIBarButtonItem alloc] initWithTitle:@"Submit"
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(submitCommand:)] autorelease];
  self.navigationItem.rightBarButtonItem = submitButton;
  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:self.textField.text];

  self.navigationItem.title = @"New command";
}

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
  cell.textLabel.text = [self.model commandStringAtIndex:indexPath.row];
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  self.textField.text = [self.model commandStringAtIndex:indexPath.row];
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
