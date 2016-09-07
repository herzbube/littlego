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
#import "GtpLogItemViewController.h"
#import "GtpLogItem.h"
#import "GtpCommandModel.h"
#import "../main/ApplicationDelegate.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiElementMetrics.h"


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
/// @brief Class extension with private properties for GtpLogItemViewController.
// -----------------------------------------------------------------------------
@interface GtpLogItemViewController()
@property(nonatomic, retain) GtpLogItem* logItem;
@end


@implementation GtpLogItemViewController

#pragma mark - Initialization and deallocation

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
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.logItem = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.tableView.estimatedRowHeight = [UiElementMetrics tableViewCellSize].height;

  self.navigationItem.title = @"GTP Log Item";

  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  if (! [delegate.gtpCommandModel hasCommand:self.logItem.commandString])
  {
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                            target:self
                                                                                            action:@selector(addToCannedCommands:)] autorelease];
  }

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gtpLogItemChanged:)
                                               name:gtpLogItemChanged
                                             object:nil];
}

#pragma mark - UITableViewDataSource overrides

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
  NSString* reusableCellIdentifier;
  if ((CommandSection == indexPath.section && CommandStringItem == indexPath.row)
      || (ResponseStringSection == indexPath.section && ResponseStringItem == indexPath.row))
  {
    cellType = DefaultCellType;
    if (CommandSection == indexPath.section)
      reusableCellIdentifier = @"CommandStringCell";
    else
      reusableCellIdentifier = @"ResponseStringCell";
  }
  else
  {
    cellType = Value1CellType;
    reusableCellIdentifier = @"Value1CellType";
  }
  UITableViewCell* cell = [TableViewCellFactory cellWithType:cellType tableView:tableView reusableCellIdentifier:reusableCellIdentifier];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  switch (indexPath.section)
  {
    case CommandSection:
    {
      switch (indexPath.row)
      {
        case CommandStringItem:
          cell.textLabel.text = self.logItem.commandString;
          cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
          cell.textLabel.numberOfLines = 0;
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
          cell.textLabel.text = self.logItem.parsedResponseString;
          cell.textLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:[UIFont labelFontSize]];
          cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
          cell.textLabel.numberOfLines = 0;
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

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #gtpLogItemChanged notification.
// -----------------------------------------------------------------------------
- (void) gtpLogItemChanged:(NSNotification*)notification
{
  if (self.logItem == [notification object])
    [self.tableView reloadData];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "add" button in the navigation item.
/// Adds the command from this log item to the list of canned commands.
// -----------------------------------------------------------------------------
- (void) addToCannedCommands:(id)sender
{
  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  GtpCommandModel* model = delegate.gtpCommandModel;
  [model addCommand:self.logItem.commandString];

  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Command added"
                                                                           message:@"The command was added to the list of predefined commands."
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction* action) {}];
  [alertController addAction:okAction];

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentViewController:alertController animated:YES completion:nil];

  // Make sure the command cannot be added a second time
  self.navigationItem.rightBarButtonItem = nil;
}

@end
