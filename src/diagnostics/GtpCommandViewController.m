// -----------------------------------------------------------------------------
// Copyright 2011-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "GtpCommandViewController.h"
#import "GtpCommandModel.h"
#import "../main/ApplicationDelegate.h"
#import "../ui/EditTextController.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UIViewControllerAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GtpCommandViewController.
// -----------------------------------------------------------------------------
@interface GtpCommandViewController()
@property(nonatomic, retain) GtpCommandModel* model;
@end


@implementation GtpCommandViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GtpCommandViewController instance
/// of plain style.
// -----------------------------------------------------------------------------
+ (GtpCommandViewController*) controller
{
  GtpCommandViewController* controller = [[GtpCommandViewController alloc] initWithStyle:UITableViewStylePlain];
  if (controller)
  {
    [controller autorelease];
    controller.model = [ApplicationDelegate sharedDelegate].gtpCommandModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpCommandViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.model = nil;
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
                                                                              action:@selector(addCommand:)] autorelease];
  addButton.style = UIBarButtonItemStylePlain;
  self.navigationItem.rightBarButtonItems = @[self.editButtonItem, addButton];
  self.navigationItem.title = @"Commands";
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
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  // Cast is required because NSInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31)
  // commands.
  cell.textLabel.text = [self.model commandStringAtIndex:(int)indexPath.row];
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
      // Cast is required because NSInteger and int differ in size in 64-bit.
      // Cast is safe because this app was not made to handle more than
      // pow(2, 31) commands.
      [self.model removeCommandAtIndex:(int)indexPath.row];
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
  // Cast is required because NSInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31)
  // commands.
  [self.model moveCommandAtIndex:(int)fromIndexPath.row toIndex:(int)toIndexPath.row];
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
  [self editCommandAtIndex:(int)indexPath.row];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Displays EditTextController to allow the user to add a new GTP
/// command to the list of canned commands.
// -----------------------------------------------------------------------------
- (void) addCommand:(id)sender
{
  EditTextController* editTextController = [[EditTextController controllerWithText:@""
                                                                             style:EditTextControllerStyleTextField
                                                                          delegate:self] retain];
  editTextController.title = @"New command";
  editTextController.context = [NSNumber numberWithInt:-1];
  [self presentNavigationControllerWithRootViewController:editTextController];
  [editTextController release];
}

// -----------------------------------------------------------------------------
/// @brief Displays EditTextController to allow the user to edit the GTP command
/// at index position @a index in the list of canned commands.
// -----------------------------------------------------------------------------
- (void) editCommandAtIndex:(int)index
{
  NSString* commandString = [self.model commandStringAtIndex:index];
  EditTextController* editTextController = [[EditTextController controllerWithText:commandString
                                                                             style:EditTextControllerStyleTextField
                                                                          delegate:self] retain];
  editTextController.title = @"Edit command";
  editTextController.context = [NSNumber numberWithInt:index];
  [self presentNavigationControllerWithRootViewController:editTextController];
  [editTextController release];
}

#pragma mark - EditTextDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  return true;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel
{
  if (! didCancel)
  {
    int context = [editTextController.context intValue];
    if (-1 == context)
    {
      [self.model addCommand:editTextController.text];
      [self.tableView reloadData];
    }
    else
    {
      [self.model replaceCommandAtIndex:context withCommand:editTextController.text];
      NSUInteger sectionIndex = 0;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:context inSection:sectionIndex];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
