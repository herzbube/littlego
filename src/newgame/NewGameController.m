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
#import "NewGameController.h"
#import "NewGameModel.h"
#import "../go/GoGame.h"
#import "../go/GoBoard.h"
#import "../ApplicationDelegate.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "New Game" table view.
// -----------------------------------------------------------------------------
enum NewGameTableViewSection
{
  BoardSizeSection,
  PlayerSection,
  HandicapSection,
  KomiSection,
  MaxSection = KomiSection
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for NewGameController.
// -----------------------------------------------------------------------------
@interface NewGameController()
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
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name BoardSizeDelegate protocol
//@{
- (void) boardSizeController:(BoardSizeController*)controller didMakeSelection:(bool)didMakeSelection;
//@}
@end


@implementation NewGameController

@synthesize delegate;
@synthesize boardSize;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a NewGameController instance of
/// grouped style.
// -----------------------------------------------------------------------------
+ (NewGameController*) controllerWithDelegate:(id<NewGameDelegate>)delegate
{
  NewGameController* controller = [[NewGameController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    NewGameModel* model = [ApplicationDelegate sharedDelegate].newGameModel;
    assert(model);
    controller.boardSize = model.boardSize;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NewGameController object.
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
  self.navigationItem.title = @"New Game";
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
/// @brief Invoked when the user has finished selecting parameters for a new
/// game.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  NewGameModel* model = [ApplicationDelegate sharedDelegate].newGameModel;
  assert(model);
  model.boardSize = self.boardSize;

  [GoGame newGame];
  [self.delegate didStartNewGame:true];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has decided not to start a new game.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  [self.delegate didStartNewGame:false];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return 4;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case BoardSizeSection:
      return 1;
    case PlayerSection:
      return 2;
    case HandicapSection:
      return 1;
    case KomiSection:
      return 1;
    default:
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  static NSString* cellID = @"NewGameCell";
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID];
  if (cell == nil)
  {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                   reuseIdentifier:cellID] autorelease];
  }

  switch (indexPath.section)
  {
    case BoardSizeSection:
      cell.textLabel.text = @"Board size";
      cell.detailTextLabel.text = [GoBoard stringForSize:self.boardSize];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    case PlayerSection:
      switch (indexPath.row)
      {
        case 0:
          cell.textLabel.text = @"Black";
          cell.detailTextLabel.text = @"Human Player";
          break;
        case 1:
          cell.textLabel.text = @"White";
          cell.detailTextLabel.text = @"Computer Player";
          break;
        default:
          assert(0);
          break;
      }
      cell.accessoryType = UITableViewCellAccessoryNone;
      break;
    case HandicapSection:
      cell.textLabel.text = @"Handicap";
      cell.detailTextLabel.text = @"0";
      cell.accessoryType = UITableViewCellAccessoryNone;
      break;
    case KomiSection:
      cell.textLabel.text = @"Komi";
      cell.detailTextLabel.text = @"6½";
      cell.accessoryType = UITableViewCellAccessoryNone;
      break;
  }

  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  UIViewController* modalController;
  switch (indexPath.section)
  {
    case BoardSizeSection:
      modalController = [[BoardSizeController controllerWithDelegate:self
                                                    defaultBoardSize:self.boardSize] retain];
      break;
    case PlayerSection:
      return;
    case HandicapSection:
      return;
    case KomiSection:
      return;
  }
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:modalController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentModalViewController:navigationController animated:YES];
  [navigationController release];
  [modalController release];
}

// -----------------------------------------------------------------------------
/// @brief BoardSizeDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) boardSizeController:(BoardSizeController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (self.boardSize != controller.boardSize)
    {
      self.boardSize = controller.boardSize;
      NSIndexPath* boardSizeIndexPath = [NSIndexPath indexPathForRow:0 inSection:BoardSizeSection];
      UITableViewCell* boardSizeCell = [self.tableView cellForRowAtIndexPath:boardSizeIndexPath];
      boardSizeCell.detailTextLabel.text = [GoBoard stringForSize:self.boardSize];
    }
  }
  [self dismissModalViewControllerAnimated:YES];
}

@end
