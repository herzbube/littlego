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
#import "GtpLogItemViewController.h"
#import "GtpLogItem.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "GTP Log Item" table view.
// -----------------------------------------------------------------------------
enum GtpLogItemTableViewSection
{
  CommandSection,
  ResponseSection,
  ResponseStringSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the CommandSection.
// -----------------------------------------------------------------------------
enum CommandSectionItem
{
  CommandStringItem,
  TimestampItem,
  MaxCommandSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ResponseSection.
// -----------------------------------------------------------------------------
enum ResponseSectionItem
{
  ResponseStatusItem,
  MaxResponseSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ResponseStringSection.
// -----------------------------------------------------------------------------
enum ResponseStringSectionItem
{
  ResponseStringItem,
  MaxResponseStringSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GtpLogItemViewController.
// -----------------------------------------------------------------------------
@interface GtpLogItemViewController()
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
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Action methods
//@{
- (void) addToCannedCommands:(id)sender;
//@}
/// @name Notification responders
//@{
- (void) gtpLogItemChanged:(NSNotification*)notification;
//@}
@end


@implementation GtpLogItemViewController

@synthesize logItem;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GtpLogItemViewController instance
/// of grouped style that displays data from @a logItem.
// -----------------------------------------------------------------------------
+ (GtpLogItemViewController*) controllerWithLogItem:(GtpLogItem*)logItem;
{
  GtpLogItemViewController* controller = [[GtpLogItemViewController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.logItem = logItem;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpLogItemViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.logItem = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.title = @"GTP Log Item";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                         target:self
                                                                                         action:@selector(addToCannedCommands:)];

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
  return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case CommandSection:
      return MaxCommandSectionItem;
    case ResponseSection:
      return MaxResponseSectionItem;
    case ResponseStringSection:
      return MaxResponseStringSectionItem;
    default:
      assert(0);
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case CommandSection:
      return @"GTP command";
    case ResponseSection:
      return @"GTP response";
    case ResponseStringSection:
      return @"Response string";
    default:
      assert(0);
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  enum TableViewCellType cellType;
  if (ResponseStringSection == indexPath.section && ResponseStringItem == indexPath.row)
    cellType = TextFieldCellType;
  else
    cellType = Value1CellType;
  UITableViewCell* cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  switch (indexPath.section)
  {
    case CommandSection:
    {
      switch (indexPath.row)
      {
        case CommandStringItem:
          cell.textLabel.text = @"Command";
          cell.detailTextLabel.text = self.logItem.commandString;
          break;
        case TimestampItem:
          cell.textLabel.text = @"Submitted on";
          cell.detailTextLabel.text = self.logItem.timeStamp;
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
    case ResponseSection:
    {
      switch (indexPath.row)
      {
        case ResponseStatusItem:
          cell.textLabel.text = @"Status";
          if (! self.logItem.hasResponse)
          {
            cell.detailTextLabel.text = @"No response received yet";
            cell.detailTextLabel.textColor = [UIColor lightGrayColor];
          }
          else
          {
            if (self.logItem.responseStatus)
            {
              cell.detailTextLabel.text = @"Success";
              cell.detailTextLabel.textColor = [UIColor greenColor];
            }
            else
            {
              cell.detailTextLabel.text = @"Failure";
              cell.detailTextLabel.textColor = [UIColor redColor];
            }
          }
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
    case ResponseStringSection:
    {
      switch (indexPath.row)
      {
        case ResponseStringItem:
        {
          UITextField* textField = (UITextField*)[cell viewWithTag:TextFieldCellTextFieldTag];
          textField.text = self.logItem.parsedResponseString;
          textField.placeholder = @"None";
          textField.enabled = NO;  // disable editing
          break;
        }
        default:
          assert(0);
          break;
      }
      break;
    }
    default:
      assert(0);
      break;
  }
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #gtpLogItemChanged notification.
// -----------------------------------------------------------------------------
- (void) gtpLogItemChanged:(NSNotification*)notification
{
  if (self.logItem == [notification object])
    [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "add" button in the navigation item.
/// Adds the command from this log item to the list of canned commands.
// -----------------------------------------------------------------------------
- (void) addToCannedCommands:(id)sender
{
}

@end
