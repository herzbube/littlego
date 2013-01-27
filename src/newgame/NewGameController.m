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
#import "../ui/TableViewSegmentedCell.h"
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
  GameTypeSection,
  PlayersSection,
  MaxSectionLoadGame,
  // Sections from here on are not displayed in "load game" mode
  BoardSizeSection = MaxSectionLoadGame,
  HandicapSection,
  KomiSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GameTypeSection.
// -----------------------------------------------------------------------------
enum GameTypeSectionItem
{
  GameTypeItem,
  MaxGameTypeSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayersSection.
///
/// This section contains different items depending on the game type, therefore
/// this enumeration contains different sets of values, one set for each game
/// type. Each set starts with value 0 and ends with a "max" item whose name
/// indicates the game type that the set belongs to.
// -----------------------------------------------------------------------------
enum PlayersSectionItem
{
  HumanPlayerItem,
  ComputerPlayerItem,
  ComputerPlayerColorItem,
  MaxPlayersSectionItemHumanVsComputer,
  BlackPlayerItem = 0,
  WhitePlayerItem,
  MaxPlayersSectionItemHumanVsHuman,
  SingleComputerPlayerItem = 0,
  MaxPlayersSectionItemComputerVsComputer
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
- (void) gameTypeChanged:(id)sender;
- (void) toggleComputerPlaysWhite:(id)sender;
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
- (UITableViewCell*) createCellForTableView:(UITableView*)tableView forRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath;
- (Player*) playerForRowAtIndexPath:(NSIndexPath*)indexPath;
- (bool) shouldPickHumanPlayerForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) updateWithNewPlayer:(Player*)newPlayer forRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) updateCell:(UITableViewCell*)cell withPlayer:(Player*)player;
- (bool) isSelectionValid;
- (void) newGame;
- (void) updatePropertiesToMatchNewGameType;
+ (int) segmentIndexForGameType:(enum GoGameType)gameType;
+ (enum GoGameType) gameTypeForSegmentIndex:(int)segmentIndex;
//@}
/// @name Private properties
//@{
@property(nonatomic, assign) enum GoGameType gameType;
@property(nonatomic, retain) Player* humanPlayer;
@property(nonatomic, retain) Player* computerPlayer;
@property(nonatomic, assign) bool computerPlaysWhite;
@property(nonatomic, retain) Player* humanPlayerBlack;
@property(nonatomic, retain) Player* humanPlayerWhite;
@property(nonatomic, retain) Player* computerPlayerSelfPlay;
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
@synthesize gameType;
@synthesize humanPlayer;
@synthesize computerPlayer;
@synthesize computerPlaysWhite;
@synthesize humanPlayerBlack;
@synthesize humanPlayerWhite;
@synthesize computerPlayerSelfPlay;


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

    // Determine game type
    if (nil == controller.blackPlayer || nil == controller.whitePlayer)
      controller.gameType = GoGameTypeComputerVsHuman;
    // From now on we are sure that player objects are not nil
    else if (controller.blackPlayer.human && controller.whitePlayer.human)
      controller.gameType = GoGameTypeHumanVsHuman;
    else if (! controller.blackPlayer.human && ! controller.whitePlayer.human)
      controller.gameType = GoGameTypeComputerVsComputer;
    else
      controller.gameType = GoGameTypeComputerVsHuman;

    // Fill player properties that match game type
    // For human vs. computer games: Determine which color the computer plays
    controller.humanPlayer = nil;
    controller.computerPlayer = nil;
    controller.computerPlaysWhite = true;
    controller.humanPlayerBlack = nil;
    controller.humanPlayerWhite = nil;
    controller.computerPlayerSelfPlay = nil;
    switch (controller.gameType)
    {
      case GoGameTypeComputerVsHuman:
      {
        if (nil != controller.blackPlayer)
        {
          if (controller.blackPlayer.human)
            controller.humanPlayer = controller.blackPlayer;
          else
          {
            controller.computerPlayer = controller.blackPlayer;
            controller.computerPlaysWhite = false;
          }
        }
        if (nil != controller.whitePlayer)
        {
          if (controller.whitePlayer.human)
          {
            controller.humanPlayer = controller.whitePlayer;
            controller.computerPlaysWhite = false;
          }
          else
            controller.computerPlayer = controller.whitePlayer;
        }
        break;
      }
      case GoGameTypeHumanVsHuman:
      {
        controller.humanPlayerBlack = controller.blackPlayer;
        controller.humanPlayerWhite = controller.whitePlayer;
        break;
      }
      case GoGameTypeComputerVsComputer:
      {
        controller.computerPlayerSelfPlay = controller.blackPlayer;
        break;
      }
      default:
      {
        NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:[NSString stringWithFormat:@"Invalid game type: %d", controller.gameType]
                                                       userInfo:nil];
        @throw exception;
      }
    }
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NewGameController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.blackPlayer = nil;
  self.whitePlayer = nil;
  self.humanPlayer = nil;
  self.computerPlayer = nil;
  self.humanPlayerBlack = nil;
  self.humanPlayerWhite = nil;
  self.computerPlayerSelfPlay = nil;
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
    case GameTypeSection:
      return MaxGameTypeSectionItem;
    case PlayersSection:
    {
      switch (self.gameType)
      {
        case GoGameTypeComputerVsHuman:
          return MaxPlayersSectionItemHumanVsComputer;
        case GoGameTypeHumanVsHuman:
          return MaxPlayersSectionItemHumanVsHuman;
        case GoGameTypeComputerVsComputer:
          return MaxPlayersSectionItemComputerVsComputer;
        default:
        {
          NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                           reason:[NSString stringWithFormat:@"Invalid game type: %d", self.gameType]
                                                         userInfo:nil];
          @throw exception;
        }
      }
    }
    case BoardSizeSection:
      return MaxBoardSizeSectionItem;
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
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [self createCellForTableView:tableView forRowAtIndexPath:indexPath];
  [self configureCell:cell forRowAtIndexPath:indexPath];
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UITableViewCell*) createCellForTableView:(UITableView*)tableView forRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell;
  if (indexPath.section == GameTypeSection)
  {
    cell = [TableViewCellFactory cellWithType:SegmentedCellType tableView:tableView];
  }
  else
  {
    if (PlayersSection == indexPath.section && GoGameTypeComputerVsHuman == self.gameType && ComputerPlayerColorItem == indexPath.row)
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
    }
    else
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
  }
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (void) configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
  switch (indexPath.section)
  {
    case GameTypeSection:
    {
      UISegmentedControl* segmentedControl = ((TableViewSegmentedCell*)cell).segmentedControl;
      [segmentedControl removeAllSegments];
      [segmentedControl insertSegmentWithImage:[UIImage imageNamed:humanVsComputerImageResource]
                                       atIndex:[NewGameController segmentIndexForGameType:GoGameTypeComputerVsHuman]
                                      animated:NO];
      [segmentedControl insertSegmentWithImage:[UIImage imageNamed:humanVsHumanImageResource]
                                       atIndex:[NewGameController segmentIndexForGameType:GoGameTypeHumanVsHuman]
                                      animated:NO];
      [segmentedControl insertSegmentWithImage:[UIImage imageNamed:computerVsComputerImageResource]
                                       atIndex:[NewGameController segmentIndexForGameType:GoGameTypeComputerVsComputer]
                                      animated:NO];
      segmentedControl.selectedSegmentIndex = [NewGameController segmentIndexForGameType:self.gameType];
      [segmentedControl addTarget:self action:@selector(gameTypeChanged:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case PlayersSection:
    {
      switch (self.gameType)
      {
        case GoGameTypeComputerVsHuman:
        {
          switch (indexPath.row)
          {
            case HumanPlayerItem:
              cell.textLabel.text = @"Human";
              [self updateCell:cell withPlayer:self.humanPlayer];
              break;
            case ComputerPlayerItem:
              cell.textLabel.text = @"Computer";
              [self updateCell:cell withPlayer:self.computerPlayer];
              break;
            case ComputerPlayerColorItem:
              cell.textLabel.text = @"Computer plays white";
              UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
              accessoryView.on = self.computerPlaysWhite ? YES : NO;
              [accessoryView addTarget:self action:@selector(toggleComputerPlaysWhite:) forControlEvents:UIControlEventValueChanged];
              break;
            default:
              assert(0);
              break;
          }
          break;
        }
        case GoGameTypeHumanVsHuman:
        {
          switch (indexPath.row)
          {
            case BlackPlayerItem:
              cell.textLabel.text = @"Black";
              [self updateCell:cell withPlayer:self.humanPlayerBlack];
              break;
            case WhitePlayerItem:
              cell.textLabel.text = @"White";
              [self updateCell:cell withPlayer:self.humanPlayerWhite];
              break;
            default:
              assert(0);
              break;
          }
          break;
        }
        case GoGameTypeComputerVsComputer:
        {
          switch (indexPath.row)
          {
            case SingleComputerPlayerItem:
              cell.textLabel.text = @"Computer";
              [self updateCell:cell withPlayer:self.computerPlayerSelfPlay];
              break;
            default:
              assert(0);
              break;
          }
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }
      break;
    }
    case BoardSizeSection:
    {
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
    }
    case HandicapSection:
    {
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
    }
    case KomiSection:
    {
      switch (indexPath.row)
      {
        case KomiItem:
          cell.textLabel.text = @"Komi";
          cell.detailTextLabel.text = [NSString stringWithKomi:self.komi numericZeroValue:false];
        default:
          assert(0);
          break;
      }
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
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  UIViewController* modalController;
  switch (indexPath.section)
  {
    case PlayersSection:
    {
      PlayerModel* model = [ApplicationDelegate sharedDelegate].playerModel;
      Player* defaultPlayer = [self playerForRowAtIndexPath:indexPath];
      bool pickHumanPlayer = [self shouldPickHumanPlayerForRowAtIndexPath:indexPath];
      NSArray* playerList = [model playerListHuman:pickHumanPlayer];
      NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
      int indexOfDefaultPlayer = -1;
      for (int playerIndex = 0; playerIndex < playerList.count; ++playerIndex)
      {
        Player* player = [playerList objectAtIndex:playerIndex];
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
  if (didMakeSelection && controller.indexOfDefaultItem != controller.indexOfSelectedItem)
  {
    NSIndexPath* indexPathContext = controller.context;
    if (PlayersSection == indexPathContext.section)
    {
      PlayerModel* model = [ApplicationDelegate sharedDelegate].playerModel;
      bool pickHumanPlayer = [self shouldPickHumanPlayerForRowAtIndexPath:indexPathContext];
      NSArray* playerList = [model playerListHuman:pickHumanPlayer];
      Player* newPlayer = [playerList objectAtIndex:controller.indexOfSelectedItem];
      [self updateWithNewPlayer:newPlayer forRowAtIndexPath:indexPathContext];
      self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
      NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:PlayersSection];
      [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (BoardSizeSection == indexPathContext.section)
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
/// @brief Returns the object from the player property that corresponds to the
/// table view cell identified by @a indexPath.
///
/// This is a private helper for methods that handle the picking of a new
/// player.
///
/// This method requires that self.gameType has the correct value.
///
/// Raises an @e NSInvalidArgumentException if self.gameType is not recognized.
// -----------------------------------------------------------------------------
- (Player*) playerForRowAtIndexPath:(NSIndexPath*)indexPath
{
  Player* player = nil;
  switch (self.gameType)
  {
    case GoGameTypeComputerVsHuman:
    {
      if (HumanPlayerItem == indexPath.row)
        player = self.humanPlayer;
      else
        player = self.computerPlayer;
      break;
    }
    case GoGameTypeHumanVsHuman:
    {
      if (BlackPlayerItem == indexPath.row)
        player = self.humanPlayerBlack;
      else
        player = self.humanPlayerWhite;
      break;
    }
    case GoGameTypeComputerVsComputer:
    {
      player = self.computerPlayerSelfPlay;
      break;
    }
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Invalid game type: %d", gameType]
                                                     userInfo:nil];
      @throw exception;
    }
  }
  return player;
}

// -----------------------------------------------------------------------------
/// @brief Determine which player type to pick for table view cell identified
/// by @a indexPath.
///
/// This is a private helper for methods that handle the picking of a new
/// player.
///
/// This method requires that self.gameType has the correct value.
///
/// Raises an @e NSInvalidArgumentException if self.gameType is not recognized.
// -----------------------------------------------------------------------------
- (bool) shouldPickHumanPlayerForRowAtIndexPath:(NSIndexPath*)indexPath
{
  bool pickHumanPlayer = true;
  switch (self.gameType)
  {
    case GoGameTypeComputerVsHuman:
    {
      if (HumanPlayerItem == indexPath.row)
        pickHumanPlayer = true;
      else
        pickHumanPlayer = false;
      break;
    }
    case GoGameTypeHumanVsHuman:
    {
      pickHumanPlayer = true;
      break;
    }
    case GoGameTypeComputerVsComputer:
    {
      pickHumanPlayer = false;
      break;
    }
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Invalid game type: %d", gameType]
                                                     userInfo:nil];
      @throw exception;
    }
  }
  return pickHumanPlayer;
}

// -----------------------------------------------------------------------------
/// @brief Updates self.blackPlayer, self.whitePlayer, and those player
/// properties that match the current game type (self.gameType).
///
/// This is a private helper for itemPickerController:didMakeSelection:(). It
/// is invoked after the new player object @a newPlayer has been selected for
/// the table view cell identified by @a indexPath.
///
/// This method requires that self.gameType and self.computerPlaysWhite have
/// correct values.
///
/// Raises an @e NSInvalidArgumentException if self.gameType is not recognized.
// -----------------------------------------------------------------------------
- (void) updateWithNewPlayer:(Player*)newPlayer forRowAtIndexPath:(NSIndexPath*)indexPath
{
  switch (self.gameType)
  {
    case GoGameTypeComputerVsHuman:
    {
      if (HumanPlayerItem == indexPath.row)
      {
        self.humanPlayer = newPlayer;
        if (self.computerPlaysWhite)
          self.blackPlayer = newPlayer;
        else
          self.whitePlayer = newPlayer;
      }
      else
      {
        self.computerPlayer = newPlayer;
        if (self.computerPlaysWhite)
          self.whitePlayer = newPlayer;
        else
          self.blackPlayer = newPlayer;
      }
      break;
    }
    case GoGameTypeHumanVsHuman:
    {
      if (BlackPlayerItem == indexPath.row)
      {
        self.humanPlayerBlack = newPlayer;
        self.blackPlayer = newPlayer;
      }
      else
      {
        self.humanPlayerWhite = newPlayer;
        self.whitePlayer = newPlayer;
      }
      break;
    }
    case GoGameTypeComputerVsComputer:
    {
      self.computerPlayerSelfPlay = newPlayer;
      self.blackPlayer = newPlayer;
      self.whitePlayer = newPlayer;
      break;
    }
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Invalid game type: %d", gameType]
                                                     userInfo:nil];
      @throw exception;
    }
  }
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
///
/// This method requires that self.gameType has the correct value.
///
/// Raises an @e NSInvalidArgumentException if self.gameType is not recognized.
// -----------------------------------------------------------------------------
- (bool) isSelectionValid
{
  // Don't need to check player types, the controller logic allows only valid
  // player types
  bool isSelectionValid = true;
  switch (self.gameType)
  {
    case GoGameTypeComputerVsHuman:
      if (nil == self.humanPlayer || nil == self.computerPlayer)
        isSelectionValid = false;
      break;
    case GoGameTypeHumanVsHuman:
      if (nil == self.humanPlayerBlack || nil == self.humanPlayerWhite)
        isSelectionValid = false;
      break;
    case GoGameTypeComputerVsComputer:
      if (nil == self.computerPlayerSelfPlay)
        isSelectionValid = false;
      break;
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Invalid game type: %d", gameType]
                                                     userInfo:nil];
      @throw exception;
    }
  }
  return isSelectionValid;
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

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Game Type" segmented control. Updates
/// the table view section that displays players.
// -----------------------------------------------------------------------------
- (void) gameTypeChanged:(id)sender
{
  UISegmentedControl* segmentedControl = (UISegmentedControl*)sender;
  self.gameType = [NewGameController gameTypeForSegmentIndex:segmentedControl.selectedSegmentIndex];

  [self updatePropertiesToMatchNewGameType];

  self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];

  NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:PlayersSection];
  [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}

// -----------------------------------------------------------------------------
/// @brief Updates self.blackPlayer and self.whitePlayer to match the newly
/// selected game type.
///
/// This is a private helper for gameTypeChanged:(). It is invoked after the
/// game type has been changed. It requires that self.gameType already has the
/// new updated value.
///
/// Raises an @e NSInvalidArgumentException if self.gameType is not recognized.
// -----------------------------------------------------------------------------
- (void) updatePropertiesToMatchNewGameType
{
  switch (self.gameType)
  {
    case GoGameTypeComputerVsHuman:
    {
      if (self.computerPlaysWhite)
      {
        self.blackPlayer = self.humanPlayer;
        self.whitePlayer = self.computerPlayer;
      }
      else
      {
        self.blackPlayer = self.computerPlayer;
        self.whitePlayer = self.humanPlayer;
      }
      break;
    }
    case GoGameTypeHumanVsHuman:
    {
      self.blackPlayer = self.humanPlayerBlack;
      self.whitePlayer = self.humanPlayerWhite;
      break;
    }
    case GoGameTypeComputerVsComputer:
    {
      self.blackPlayer = self.computerPlayerSelfPlay;
      self.whitePlayer = self.computerPlayerSelfPlay;
      break;
    }
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Invalid game type: %d", gameType]
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Computer plays white" switch. Updates
/// internal data storage only, i.e. no GUI updates are necessary.
// -----------------------------------------------------------------------------
- (void) toggleComputerPlaysWhite:(id)sender
{
  self.computerPlaysWhite = (! self.computerPlaysWhite);
  // Simply switch players, we don't even need to check the player types
  Player* newBlackPlayer = self.whitePlayer;
  Player* newWhitePlayer = self.blackPlayer;
  self.blackPlayer = newBlackPlayer;
  self.whitePlayer = newWhitePlayer;
}

// -----------------------------------------------------------------------------
/// @brief Returns the index of the segment in the segmented control that
/// matches the game type @a gameType.
///
/// Raises an @e NSInvalidArgumentException if @a gameType is not recognized.
// -----------------------------------------------------------------------------
+ (int) segmentIndexForGameType:(enum GoGameType)gameType
{
  switch (gameType)
  {
    case GoGameTypeComputerVsHuman:
      return 0;
    case GoGameTypeHumanVsHuman:
      return 1;
    case GoGameTypeComputerVsComputer:
      return 2;
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Invalid game type: %d", gameType]
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the game type that matches the segment in the segmented
/// control that is identified by @a segmentIndex.
///
/// Raises an @e NSInvalidArgumentException if @a segmentIndex is not
/// recognized.
// -----------------------------------------------------------------------------
+ (enum GoGameType) gameTypeForSegmentIndex:(int)segmentIndex
{
  switch (segmentIndex)
  {
    case 0:
      return GoGameTypeComputerVsHuman;
    case 1:
      return GoGameTypeHumanVsHuman;
    case 2:
      return GoGameTypeComputerVsComputer;
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Invalid segment index: %d", segmentIndex]
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

@end
