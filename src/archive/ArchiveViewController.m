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
#import "ArchiveViewController.h"
#import "ArchiveViewModel.h"
#import "ArchiveGame.h"
#import "ViewGameController.h"
#import "../main/ApplicationDelegate.h"
#import "../ui/AutoLayoutUtility.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"
#import "../command/game/DeleteGameCommand.h"


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
@property(nonatomic, retain) UIView* placeholderView;
@property(nonatomic, retain) UILabel* placeholderLabel;
@property(nonatomic, retain) UITableView* tableView;
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
  self.placeholderLabel = nil;
  self.tableView = nil;
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
  self.placeholderLabel = nil;
  self.tableView = nil;
  [self.archiveViewModel removeObserver:self forKeyPath:@"gameList"];
  self.archiveViewModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self setupPlaceholderView];
  [self setupTableView];
  [self setupAutoLayoutConstraints];

  [self updateVisibleStateOfMainViews];
  [self updateVisibleStateOfEditButton];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
  [super setEditing:editing animated:animated];
  [self.tableView setEditing:editing animated:animated];
}

#pragma mark - Private helpers for view setup

// -----------------------------------------------------------------------------
/// @brief Sets up the placeholder view and the static label inside.
// -----------------------------------------------------------------------------
- (void) setupPlaceholderView
{
  self.placeholderView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.placeholderView];

  // The following font size factors have been experimentally determined, i.e.
  // what looks good to me on a simulator
  CGFloat fontSizeFactor;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    fontSizeFactor = 1.5;
  else
    fontSizeFactor = 2.0;

  self.placeholderLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  [self.placeholderView addSubview:self.placeholderLabel];
  self.placeholderLabel.text = @"No archived games.";
  self.placeholderLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] * fontSizeFactor];
  self.placeholderLabel.textAlignment = NSTextAlignmentCenter;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the table view.
// -----------------------------------------------------------------------------
- (void) setupTableView
{
  self.tableView = [UiUtilities createTableViewWithStyle:UITableViewStyleGrouped
                               withDelegateAndDataSource:self];
  [self.view addSubview:self.tableView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.edgesForExtendedLayout = UIRectEdgeNone;

  self.placeholderView.translatesAutoresizingMaskIntoConstraints = NO;
  self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.view withSubview:self.placeholderView];
  [AutoLayoutUtility centerSubview:self.placeholderLabel inSuperview:self.placeholderView];
  [AutoLayoutUtility fillSuperview:self.view withSubview:self.tableView];
}

#pragma mark - Private helpers for managing view visibility

// -----------------------------------------------------------------------------
/// @brief Makes either the placeholder view or the table view visible. The
/// placeholder view is visible if there are no archived games to display.
// -----------------------------------------------------------------------------
- (void) updateVisibleStateOfMainViews
{
  if (0 == self.archiveViewModel.gameCount)
  {
    self.placeholderView.hidden = NO;
    self.tableView.hidden = YES;
  }
  else
  {
    self.placeholderView.hidden = YES;
    self.tableView.hidden = NO;
  }
}

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
      ArchiveGame* game = [self.archiveViewModel gameAtIndex:indexPath.row];
      cell.textLabel.text = game.name;
      cell.detailTextLabel.text = [@"Last saved: " stringByAppendingString:game.fileDate];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case DeleteAllSection:
    {
      cell = [TableViewCellFactory cellWithType:DeleteTextCellType tableView:tableView];
      cell.textLabel.text = @"Delete all games";
      break;
    }
    default:
    {
      assert(0);
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
    DDLogError(@"%@: Unexpected editingStyle %d", self, editingStyle);
    return;
  }

  ArchiveGame* game = [self.archiveViewModel gameAtIndex:indexPath.row];
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
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
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
      [self viewGame:[self.archiveViewModel gameAtIndex:indexPath.row]];
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
  [self updateVisibleStateOfMainViews];
  [self updateVisibleStateOfEditButton];
  // Debugging note: Invocation of most of the UITableViewDataSource methods is
  // delayed until the table is displayed
  [self.tableView reloadData];
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
/// @brief Initiates the process to delete all games. First displays an alert
/// that asks the user to confirm that she really wants to do this.
// -----------------------------------------------------------------------------
- (void) deleteAllGames
{
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Please confirm"
                                                  message:@"Are you sure you want to delete all games?"
                                                 delegate:self
                                        cancelButtonTitle:@"No"
                                        otherButtonTitles:@"Yes", nil];
  alert.tag = AlertViewTypeDeleteAllGamesConfirmation;
  [alert show];
  [alert release];
}

#pragma mark - UIAlertViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UIAlertViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (AlertViewButtonTypeYes == buttonIndex)
  {
    // Temporarily disable KVO observer mechanism so that no table view update
    // is triggered while we are deleting games. When we are finished we will
    // reload all data.
    [self.archiveViewModel removeObserver:self forKeyPath:@"gameList"];
    while (self.archiveViewModel.gameCount > 0)
    {
      ArchiveGame* game = [self.archiveViewModel gameAtIndex:0];
      [[[[DeleteGameCommand alloc] initWithGame:game] autorelease] submit];
    }
    [self.archiveViewModel addObserver:self forKeyPath:@"gameList" options:0 context:NULL];
    [self updateVisibleStateOfMainViews];
    [self updateVisibleStateOfEditButton];
    [self.tableView reloadData];
  }
}

@end
