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
#import "GtpEngineProfileSelectionController.h"
#import "../ui/TableViewCellFactory.h"
#import "../ApplicationDelegate.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/GtpEngineProfile.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for
/// GtpEngineProfileSelectionController.
// -----------------------------------------------------------------------------
@interface GtpEngineProfileSelectionController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
//@}
/// @name Action methods
//@{
- (void) done:(id)sender;
- (void) cancel:(id)sender;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Private helpers
//@{
- (bool) isSelectionValid;
//@}
@end


@implementation GtpEngineProfileSelectionController

@synthesize delegate;
@synthesize profile;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a
/// GtpEngineProfileSelectionController instance of grouped style.
// -----------------------------------------------------------------------------
+ (GtpEngineProfileSelectionController*) controllerWithDelegate:(id<GtpEngineProfileSelectionDelegate>)delegate defaultProfile:(GtpEngineProfile*)profile
{
  GtpEngineProfileSelectionController* controller = [[GtpEngineProfileSelectionController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.profile = profile;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// GtpEngineProfileSelectionController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.profile = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  assert(self.delegate != nil);

  // Configure the navigation item representing this controller. This item will
  // be displayed by the navigation controller that wraps this controller in
  // its navigation bar.
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                        target:self
                                                                                        action:@selector(cancel:)];
  self.navigationItem.title = @"Select profile";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(done:)];
  self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
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
/// @brief Invoked when the user has finished selecting a profile.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  [self.delegate gtpEngineProfileSelectionController:self didMakeSelection:true];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled selecting a profile.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  [self.delegate gtpEngineProfileSelectionController:self didMakeSelection:false];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  return [ApplicationDelegate sharedDelegate].gtpEngineProfileModel.profileCount;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
  GtpEngineProfile* cellProfile = [model.profileList objectAtIndex:indexPath.row];
  cell.textLabel.text = cellProfile.name;
  if (cellProfile == self.profile)
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  else
    cell.accessoryType = UITableViewCellAccessoryNone;
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  // Deselect the row that was just selected
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  // Do nothing if the selection did not change
  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
  NSArray* profileList = model.profileList;
  GtpEngineProfile* newProfile = [profileList objectAtIndex:indexPath.row];
  if (self.profile == newProfile)
    return;
  // Remove the checkmark from the previously selected cell
  int previousRow = [profileList indexOfObject:self.profile];
  NSIndexPath* previousIndexPath = [NSIndexPath indexPathForRow:previousRow inSection:0];
  UITableViewCell* previousCell = [tableView cellForRowAtIndexPath:previousIndexPath];
  if (previousCell.accessoryType == UITableViewCellAccessoryCheckmark)
    previousCell.accessoryType = UITableViewCellAccessoryNone;
  // Add the checkmark to the newly selected cell
  UITableViewCell* newCell = [tableView cellForRowAtIndexPath:indexPath];
  if (newCell.accessoryType == UITableViewCellAccessoryNone)
    newCell.accessoryType = UITableViewCellAccessoryCheckmark;
  // Last but not least, remember the new selection
  self.profile = newProfile;
  // Also update the button that lets the user confirm the selection and
  // dismiss the selection screen
  self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the currently selected player is valid.
// -----------------------------------------------------------------------------
- (bool) isSelectionValid
{
  return (self.profile != nil);
}

@end
