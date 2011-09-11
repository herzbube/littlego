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
#import "ArchiveViewController.h"
#import "ArchiveViewModel.h"
#import "ArchiveGame.h"
#import "ViewGameController.h"
#import "../ApplicationDelegate.h"
#import "../ui/TableViewCellFactory.h"
#import "../command/DeleteGameCommand.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ArchiveViewController.
// -----------------------------------------------------------------------------
@interface ArchiveViewController()
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
- (void) tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Notification responders
//@{
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name Helpers
//@{
- (void) viewGame:(ArchiveGame*)game;
//@}
@end


@implementation ArchiveViewController

@synthesize archiveViewModel;


// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ArchiveViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self.archiveViewModel removeObserver:self forKeyPath:@"gameList"];
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
  self.archiveViewModel = delegate.archiveViewModel;
  // self.editButtonItem is a standard item provided by UIViewController, which
  // is linked to triggering the view's edit mode
  self.navigationItem.rightBarButtonItem = self.editButtonItem;

  // KVO observing
  [self.archiveViewModel addObserver:self forKeyPath:@"gameList" options:0 context:NULL];
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
  return self.archiveViewModel.gameCount;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:SubtitleCellType tableView:tableView];
  ArchiveGame* game = [self.archiveViewModel gameAtIndex:indexPath.row];
  cell.textLabel.text = game.fileName;
  cell.detailTextLabel.text = [@"Last saved: " stringByAppendingString:game.fileDate];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
  assert(editingStyle == UITableViewCellEditingStyleDelete);
  if (editingStyle != UITableViewCellEditingStyleDelete)
    return;

  DeleteGameCommand* command = [[DeleteGameCommand alloc] init];
  command.game = [self.archiveViewModel gameAtIndex:indexPath.row];
  // Temporarily disable KVO observer mechanism so that no table view update
  // is triggered during command execution. Purpose: In a minute, we are going
  // to manipulate the table view ourselves so that a nice animation is shown.
  [self.archiveViewModel removeObserver:self forKeyPath:@"gameList"];
  [command submit];
  [self.archiveViewModel addObserver:self forKeyPath:@"gameList" options:0 context:NULL];
  // Animate item deletion. Requires that in the meantime we have not triggered
  // a reloadData().
  [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  [self viewGame:[self.archiveViewModel gameAtIndex:indexPath.row]];
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
/// @brief Displays ViewGameController to allow the user to view and/or change
/// archive game information.
// -----------------------------------------------------------------------------
- (void) viewGame:(ArchiveGame*)game
{
  ViewGameController* viewGameController = [[ViewGameController controllerWithGame:game model:self.archiveViewModel] retain];
  [self.navigationController pushViewController:viewGameController animated:YES];
  [viewGameController release];
}

@end
