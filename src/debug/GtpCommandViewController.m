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
#import "GtpCommandViewController.h"
#import "GtpCommandModel.h"
#import "../ApplicationDelegate.h"
#import "../ui/EditTextController.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GtpCommandViewController.
// -----------------------------------------------------------------------------
@interface GtpCommandViewController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name EditTextDelegate protocol
//@{
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text;
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
//@}
/// @name Action methods
//@{
- (void) addCommand:(id)sender;
- (void) editCommandAtIndex:(int)index;
//@}
/// @name Private helpers
//@{
- (void) setupNavigationItem;
//@}
@end


@implementation GtpCommandViewController

@synthesize model;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GtpCommandViewController instance
/// of plain style.
// -----------------------------------------------------------------------------
+ (GtpCommandViewController*) controller
{
  GtpCommandViewController* controller = [[GtpCommandViewController alloc] initWithStyle:UITableViewStylePlain];
  if (controller)
    [controller autorelease];
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
  // 105.0 determined experimentally in IB
  // 44.01 taken from examples on the Internet; this values seems to shift the
  // toolbar up 1px for some reason
  UIToolbar* toolbar = [[UIToolbar alloc]
                        initWithFrame:CGRectMake(0.0f, 0.0f, 105.0f, 44.01f)];
  NSMutableArray* buttons = [[NSMutableArray alloc] initWithCapacity:2];
  [buttons addObject:self.editButtonItem];

  UIBarButtonItem* addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                           target:self
                                                                           action:@selector(addCommand:)];
  addButton.style = UIBarButtonItemStyleBordered;
  [buttons addObject:addButton];
  [addButton release];
  [toolbar setItems:buttons animated:NO];
  [buttons release];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:toolbar] autorelease];

  self.navigationItem.title = @"Commands";
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
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.textLabel.text = [model commandStringAtIndex:indexPath.row];
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
      [self.model removeCommandAtIndex:indexPath.row];
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
  [self.model moveCommandAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  [self editCommandAtIndex:indexPath.row];
}

// -----------------------------------------------------------------------------
/// @brief Displays EditTextController to allow the user to add a new GTP
/// command to the list of canned commands.
// -----------------------------------------------------------------------------
- (void) addCommand:(id)sender
{
  EditTextController* editTextController = [[EditTextController controllerWithText:@"" title:@"New command" delegate:self] retain];
  editTextController.context = [NSNumber numberWithInt:-1];
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:editTextController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentModalViewController:navigationController animated:YES];
  [navigationController release];
  [editTextController release];
}

// -----------------------------------------------------------------------------
/// @brief Displays EditTextController to allow the user to edit the GTP command
/// at index position @a index in the list of canned commands.
// -----------------------------------------------------------------------------
- (void) editCommandAtIndex:(int)index
{
  NSString* commandString = [self.model commandStringAtIndex:index];
  EditTextController* editTextController = [[EditTextController controllerWithText:commandString title:@"Edit command" delegate:self] retain];
  editTextController.context = [NSNumber numberWithInt:index];
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:editTextController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentModalViewController:navigationController animated:YES];
  [navigationController release];
  [editTextController release];
}

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
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
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
  [self dismissModalViewControllerAnimated:YES];
}

@end
