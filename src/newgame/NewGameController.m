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
#import "NewGameController.h"
#import "NewGameModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"
#import "../utility/NSStringAdditions.h"
#import "../utility/UIColorAdditions.h"
#import "../go/GoGame.h"
#import "../go/GoBoard.h"
#import "../go/GoUtilities.h"
#import "../main/ApplicationDelegate.h"
#import "../player/PlayerModel.h"
#import "../player/Player.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "New Game" table view.
// -----------------------------------------------------------------------------
enum NewGameTableViewSection
{
  PlayersSection,
  MaxSectionLoadGame,
  // Sections from here on are not displayed in "load game" mode
  BoardSizeSection = MaxSectionLoadGame,
  HandicapSection,
  KomiSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the BoardSizeSection.
// -----------------------------------------------------------------------------
enum BoardSizeSectionItem
{
  BoardSizeItem,
  MaxBoardSizeSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayersSection.
// -----------------------------------------------------------------------------
enum PlayersSectionItem
{
  BlackPlayerItem,
  WhitePlayerItem,
  MaxPlayersSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the HandicapSection.
// -----------------------------------------------------------------------------
enum HandicapSectionItem
{
  HandicapItem,
  MaxHandicapSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the KomiSection.
// -----------------------------------------------------------------------------
enum KomiSectionItem
{
  KomiItem,
  MaxKomiSectionItem
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
/// @name ItemPickerDelegate protocol
//@{
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection;
//@}
/// @name HandicapSelectionDelegate protocol
//@{
- (void) handicapSelectionController:(HandicapSelectionController*)controller didMakeSelection:(bool)didMakeSelection;
//@}
/// @name KomiSelectionDelegate protocol
//@{
- (void) komiSelectionController:(KomiSelectionController*)controller didMakeSelection:(bool)didMakeSelection;
//@}
/// @name UIAlertViewDelegate protocol
//@{
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
//@}
/// @name Helpers
//@{
- (void) updateCell:(UITableViewCell*)cell withPlayer:(Player*)player;
- (bool) isSelectionValid;
- (void) newGame;
//@}
@end


@implementation NewGameController

@synthesize delegate;
@synthesize boardSize;
@synthesize blackPlayer;
@synthesize whitePlayer;
@synthesize loadGame;
@synthesize handicap;
@synthesize komi;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a NewGameController instance of
/// grouped style.
///
/// @a loadGame is true to indicate that the intent of starting the new game is
/// to load an archived game. @a loadGame is false to indicate that the new game
/// should be started in the regular fashion. The two modes display different
/// UI elements and trigger different operations when the user finally confirms
/// starting the new game.
// -----------------------------------------------------------------------------
+ (NewGameController*) controllerWithDelegate:(id<NewGameDelegate>)delegate loadGame:(bool)loadGame
{
  NewGameController* controller = [[NewGameController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.loadGame = loadGame;
    NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;
    PlayerModel* playerModel = [ApplicationDelegate sharedDelegate].playerModel;
    controller.boardSize = newGameModel.boardSize;
    controller.blackPlayer = [playerModel playerWithUUID:newGameModel.blackPlayerUUID];
    controller.whitePlayer = [playerModel playerWithUUID:newGameModel.whitePlayerUUID];
    controller.handicap = newGameModel.handicap;
    controller.komi = newGameModel.komi;
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
  if (! self.loadGame)
    self.navigationItem.title = @"New Game";
  else
    self.navigationItem.title = @"Load Game";
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
/// @brief Called by UIKit at various times to determine whether this controller
/// supports the given orientation @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has decided to start a new game.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  GoGame* game = [GoGame sharedGame];
  switch (game.state)
  {
    case GoGameStateGameHasStarted:
    case GoGameStateGameIsPaused:
    {
      UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"New game"
                                                      message:@"Are you sure you want to start a new game and discard the game in progress?"
                                                     delegate:self
                                            cancelButtonTitle:@"No"
                                            otherButtonTitles:@"Yes", nil];
      alert.tag = AlertViewTypeNewGame;
      [alert show];
      break;
    }
    default:
    {
      [self newGame];
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has decided not to start a new game.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  [self.delegate newGameController:self didStartNewGame:false];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  if (! self.loadGame)
    return MaxSection;
  else
    return MaxSectionLoadGame;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case BoardSizeSection:
      return MaxBoardSizeSectionItem;
    case PlayersSection:
      return MaxPlayersSectionItem;
    case HandicapSection:
      return MaxHandicapSectionItem;
    case KomiSection:
      return MaxKomiSectionItem;
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
  if (PlayersSection == section)
  {
    if ([self.blackPlayer isHuman] && [self.whitePlayer isHuman])
      return @"None of the players is a computer player. The default profile will be active during the game. See \"Settings > Players & Profiles\".";
    else if (! [self.blackPlayer isHuman] && ! [self.whitePlayer isHuman])
      return @"Both players are computer players. The black player's profile will be active during the game. See \"Settings > Players & Profiles\".";
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  switch (indexPath.section)
  {
    case BoardSizeSection:
      switch (indexPath.row)
      {
        case BoardSizeItem:
          cell.textLabel.text = @"Board size";
          cell.detailTextLabel.text = [GoBoard stringForSize:self.boardSize];
          break;
        default:
          assert(0);
          break;
      }
      break;
    case PlayersSection:
      {
        switch (indexPath.row)
        {
          case BlackPlayerItem:
            cell.textLabel.text = @"Black";
            [self updateCell:cell withPlayer:self.blackPlayer];
            break;
          case WhitePlayerItem:
            cell.textLabel.text = @"White";
            [self updateCell:cell withPlayer:self.whitePlayer];
            break;
          default:
            assert(0);
            break;
        }
        break;
      }
    case HandicapSection:
      switch (indexPath.row)
      {
        case HandicapItem:
          cell.textLabel.text = @"Handicap";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.handicap];
        default:
          assert(0);
          break;
      }
      break;
    case KomiSection:
      switch (indexPath.row)
      {
        case KomiItem:
          cell.textLabel.text = @"Komi";
          cell.detailTextLabel.text = [NSString stringWithKomi:self.komi];
        default:
          assert(0);
          break;
      }
      break;
    default:
      assert(0);
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
    {
      NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
      for (int boardSizeIndex = 0; boardSizeIndex < gNumberOfBoardSizes; ++boardSizeIndex)
      {
        int naturalBoardSize = GoBoardSizeMin + (boardSizeIndex * 2);
        [itemList addObject:[NSString stringWithFormat:@"%d", naturalBoardSize]];
      }
      int indexOfDefaultBoardSize = (self.boardSize - GoBoardSizeMin) / 2;
      ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                          title:@"Board size"
                                                                             indexOfDefaultItem:indexOfDefaultBoardSize
                                                                                       delegate:self];
      itemPickerController.context = indexPath;
      modalController = itemPickerController;
      break;
    }
    case PlayersSection:
    {
      PlayerModel* model = [ApplicationDelegate sharedDelegate].playerModel;
      Player* defaultPlayer;
      if (indexPath.row == BlackPlayerItem)
        defaultPlayer = self.blackPlayer;
      else
        defaultPlayer = self.whitePlayer;

      NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
      int indexOfDefaultPlayer = -1;
      for (int playerIndex = 0; playerIndex < model.playerCount; ++playerIndex)
      {
        Player* player = [model.playerList objectAtIndex:playerIndex];
        [itemList addObject:player.name];
        if (player == defaultPlayer)
          indexOfDefaultPlayer = playerIndex;
      }
      ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                          title:@"Select player"
                                                                             indexOfDefaultItem:indexOfDefaultPlayer
                                                                                       delegate:self];
      itemPickerController.context = indexPath;
      modalController = itemPickerController;
      break;
    }
    case HandicapSection:
    {
      int maximumHandicap = [GoUtilities maximumHandicapForBoardSize:self.boardSize];
      modalController = [HandicapSelectionController controllerWithDelegate:self
                                                            defaultHandicap:self.handicap
                                                            maximumHandicap:maximumHandicap];
      break;
    }
    case KomiSection:
    {
      modalController = [KomiSelectionController controllerWithDelegate:self
                                                            defaultKomi:self.komi];
      break;
    }
    default:
    {
      assert(0);
      return;
    }
  }
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:modalController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentModalViewController:navigationController animated:YES];
  [navigationController release];
}

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    NSIndexPath* indexPathContext = controller.context;
    if (BoardSizeSection == indexPathContext.section)
    {
      if (controller.indexOfDefaultItem != controller.indexOfSelectedItem)
      {
        self.boardSize = GoBoardSizeMin + (controller.indexOfSelectedItem * 2);
        NSRange indexSetRange = NSMakeRange(BoardSizeSection, 1);

        // Adjust handicap if the current handicap exceeds the maximum allowed
        // handicap for the new board size
        int maximumHandicap = [GoUtilities maximumHandicapForBoardSize:self.boardSize];
        if (self.handicap > maximumHandicap)
        {
          self.handicap = maximumHandicap;
          indexSetRange.length = HandicapSection - indexSetRange.location + 1;
        }

        self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
        NSIndexSet* indexSet = [NSIndexSet indexSetWithIndexesInRange:indexSetRange];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
      }
    }
    else if (PlayersSection == indexPathContext.section)
    {
      if (controller.indexOfDefaultItem != controller.indexOfSelectedItem)
      {
        PlayerModel* model = [ApplicationDelegate sharedDelegate].playerModel;
        Player* newPlayer = [[model playerList] objectAtIndex:controller.indexOfSelectedItem];
        if (BlackPlayerItem == indexPathContext.row)
          self.blackPlayer = newPlayer;
        else
          self.whitePlayer = newPlayer;
        self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
        NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:PlayersSection];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
      }
    }
  }
  [self dismissModalViewControllerAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief HandicapSelectionDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) handicapSelectionController:(HandicapSelectionController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (self.handicap != controller.handicap)
    {
      self.handicap = controller.handicap;
      self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
      NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:HandicapSection];
      [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
  }
  [self dismissModalViewControllerAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief KomiSelectionDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) komiSelectionController:(KomiSelectionController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (self.komi != controller.komi)
    {
      self.komi = controller.komi;
      self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
      NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:KomiSection];
      [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
  }
  [self dismissModalViewControllerAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Updates @a cell so that it represents @a player. Note that @a player
/// may be @e nil.
// -----------------------------------------------------------------------------
- (void) updateCell:(UITableViewCell*)cell withPlayer:(Player*)player
{
  if (player)
  {
    cell.detailTextLabel.text = player.name;
    cell.detailTextLabel.textColor = [UIColor slateBlueColor];
  }
  else
  {
    cell.detailTextLabel.text = @"No player selected";
    cell.detailTextLabel.textColor = [UIColor grayColor];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the currently selected settings are valid so that a
/// new game can be started.
// -----------------------------------------------------------------------------
- (bool) isSelectionValid
{
  return (self.blackPlayer != nil && self.whitePlayer != nil);
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user dismissing an alert view for which this controller
/// is the delegate.
// -----------------------------------------------------------------------------
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex)
  {
    case AlertViewButtonTypeNo:
      break;
    case AlertViewButtonTypeYes:
      [self newGame];
      break;
    default:
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished selecting parameters for a new
/// game. Makes the collected information persistent, then informs the delegate
/// that a new game needs to be started.
// -----------------------------------------------------------------------------
- (void) newGame
{
  // Store the collected information in NewGameModel before informing the
  // delegate
  NewGameModel* model = [ApplicationDelegate sharedDelegate].theNewGameModel;
  assert(model);
  model.boardSize = self.boardSize;
  model.blackPlayerUUID = self.blackPlayer.uuid;
  model.whitePlayerUUID = self.whitePlayer.uuid;
  // If an archived game is loaded, handicap and komi are taken from the
  // archive; since the user did not make selections for those parameters, they
  // cannot be persisted.
  if (! self.loadGame)
  {
    model.handicap = self.handicap;
    model.komi = self.komi;
  }

  [self.delegate newGameController:self didStartNewGame:true];
}

@end
