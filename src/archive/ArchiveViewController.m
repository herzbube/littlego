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
#import "ArchiveViewController.h"
#import "ArchiveViewModel.h"
#import "ArchiveGame.h"
#import "ViewGameController.h"
#import "../command/game/DeleteGameCommand.h"
#import "../main/ApplicationDelegate.h"
#import "../ui/AutoLayoutUtility.h"
#import "../ui/PlaceholderView.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UIViewControllerAdditions.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Archive" table view.
// -----------------------------------------------------------------------------
enum ArchiveTableViewSection
{
  GamesSection,
  DeleteAllSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DeleteAllSection.
// -----------------------------------------------------------------------------
enum DeleteAllSectionItem
{
  DeleteAllItem,
  MaxDeleteAllSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ArchiveViewController.
// -----------------------------------------------------------------------------
@interface ArchiveViewController()
@property(nonatomic, retain) PlaceholderView* placeholderView;
@property(nonatomic, retain) UITableViewController* tableViewController;
@property(nonatomic, retain) NSArray* autoLayoutConstraints;
@end


@implementation ArchiveViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an ArchiveViewController object.
///
/// @note This is the designated initializer of ArchiveViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.placeholderView = nil;
  self.tableViewController = nil;
  self.autoLayoutConstraints = nil;
  self.archiveViewModel = [ApplicationDelegate sharedDelegate].archiveViewModel;
  [self.archiveViewModel addObserver:self forKeyPath:@"gameList" options:0 context:NULL];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ArchiveViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.placeholderView = nil;
  self.tableViewController = nil;
  self.autoLayoutConstraints = nil;
  [self.archiveViewModel removeObserver:self forKeyPath:@"gameList"];
  self.archiveViewModel = nil;

  [super dealloc];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setTableViewController:(UITableViewController*)tableViewController
{
  if (_tableViewController == tableViewController)
    return;
  if (_tableViewController)
  {
    [_tableViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_tableViewController removeFromParentViewController];
    [_tableViewController release];
    _tableViewController = nil;
  }
  if (tableViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:tableViewController];
    [tableViewController didMoveToParentViewController:self];
    [tableViewController retain];
    _tableViewController = tableViewController;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  // self.edgesForExtendedLayout is UIRectEdgeAll, therefore we have to provide
  // a background color that is visible behind the navigation bar at the top
  // (which on smaller iPhones extends behind the statusbar) and the tab bar
  // at the bottom. The background is only visible when the placeholder view
  // is shown.
  self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];

  [self updateVisibleStateOfEditButton];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
  [super setEditing:editing animated:animated];
  [self.tableViewController setEditing:editing animated:animated];
}

#pragma mark - View hierarchy handling

// -----------------------------------------------------------------------------
/// @brief Initial setup of the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  if (0 == self.archiveViewModel.gameCount)
    [self setupPlaceholderView];
  else
    [self setupTableView];
}

// -----------------------------------------------------------------------------
/// @brief Makes either the placeholder view or the table view visible. The
/// placeholder view is visible if there are no archived games to display.
// -----------------------------------------------------------------------------
- (void) updateViewHierarchy
{
  if (0 == self.archiveViewModel.gameCount)
  {
    if (self.placeholderView)
      return;

    [self.tableViewController.view removeFromSuperview];
    self.tableViewController = nil;
    self.autoLayoutConstraints = nil;

    [self setupViewHierarchy];
    [self setupAutoLayoutConstraints];
  }
  else
  {
    if (self.tableViewController)
      return;

    [self.placeholderView removeFromSuperview];
    self.placeholderView = nil;
    self.autoLayoutConstraints = nil;

    [self setupViewHierarchy];
    [self setupAutoLayoutConstraints];
  }
}


