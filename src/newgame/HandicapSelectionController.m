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
#import "HandicapSelectionController.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Handicap selection" table
/// view.
// -----------------------------------------------------------------------------
enum HandicapSelectionTableViewSection
{
  NoHandicapSection,
  TwoAndMoreHandicapSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the NoHandicapSection.
// -----------------------------------------------------------------------------
enum NoHandicapSectionItem
{
  NoHandicapItem,
  MaxNoHandicapSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the TwoAndMoreHandicapSection.
// -----------------------------------------------------------------------------
enum TwoAndMoreHandicapSectionItem
{
  MinimumHandicapItem = 2
  // MaximumHandicapItem does not exist, it's calculated dynamically using the
  // maximum handicap that has been specified on construction
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for HandicapSelectionController.
// -----------------------------------------------------------------------------
@interface HandicapSelectionController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
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
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Private helpers
//@{
- (int) handicapValueForRowAtIndexPath:(NSIndexPath*)indexPath;
- (NSIndexPath*) indexPathForHandicapValue:(int)handicapValue;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) int maximumHandicap;
//@}
@end


@implementation HandicapSelectionController

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a HandicapSelectionController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (HandicapSelectionController*) controllerWithDelegate:(id<HandicapSelectionDelegate>)delegate defaultHandicap:(int)handicap  maximumHandicap:(int)maximumHandicap
{
  HandicapSelectionController* controller = [[HandicapSelectionController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.handicap = handicap;
    controller.maximumHandicap = maximumHandicap;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this HandicapSelectionController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
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
  self.navigationItem.title = @"Handicap";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(done:)];
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
/// @brief Called by UIKit at various times to determine whether this controller
/// supports the given orientation @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
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
    case NoHandicapSection:
      return MaxNoHandicapSectionItem;
    case TwoAndMoreHandicapSection:
      return (self.maximumHandicap - MinimumHandicapItem + 1);
    default:
      assert(0);
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  if (NoHandicapSection == section)
    return @"There is no handicap 1. Instead of giving a handicap of 1, white should forego komi (set komi to 0 or 0.5) and let black play first. This way black benefits from the absence of komi and is still able to freely choose his or her first move.";
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];

  int cellHandicapValue = [self handicapValueForRowAtIndexPath:indexPath];
  if (0 == cellHandicapValue)
    cell.textLabel.text = @"No handicap";
  else
    cell.textLabel.text = [NSString stringWithFormat:@"%d", cellHandicapValue];

  if (cellHandicapValue == self.handicap)
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
  int newHandicap = [self handicapValueForRowAtIndexPath:indexPath];
  if (self.handicap == newHandicap)
    return;
  // Remove the checkmark from the previously selected cell
  NSIndexPath* previousIndexPath = [self indexPathForHandicapValue:self.handicap];
  UITableViewCell* previousCell = [tableView cellForRowAtIndexPath:previousIndexPath];
  if (previousCell.accessoryType == UITableViewCellAccessoryCheckmark)
    previousCell.accessoryType = UITableViewCellAccessoryNone;
  // Add the checkmark to the newly selected cell
  UITableViewCell* newCell = [tableView cellForRowAtIndexPath:indexPath];
  if (newCell.accessoryType == UITableViewCellAccessoryNone)
    newCell.accessoryType = UITableViewCellAccessoryCheckmark;
  // Last but not least, remember the new selection
  self.handicap = newHandicap;
}

// -----------------------------------------------------------------------------
/// @brief Returns the handicap value displayed by the cell at @a indexPath.
// -----------------------------------------------------------------------------
- (int) handicapValueForRowAtIndexPath:(NSIndexPath*)indexPath
{
  int handicapValue = 0;
  switch (indexPath.section)
  {
    case NoHandicapSection:
    {
      handicapValue = 0;
      break;
    }
    case TwoAndMoreHandicapSection:
    {
      handicapValue = MinimumHandicapItem + indexPath.row;
      assert(handicapValue >= MinimumHandicapItem && handicapValue <= self.maximumHandicap);
      break;
    }
    default:
      assert(0);
      break;
  }
  return handicapValue;
}

// -----------------------------------------------------------------------------
/// @brief Returns the index path of the cell that displays the handicap value
/// @a handicapValue
// -----------------------------------------------------------------------------
- (NSIndexPath*) indexPathForHandicapValue:(int)handicapValue
{
  int section;
  int row;
  if (0 == handicapValue)
  {
    section = NoHandicapSection;
    row = NoHandicapItem;
  }
  else
  {
    section = TwoAndMoreHandicapSection;
    row = handicapValue - MinimumHandicapItem;
    assert(handicapValue >= MinimumHandicapItem && handicapValue <= self.maximumHandicap);
  }
  return [NSIndexPath indexPathForRow:row inSection:section];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished selecting a handicap value.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  [self.delegate handicapSelectionController:self didMakeSelection:true];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled selecting a handicap value.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  [self.delegate handicapSelectionController:self didMakeSelection:false];
}


@end
