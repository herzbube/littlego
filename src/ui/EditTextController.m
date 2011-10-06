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
#import "EditTextController.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for EditTextController.
// -----------------------------------------------------------------------------
@interface EditTextController()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
- (void) viewWillAppear:(BOOL)animated;
//@}
/// @name Action methods
//@{
- (void) done:(id)sender;
- (void) cancel:(id)sender;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITextFieldDelegate protocol method.
//@{
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
- (BOOL) textFieldShouldClear:(UITextField*) textField;
- (BOOL) textFieldShouldReturn:(UITextField*) textField;
//@}
/// @name Helpers
//@{
- (bool) isTextAcceptable:(NSString*)aText;
//@}
@end


@implementation EditTextController

@synthesize context;
@synthesize title;
@synthesize delegate;
@synthesize text;
@synthesize placeholder;
@synthesize textHasChanged;
@synthesize acceptEmptyText;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditTextController instance of
/// grouped style that is used to edit @a text.
// -----------------------------------------------------------------------------
+ (EditTextController*) controllerWithText:(NSString*)text title:(NSString*)title delegate:(id<EditTextDelegate>)delegate
{
  EditTextController* controller = [[EditTextController alloc] init];
  if (controller)
  {
    [controller autorelease];
    controller.title = title;
    controller.delegate = delegate;
    controller.text = text;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an EditTextController object.
///
/// @note This is the designated initializer of EditTextController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;

  m_textField = nil;
  self.context = nil;
  self.title = nil;
  self.delegate = nil;
  self.text = nil;
  self.placeholder = nil;
  self.acceptEmptyText = false;
  self.textHasChanged = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditTextController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.context = nil;
  self.title = nil;
  self.delegate = nil;
  self.text = nil;
  self.placeholder = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                        target:self
                                                                                        action:@selector(cancel:)];
  self.navigationItem.title = self.title;
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(done:)];

  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:self.text];
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
/// @brief Invoked when the view is about to made visible.
// -----------------------------------------------------------------------------
- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  // Place the insertion point into the text field
  [m_textField becomeFirstResponder];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished editing the text.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  if (! [self.delegate controller:self shouldEndEditingWithText:m_textField.text])
    return;
  self.textHasChanged = ! [self.text isEqualToString:m_textField.text];
  self.text = m_textField.text;
  [self.delegate didEndEditing:self didCancel:false];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled editing the text.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  [self.delegate didEndEditing:self didCancel:true];
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
  return 1;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (0 != indexPath.section && 0 != indexPath.row)
  {
    assert(false);
    return nil;
  }

  enum TableViewCellType cellType = TextFieldCellType;
  UITableViewCell* cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];

  m_textField = (UITextField*)[cell viewWithTag:TextFieldCellTextFieldTag];
  assert(m_textField != nil);
  m_textField.delegate = self;
  m_textField.text = self.text;
  m_textField.placeholder = self.placeholder;
  m_textField.clearButtonMode = UITextFieldViewModeAlways;

  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
///
/// An alternative to using the delegate protocol is to listen for notifications
/// sent by the text field.
// -----------------------------------------------------------------------------
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
  // Compose the string as it would look like if the proposed change had already
  // been made
  NSString* newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
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
- (BOOL) textFieldShouldClear:(UITextField*) textField
{
  self.navigationItem.rightBarButtonItem.enabled = NO;
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) textFieldShouldReturn:(UITextField*) textField
{
  if (! [self isTextAcceptable:textField.text])
    return NO;
  [self done:nil];
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a text is acceptable as valid input.
// -----------------------------------------------------------------------------
- (bool) isTextAcceptable:(NSString*)aText
{
  if (self.acceptEmptyText)
    return true;
  return (aText.length > 0);
}

@end