// -----------------------------------------------------------------------------
/// @brief Sets up the placeholder view and the static label inside.
// -----------------------------------------------------------------------------
- (void) setupPlaceholderView
{
  self.placeholderView = [[[PlaceholderView alloc] initWithFrame:CGRectZero placeholderText:@"No archived games."] autorelease];
  [self.view addSubview:self.placeholderView];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the table view.
// -----------------------------------------------------------------------------
- (void) setupTableView
{
  self.tableViewController = [[[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];

  UITableView* tableView = self.tableViewController.tableView;
  [self.view addSubview:tableView];

  tableView.delegate = self;
  tableView.dataSource = self;
}

#pragma mark - Auto Layout constraints

// -----------------------------------------------------------------------------
/// @brief Main method for setting up Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  if (self.placeholderView)
  {
    self.placeholderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.autoLayoutConstraints = [AutoLayoutUtility fillSuperview:self.view withSubview:self.placeholderView];
  }
  else
  {
    UIView* tableViewControllerView = self.tableViewController.view;
    tableViewControllerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.autoLayoutConstraints = [AutoLayoutUtility fillSuperview:self.view withSubview:tableViewControllerView];
  }
}

#pragma mark - Private helpers for managing view visibility

// -----------------------------------------------------------------------------
/// @brief Makes the edit button visible if the table view contains 1 or more
/// rows. Hides the edit button if the table views contains no rows.
// -----------------------------------------------------------------------------
- (void) updateVisibleStateOfEditButton
{
  // self.editButtonItem is a standard item provided by UIViewController, which
  // is linked to triggering the view's edit mode
  if (0 == self.archiveViewModel.gameCount)
    self.navigationItem.rightBarButtonItem = nil;
  else
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

// -----------------------------------------------------------------------------
/// @brief Updates the entire archive view after the last game was deleted
// -----------------------------------------------------------------------------
- (void) updateArchiveViewAfterLastGameWasDeleted
{
  [self updateViewHierarchy];
  [self updateVisibleStateOfEditButton];
  // "Delete All" button must go away, the simplest way to achieve this is to
  // reload all data
  [self.tableViewController.tableView reloadData];
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
    case GamesSection:
    {
      return self.archiveViewModel.gameCount;
    }
    case DeleteAllSection:
    {
      if (0 == self.archiveViewModel.gameCount)
        return 0;
      else
        return MaxDeleteAllSectionItem;
    }
    default:
    {
      assert(0);
      break;
    }
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = 0;
  switch (indexPath.section)
  {
    case GamesSection:
    {
      cell = [TableViewCellFactory cellWithType:SubtitleCellType tableView:tableView];
      // Cast is required because NSInteger and int differ in size in 64-bit.
      // Cast is safe because this app was not made to handle more than
      // pow(2, 31) files.
      ArchiveGame* game = [self.archiveViewModel gameAtIndex:(int)indexPath.row];
      cell.textLabel.text = game.name;
      cell.detailTextLabel.text = [@"Last saved: " stringByAppendingString:game.fileDate];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case DeleteAllSection:
    {
      cell = [TableViewCellFactory cellWithType:DeleteTextCellType tableView:tableView];
      cell.textLabel.text = @"Delete all entries";
      break;
    }
    default:
    {
      assert(0);
      @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
      break;
    }
  }
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (GamesSection != indexPath.section)
    return;

  assert(editingStyle == UITableViewCellEditingStyleDelete);
  if (editingStyle != UITableViewCellEditingStyleDelete)
  {
    DDLogError(@"%@: Unexpected editingStyle %d", self, (int)editingStyle);
    return;
  }

  // Cast is required because NSInteger and int differ in size in 64-bit.
  // Cast is safe because this app was not made to handle more than
  // pow(2, 31) files.
  ArchiveGame* game = [self.archiveViewModel gameAtIndex:(int)indexPath.row];
  DeleteGameCommand* command = [[[DeleteGameCommand alloc] initWithGame:game] autorelease];
  // Temporarily disable KVO observer mechanism so that no table view update
  // is triggered during command execution. Purpose: In a minute, we are going
  // to manipulate the table view ourselves so that a nice animation is shown.
  [self.archiveViewModel removeObserver:self forKeyPath:@"gameList"];
  bool success = [command submit];
  [self.archiveViewModel addObserver:self forKeyPath:@"gameList" options:0 context:NULL];
  // Animate item deletion. Requires that in the meantime we have not triggered
  // a reloadData().
  if (success)
  {
    if (0 == self.archiveViewModel.gameCount)
      [self updateArchiveViewAfterLastGameWasDeleted];
    else
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
  }
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  switch (indexPath.section)
  {
    case GamesSection:
    {
      // Cast is required because NSInteger and int differ in size in 64-bit.
      // Cast is safe because this app was not made to handle more than
      // pow(2, 31) files.
      [self viewGame:[self.archiveViewModel gameAtIndex:(int)indexPath.row]];
      break;
    }
    case DeleteAllSection:
    {
      [self deleteAllGames];
      break;
    }
    default:
    {
      assert(0);
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCellEditingStyle) tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
  switch (indexPath.section)
  {
    case DeleteAllSection:
      return UITableViewCellEditingStyleNone;
    default:
      return UITableViewCellEditingStyleDelete;
  }
}

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  [self updateViewHierarchy];
  [self updateVisibleStateOfEditButton];
  // "Delete All" button may need to be shown if game count goes from 0 to 1
  [self.tableViewController.tableView reloadData];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Displays ViewGameController to allow the user to view and/or change
/// archive game information.
// -----------------------------------------------------------------------------
- (void) viewGame:(ArchiveGame*)game
{
  ViewGameController* viewGameController = [[ViewGameController controllerWithGame:game model:self.archiveViewModel] retain];
  [self.navigationController pushViewController:viewGameController animated:YES];
  [viewGameController release];
}

// -----------------------------------------------------------------------------
/// @brief Initiates the process to delete all entries. First displays an alert
/// that asks the user to confirm that she really wants to do this.
// -----------------------------------------------------------------------------
- (void) deleteAllGames
{
  void (^yesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    // Temporarily disable KVO observer mechanism so that no table view update
    // is triggered while we are deleting. When we are finished we will reload
    // all data.
    [self.archiveViewModel removeObserver:self forKeyPath:@"gameList"];
    while (self.archiveViewModel.gameCount > 0)
    {
      ArchiveGame* game = [self.archiveViewModel gameAtIndex:0];
      [[[[DeleteGameCommand alloc] initWithGame:game] autorelease] submit];
    }
    [self.archiveViewModel addObserver:self forKeyPath:@"gameList" options:0 context:NULL];
    [self updateArchiveViewAfterLastGameWasDeleted];
  };

  [self presentYesNoAlertWithTitle:@"Please confirm"
                           message:@"Are you sure you want to delete the entire archive?"
                        yesHandler:yesActionBlock
                         noHandler:nil];
}

@end
