// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "KomiSelectionController.h"
#import "../ui/TableViewCellFactory.h"
#import "../utility/NSStringAdditions.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "komi selection" table view.
// -----------------------------------------------------------------------------
enum KomiSelectionTableViewSection
{
  HandicapGameSection,
  NoHandicapGameSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the HandicapGameSection.
// -----------------------------------------------------------------------------
enum HandicapGameSectionItem
{
  NoKomiItem,
  HalfKomiItem,
  MaxHandicapGameSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the NoHandicapGameSection.
// -----------------------------------------------------------------------------
enum NoHandicapGameSectionItem
{
  MinimumKomiItem = 5,
  MaximumKomiItem = 8,
  MaxNoHandicapGameSectionItem = (2 * (MaximumKomiItem - MinimumKomiItem) + 1)
};


@implementation KomiSelectionController

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a KomiSelectionController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (KomiSelectionController*) controllerWithDelegate:(id<KomiSelectionDelegate>)delegate defaultKomi:(double)komi
{
  KomiSelectionController* controller = [[KomiSelectionController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.komi = komi;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this KomiSelectionController
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
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancel:)] autorelease];
  self.navigationItem.title = @"Komi";
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(done:)] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
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
    case HandicapGameSection:
      return MaxHandicapGameSectionItem;
    case NoHandicapGameSection:
      return MaxNoHandicapGameSectionItem;
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
    case HandicapGameSection:
      return @"Komi for handicap games";
    case NoHandicapGameSection:
      return @"Komi for games with no handicap";
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
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];

  double cellKomiValue = [self komiValueForRowAtIndexPath:indexPath];
  cell.textLabel.text = [NSString stringWithKomi:cellKomiValue numericZeroValue:false];

  if (cellKomiValue == self.komi)
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
  double newKomi = [self komiValueForRowAtIndexPath:indexPath];
  if (self.komi == newKomi)
    return;
  // Remove the checkmark from the previously selected cell
  NSIndexPath* previousIndexPath = [self indexPathForKomiValue:self.komi];
  UITableViewCell* previousCell = [tableView cellForRowAtIndexPath:previousIndexPath];
  if (previousCell.accessoryType == UITableViewCellAccessoryCheckmark)
    previousCell.accessoryType = UITableViewCellAccessoryNone;
  // Add the checkmark to the newly selected cell
  UITableViewCell* newCell = [tableView cellForRowAtIndexPath:indexPath];
  if (newCell.accessoryType == UITableViewCellAccessoryNone)
    newCell.accessoryType = UITableViewCellAccessoryCheckmark;
  // Last but not least, remember the new selection
  self.komi = newKomi;
}

// -----------------------------------------------------------------------------
/// @brief Returns the komi value displayed by the cell at @a indexPath.
// -----------------------------------------------------------------------------
- (double) komiValueForRowAtIndexPath:(NSIndexPath*)indexPath
{
  double komiValue = 0;
  switch (indexPath.section)
  {
    case HandicapGameSection:
    {
      switch (indexPath.row)
      {
        case NoKomiItem:
        {
          komiValue = 0;
          break;
        }
        case HalfKomiItem:
        {
          komiValue = 0.5;
          break;
        }
        default:
          assert(0);
          break;
      }
      break;
    }
    case NoHandicapGameSection:
    {
      komiValue = MinimumKomiItem + (indexPath.row / 2.0);
      assert(komiValue >= MinimumKomiItem && komiValue <= MaximumKomiItem);
      break;
    }
    default:
      assert(0);
      break;
  }
  return komiValue;
}

// -----------------------------------------------------------------------------
/// @brief Returns the index path of the cell that displays the komi value
/// @a komiValue
// -----------------------------------------------------------------------------
- (NSIndexPath*) indexPathForKomiValue:(double)komiValue
{
  int section;
  int row;
  if (0.0 == komiValue)
  {
    section = HandicapGameSection;
    row = NoKomiItem;
  }
  else if (0.5 == komiValue)
  {
    section = HandicapGameSection;
    row = HalfKomiItem;
  }
  else
  {
    section = NoHandicapGameSection;
    row = 2 * (komiValue - MinimumKomiItem);
    assert(komiValue >= MinimumKomiItem && komiValue <= MaximumKomiItem);
  }
  return [NSIndexPath indexPathForRow:row inSection:section];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished selecting komi value.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  [self.delegate komiSelectionController:self didMakeSelection:true];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled selecting a komi value.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  [self.delegate komiSelectionController:self didMakeSelection:false];
}

@end
