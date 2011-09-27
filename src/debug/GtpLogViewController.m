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
#import "GtpLogViewController.h"
#import "GtpLogItem.h"
#import "GtpLogItemViewController.h"
#import "GtpLogModel.h"
#import "../ApplicationDelegate.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GtpLogViewController.
// -----------------------------------------------------------------------------
@interface GtpLogViewController()
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
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Action methods
//@{
- (void) composeCommand:(id)sender;
- (void) viewLogItem:(GtpLogItem*)logItem;
//@}
/// @name Notification responders
//@{
- (void) gtpLogContentChanged:(NSNotification*)notification;
- (void) gtpLogItemChanged:(NSNotification*)notification;
//@}
@end


@implementation GtpLogViewController

@synthesize model;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GtpLogViewController instance of
/// plain style.
// -----------------------------------------------------------------------------
+ (GtpLogViewController*) controller
{
  GtpLogViewController* controller = [[GtpLogViewController alloc] initWithStyle:UITableViewStylePlain];
  if (controller)
    [controller autorelease];
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpLogViewController object.
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
  self.model = delegate.gtpLogModel;

  self.navigationItem.title = @"GTP Log";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                         target:self
                                                                                         action:@selector(composeCommand:)];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gtpLogContentChanged:)
                                               name:gtpLogContentChanged
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gtpLogItemChanged:)
                                               name:gtpLogItemChanged
                                             object:nil];
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
  return self.model.itemCount;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:SubtitleCellType tableView:tableView];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  GtpLogItem* logItem = [self.model itemAtIndex:indexPath.row];
  cell.textLabel.text = logItem.commandString;
  cell.detailTextLabel.text = logItem.timeStamp;
  cell.imageView.image = [logItem imageRepresentingResponseStatus];
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  [self viewLogItem:[self.model itemAtIndex:indexPath.row]];
}


// -----------------------------------------------------------------------------
/// @brief Responds to the #gtpLogContentChanged notification.
// -----------------------------------------------------------------------------
- (void) gtpLogContentChanged:(NSNotification*)notification
{
  [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #gtpLogItemChanged notification.
// -----------------------------------------------------------------------------
- (void) gtpLogItemChanged:(NSNotification*)notification
{
  [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "compose" button in the navigation
/// item. Displays a view that allows the user to compose and submit a GTP
/// command.
// -----------------------------------------------------------------------------
- (void) composeCommand:(id)sender
{
}

// -----------------------------------------------------------------------------
/// @brief Displays GtpLogItemViewController to allow the user to view the
/// details of item @a logItem.
// -----------------------------------------------------------------------------
- (void) viewLogItem:(GtpLogItem*)logItem
{
  GtpLogItemViewController* controller = [GtpLogItemViewController controllerWithLogItem:logItem];
  [self.navigationController pushViewController:controller animated:YES];
}

@end
