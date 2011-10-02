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
/// @name Privately declared properties
//@{
@property bool lastRowIsVisible;
@property bool updateScheduledByGtpLogItemChanged;
/// TODO This flag exists because we "know" that, if both gtpLogContentChanged
/// and gtpLogItemChanged are sent shortly after each other,
/// gtpLogContentChanged will always be sent first. This is deep knowledge of
/// how GtpLogModel sends its notifications, and we should find a better way
/// for handling update conflicts.
@property bool updateScheduledByGtpLogContentChanged;
//@}
@end


@implementation GtpLogViewController

@synthesize model;
@synthesize lastRowIsVisible;
@synthesize updateScheduledByGtpLogItemChanged;
@synthesize updateScheduledByGtpLogContentChanged;


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

  self.lastRowIsVisible = false;
  self.updateScheduledByGtpLogItemChanged = false;
  self.updateScheduledByGtpLogContentChanged = false;
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
  // We assume that this method is invoked only for a complete rebuild of the
  // view (e.g. when the view is displayed for the first time, or for
  // reloadData()). We can clear the flag here, and it will be set again in
  // tableView:cellForRowAtIndexPath:() as soon as the cell for the last row
  // is requested.
  self.lastRowIsVisible = false;

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
  // If updateScheduledByGtpLogItemChanged is true we must *NOT* clear
  // lastRowIsVisible. See class documentation for an extensive discussion of
  // how the lastRowIsVisible flag is managed.
  if (self.updateScheduledByGtpLogItemChanged)
  {
    self.updateScheduledByGtpLogItemChanged = false;
    assert(! self.updateScheduledByGtpLogContentChanged);
  }
  else
  {
    if (self.lastRowIsVisible)
      self.lastRowIsVisible = false;
    // updateScheduledByGtpLogContentChanged and updateScheduledByGtpLogItemChanged
    // are not expected to be set at the same time.
    if (self.updateScheduledByGtpLogContentChanged)
      self.updateScheduledByGtpLogContentChanged = false;
  }

  int lastRow = self.model.itemCount - 1;  // -1 because table view rows are zero-based
  int row = indexPath.row;
  if (lastRow == row)
    self.lastRowIsVisible = true;

  UITableViewCell* cell = [TableViewCellFactory cellWithType:SubtitleCellType tableView:tableView];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  GtpLogItem* logItem = [self.model itemAtIndex:row];
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
  if (self.lastRowIsVisible)
  {
    // The delay value must be in the range of
    // - "not too short" (so that reloadData() has time to do its work), and
    // - "not too long" (so that the delay does not get noticed by the user)
    NSTimeInterval delay = 0.1;
    [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:delay];
  }

  // Inform gtpLogItemChanged:() that an update has been scheduled by this
  // method.
  self.updateScheduledByGtpLogContentChanged = true;

  [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #gtpLogItemChanged notification.
// -----------------------------------------------------------------------------
- (void) gtpLogItemChanged:(NSNotification*)notification
{
  // If an update has already been scheduled by gtpLogContentChanged:() we don't
  // have to do anything - in fact the number of cells in self.tableView at this
  // time has already been reset, so we can't invoke
  // reloadRowsAtIndexPaths:withRowAnimation:() anyway
  if (self.updateScheduledByGtpLogContentChanged)
    return;

  // Inform tableView:cellForRowAtIndexPath:() that the update is only for a
  // single item (not for scrolling).
  self.updateScheduledByGtpLogItemChanged = true;

  GtpLogItem* logItem = [notification object];
  NSUInteger sectionIndex = 0;
  NSUInteger indexOfItem = [self.model.itemList indexOfObject:logItem];
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:indexOfItem inSection:sectionIndex];
  NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
  [self.tableView reloadRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationNone];
}

// -----------------------------------------------------------------------------
/// @brief Scrolls to the bottom of the view.
// -----------------------------------------------------------------------------
- (void) scrollToBottom
{
  NSUInteger lastRowSection = 0;
  NSUInteger lastRow = self.model.itemCount - 1;  // -1 because table view rows are zero-based
  NSIndexPath* lastRowIndexPath = [NSIndexPath indexPathForRow:lastRow
                                                     inSection:lastRowSection];
  [self.tableView scrollToRowAtIndexPath:lastRowIndexPath
                        atScrollPosition:UITableViewScrollPositionBottom
                                animated:YES];
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
