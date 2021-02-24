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
#import "SgfDisabledMessagesController.h"
#import "../sgf/SgfSettingsModel.h"
#import "../main/ApplicationDelegate.h"
#import "../shared/LayoutManager.h"
#import "../ui/EditTextController.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UIViewControllerAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// SgfDisabledMessagesController.
// -----------------------------------------------------------------------------
@interface SgfDisabledMessagesController()
@property(nonatomic, retain) SgfSettingsModel* sgfSettingsModel;
@end


@implementation SgfDisabledMessagesController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a SgfDisabledMessagesController
/// instance of plain style.
// -----------------------------------------------------------------------------
+ (SgfDisabledMessagesController*) controllerWithDelegate:(id<SgfDisabledMessagesDelegate>)delegate
{
  SgfDisabledMessagesController* controller = [[SgfDisabledMessagesController alloc] initWithStyle:UITableViewStylePlain];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.sgfSettingsModel = [ApplicationDelegate sharedDelegate].sgfSettingsModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SgfDisabledMessagesController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.sgfSettingsModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  [self setupNavigationItem];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the navigation item of this view controller.
// -----------------------------------------------------------------------------
- (void) setupNavigationItem
{
  UIBarButtonItem* addButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                              target:self
                                                                              action:@selector(addMessage:)] autorelease];
  addButton.style = UIBarButtonItemStylePlain;
  self.navigationItem.rightBarButtonItems = @[self.editButtonItem, addButton];
  self.navigationItem.title = @"Disabled messages";
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
  return self.sgfSettingsModel.disabledMessages.count;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.textLabel.text = [[self.sgfSettingsModel.disabledMessages objectAtIndex:indexPath.row] stringValue];
  cell.showsReorderControl = YES;
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
  switch (editingStyle)
  {
    case UITableViewCellEditingStyleDelete:
    {
      NSMutableArray* mutableDisabledMessages = [self.sgfSettingsModel.disabledMessages.mutableCopy autorelease];
      [mutableDisabledMessages removeObjectAtIndex:indexPath.row];
      self.sgfSettingsModel.disabledMessages = mutableDisabledMessages;

      [self.delegate didChangeDisabledMessages:self];

      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                       withRowAnimation:UITableViewRowAnimationRight];
      break;
    }
    default:
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath
{
  NSMutableArray* mutableDisabledMessages = [self.sgfSettingsModel.disabledMessages.mutableCopy autorelease];
  id elementToMove = [mutableDisabledMessages objectAtIndex:fromIndexPath.row];
  [mutableDisabledMessages removeObjectAtIndex:fromIndexPath.row];
  [mutableDisabledMessages insertObject:elementToMove atIndex:toIndexPath.row];
  self.sgfSettingsModel.disabledMessages = mutableDisabledMessages;

  [self.delegate didChangeDisabledMessages:self];
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
  [self editMessageAtIndex:indexPath.row];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Displays EditTextController to allow the user to add a new message
/// to the list of disabled messages.
// -----------------------------------------------------------------------------
- (void) addMessage:(id)sender
{
  EditTextController* editTextController = [EditTextController controllerWithText:@""
                                                                            style:EditTextControllerStyleTextField
                                                                         delegate:self];
  editTextController.title = @"Add message number";
  editTextController.context = [NSNumber numberWithInteger:-1];
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:editTextController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  navigationController.delegate = [LayoutManager sharedManager];
  [self presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
}

// -----------------------------------------------------------------------------
/// @brief Displays EditTextController to allow the user to edit the message
/// at index position @a index in the list of disabled messages.
// -----------------------------------------------------------------------------
- (void) editMessageAtIndex:(NSInteger)index
{
  NSString* messageIDString = [[self.sgfSettingsModel.disabledMessages objectAtIndex:index] stringValue];
  EditTextController* editTextController = [EditTextController controllerWithText:messageIDString
                                                                            style:EditTextControllerStyleTextField
                                                                         delegate:self];
  editTextController.title = @"Edit message number";
  editTextController.context = [NSNumber numberWithInteger:index];
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:editTextController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  navigationController.delegate = [LayoutManager sharedManager];
  [self presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
}

#pragma mark - EditTextDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  NSString* title = nil;
  NSString* message = nil;

  NSNumber* number = [self numberFromText:text];
  bool isValidNumber = false;
  if (number)
  {
    if ([number integerValue] > 0)
    {
      isValidNumber = true;
    }
    else
    {
      title = @"Not a positive number";
      message = [NSString stringWithFormat:@"The number \"%@\" is zero or negative. Please enter a number greater than zero.", text];
    }
  }
  else
  {
    title = @"Input not numeric";
    message = [NSString stringWithFormat:@"The text \"%@\" is not numeric. Please enter a valid number.", text];
  }

  if (! isValidNumber)
    [editTextController presentOkAlertWithTitle:title message:message];

  return isValidNumber;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
{
  if (! didCancel)
  {
    // The SgfcKit enumeration SGFCMessageID has the underlying type NSInteger,
    // so we can use the NSNumber object as-is
    NSNumber* number = [self numberFromText:editTextController.text];
    NSMutableArray* mutableDisabledMessages = [self.sgfSettingsModel.disabledMessages.mutableCopy autorelease];

    NSInteger context = [editTextController.context integerValue];
    if (-1 == context)
    {
      [mutableDisabledMessages addObject:number];
      self.sgfSettingsModel.disabledMessages = mutableDisabledMessages;

      [self.delegate didChangeDisabledMessages:self];

      [self.tableView reloadData];
    }
    else
    {
      [mutableDisabledMessages replaceObjectAtIndex:context withObject:number];
      self.sgfSettingsModel.disabledMessages = mutableDisabledMessages;

      [self.delegate didChangeDisabledMessages:self];

      NSUInteger sectionIndex = 0;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:context inSection:sectionIndex];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private helpers

- (NSNumber*) numberFromText:(NSString*)text
{
  NSNumberFormatter* numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];

  // Parses the text as an integer. 1234.5678 is parsed as 1234.
  numberFormatter.numberStyle = NSNumberFormatterNoStyle;

  // If the string contains any characters other than numerical digits or
  // locale-appropriate group or decimal separators, parsing will fail.
  // Leading/trailing space is ignored.
  // Returns nil if parsing fails.
  NSNumber* number = [numberFormatter numberFromString:text];

  return number;
}

@end
