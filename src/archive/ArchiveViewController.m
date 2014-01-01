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
#import "ArchiveViewController.h"
#import "ArchiveViewModel.h"
#import "ArchiveGame.h"
#import "ViewGameController.h"
#import "../main/ApplicationDelegate.h"
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
@end


@implementation ArchiveViewController

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ArchiveViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self.archiveViewModel removeObserver:self forKeyPath:@"gameList"];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Creates the view that this controller manages.
///
/// This implementation exists because this controller needs a grouped style
/// table view, and there is no simpler way to specify the table view style.
/// - This controller does not load its table view from a .nib file, so the
///   style can't be specified there
/// - This controller is itself loaded from a .nib file, so the style can't be
///   specified in initWithStyle:()
// -----------------------------------------------------------------------------
- (void) loadView
{
  [UiUtilities createTableViewWithStyle:UITableViewStyleGrouped forController:self];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  self.archiveViewModel = delegate.archiveViewModel;

  [self setupPlaceholderView];

  // KVO observing
  [self.archiveViewModel addObserver:self forKeyPath:@"gameList" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];

  // Super's viewDidUnload does not release self.view/self.tableView for us,
  // possibly because we override loadView and create the view ourselves
  self.view = nil;
  self.tableView = nil;

  // Undo all of the stuff that is happening in viewDidLoad
  [self.archiveViewModel removeObserver:self forKeyPath:@"gameList"];
  self.archiveViewModel = nil;
  self.placeholderView = nil;
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
    case GamesSection:
    {
      [self updateVisibleStateOfPlaceholderView];
      [self updateVisibleStateOfEditButton];
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
      cell = [TableViewCellFactory cellWithType:RedButtonCellType tableView:tableView];
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

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  // Invocation of most of the UITableViewDataSource methods is delayed until
  // the table is displayed 
  [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the placeholder view and the static label inside.
// -----------------------------------------------------------------------------
- (void) setupPlaceholderView
{
  self.placeholderView = [[[UIView alloc] initWithFrame:self.tableView.frame] autorelease];
  [self.tableView addSubview:self.placeholderView];
  self.placeholderView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

  NSString* labelText = @"No archived games.";
  // The following font size factors have been experimentally determined, i.e.
  // what looks good to me on a simulator
  CGFloat fontSizeFactor;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    fontSizeFactor = 1.5;
  else
    fontSizeFactor = 2.0;
  UIFont* labelFont = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] * fontSizeFactor];
  CGSize constraintSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
  CGSize labelSize = [labelText sizeWithFont:labelFont
                           constrainedToSize:constraintSize
                               lineBreakMode:NSLineBreakByWordWrapping];
  CGRect labelFrame = CGRectNull;
  labelFrame.size = labelSize;
  // Horizontally center
  labelFrame.origin.x = (self.placeholderView.bounds.size.width - labelSize.width) / 2;
  // Vertically place label somewhere in the upper part of the view
  labelFrame.origin.y = (self.placeholderView.bounds.size.height / 4);
  UILabel* label = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
  [self.placeholderView addSubview:label];
  label.text = labelText;
  label.font = labelFont;
  label.textColor = [UIColor blackColor];
  label.backgroundColor = [UIColor clearColor];
  label.numberOfLines = 1;
  label.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
                            UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin);
}

// -----------------------------------------------------------------------------
/// @brief Makes the placeholder view visible if the table view does not contain
/// any rows. Hides the placeholder view if the table views contains 1 or more
/// rows.
// -----------------------------------------------------------------------------
- (void) updateVisibleStateOfPlaceholderView
{
  if (0 == self.archiveViewModel.gameCount)
    self.placeholderView.hidden = NO;
  else
    self.placeholderView.hidden = YES;
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
    [self.tableView reloadData];
  }
}

@end
