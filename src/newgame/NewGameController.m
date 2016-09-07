// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "NewGameAdvancedController.h"
#import "NewGameModel.h"
#import "../go/GoGame.h"
#import "../go/GoGameDocument.h"
#import "../go/GoGameRules.h"
#import "../go/GoBoard.h"
#import "../go/GoUtilities.h"
#import "../main/ApplicationDelegate.h"
#import "../player/PlayerModel.h"
#import "../player/Player.h"
#import "../shared/LayoutManager.h"
#import "../ui/AutoLayoutUtility.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "New Game" table view when
/// not in "load game" mode.
// -----------------------------------------------------------------------------
enum NewGameTableViewSection
{
  PlayersSection,
  BoardSizeSection,
  RulesetHandicapSection,
  AdvancedSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "New Game" table view when
/// in "load game" mode.
// -----------------------------------------------------------------------------
enum NewGameTableViewSection_LoadGame
{
  PlayersSection_LoadGame,
  RulesetHandicapSection_LoadGame,
  AdvancedSection_LoadGame,
  MaxSection_LoadGame
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
  // Items for game type human vs. computer
  HumanPlayerItem,
  ComputerPlayerItem,
  ComputerPlayerColorItem,
  MaxPlayersSectionItemHumanVsComputer,
  // Items for game type human vs. human
  BlackPlayerItem = 0,
  WhitePlayerItem,
  MaxPlayersSectionItemHumanVsHuman,
  // Items for game type computer vs. computer
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
/// @brief Enumerates items in the RulesetHandicapSection.
// -----------------------------------------------------------------------------
enum RulesetHandicapSectionItem
{
  RulesetItem,
  EvenGameItem,  // not shown in "load game" mode
  HandicapItem,  // not shown in "load game" mode; also not shown in "normal" mode if game is even
  MaxRulesetHandicapSectionItem_UnevenGame,
  MaxRulesetHandicapSectionItem_EvenGame = MaxRulesetHandicapSectionItem_UnevenGame - 1,
  MaxRulesetHandicapSectionItem_LoadGame = MaxRulesetHandicapSectionItem_UnevenGame - 2
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the AdvancedSection.
// -----------------------------------------------------------------------------
enum AdvancedSectionItem
{
  AdvancedItem,
  MaxAdvancedSectionItem,
  MaxAdvancedSectionItem_LoadGame = MaxAdvancedSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates all table view cells that can ever appear in the
/// "New Game" table view, without regard to the conditions under which they
/// appear.
///
/// This enumeration exists to simplify controller logic. Using this enumeration
/// allows to write a single switch() statement instead of writing complicated
/// complicated nested switch/if statements.
// -----------------------------------------------------------------------------
enum CellID
{
  HumanPlayerCellID,
  ComputerPlayerCellID,
  ComputerPlayerColorCellID,
  BlackPlayerCellID,
  WhitePlayerCellID,
  SingleComputerPlayerCellID,
  BoardSizeCellID,
  RulesetCellID,
  EvenGameCellID,
  HandicapCellID,
  AdvancedCellID
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NewGameController.
// -----------------------------------------------------------------------------
@interface NewGameController()
@property(nonatomic, assign) id<NewGameControllerDelegate> delegate;
@property(nonatomic, assign) bool loadGame;
@property(nonatomic, assign) NewGameModel* theNewGameModel;
@property(nonatomic, assign) PlayerModel* playerModel;
@property(nonatomic, assign) bool advancedScreenWasShown;
@property(nonatomic, assign) UITableView* tableView;
@property(nonatomic, assign) UISegmentedControl* segmentedControl;
@end


@implementation NewGameController

#pragma mark - Initialization and deallocation

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
+ (NewGameController*) controllerWithDelegate:(id<NewGameControllerDelegate>)delegate
                                     loadGame:(bool)loadGame
{
  NewGameController* controller = [[NewGameController alloc] initWithNibName:nil bundle:nil];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.loadGame = loadGame;
    NewGameModel* theNewGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;
    controller.theNewGameModel = theNewGameModel;
    PlayerModel* playerModel = [ApplicationDelegate sharedDelegate].playerModel;
    controller.playerModel = playerModel;
    controller.advancedScreenWasShown = false;

    // Try to find some sensible defaults if player objects could not be
    // determined (e.g. because the UUIDs we remembered are no longer valid).
    // The general approach here is to avoid guesses: A default is chosen only
    // if there is no other logical choice.
    NSArray* humanPlayerList = [playerModel playerListHuman:true];
    NSArray* computerPlayerList = [playerModel playerListHuman:false];
    if (! [playerModel playerWithUUID:theNewGameModel.humanPlayerUUID])
    {
      if (1 == humanPlayerList.count)
      {
        Player* player = [humanPlayerList objectAtIndex:0];
        theNewGameModel.humanPlayerUUID = player.uuid;
      }
    }
    if (! [playerModel playerWithUUID:theNewGameModel.computerPlayerUUID])
    {
      if (1 == computerPlayerList.count)
      {
        Player* player = [computerPlayerList objectAtIndex:0];
        theNewGameModel.computerPlayerUUID = player.uuid;
      }
    }
    if (! [playerModel playerWithUUID:theNewGameModel.humanBlackPlayerUUID])
    {
      if (humanPlayerList.count >= 1 && humanPlayerList.count <= 2)
      {
        Player* player = [humanPlayerList objectAtIndex:0];
        theNewGameModel.humanBlackPlayerUUID = player.uuid;
      }
    }
    if (! [playerModel playerWithUUID:theNewGameModel.humanWhitePlayerUUID])
    {
      if (2 == humanPlayerList.count)
      {
        Player* player = [humanPlayerList objectAtIndex:1];
        theNewGameModel.humanWhitePlayerUUID = player.uuid;
      }
    }
    if (! [playerModel playerWithUUID:theNewGameModel.computerPlayerSelfPlayUUID])
    {
      if (1 == computerPlayerList.count)
      {
        Player* player = [computerPlayerList objectAtIndex:0];
        theNewGameModel.computerPlayerSelfPlayUUID = player.uuid;
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
  self.theNewGameModel = nil;
  self.playerModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self createSubviews];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureViews];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if (self.advancedScreenWasShown)
  {
    // We get here if the "Advanced settings" screeen is popped from the
    // navigation stack
    NSUInteger indexOfSectionToReload;
    if (self.loadGame)
      indexOfSectionToReload = RulesetHandicapSection_LoadGame;
    else
      indexOfSectionToReload = RulesetHandicapSection;
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:indexOfSectionToReload];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    self.advancedScreenWasShown = false;
  }
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) createSubviews
{
  self.segmentedControl = [[[UISegmentedControl alloc] initWithItems:nil] autorelease];
  self.tableView = [[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.segmentedControl];
  [self.view addSubview:self.tableView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.edgesForExtendedLayout = UIRectEdgeNone;
  self.segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.segmentedControl, @"segmentedControl",
                                   self.tableView, @"tableView",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-[segmentedControl]-|",
                            @"H:|-0-[tableView]-0-|",
                            // We want the segmented control to be offset from
                            // the superview top edge. We can't use AutoLayout's
                            // default (i.e. visual format
                            // "V:|-[segmentedControl]") for this because
                            // starting with iOS 8 this default has become 0.
                            [NSString stringWithFormat:@"V:|-%f-[segmentedControl]-[tableView]-|", [UiElementMetrics verticalSpacingSuperview]],
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  [UiUtilities addGroupTableViewBackgroundToView:self.view];
  [self configureSegmentedControl];
  [self configureTableView];
  [self configureNavigationItem];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureSegmentedControl
{
  self.segmentedControl.tintColor = [UIColor blackColor];

  [self.segmentedControl insertSegmentWithImage:[UIImage imageNamed:humanVsComputerImageResource]
                                        atIndex:[NewGameController segmentIndexForGameType:GoGameTypeComputerVsHuman]
                                       animated:NO];
  [self.segmentedControl insertSegmentWithImage:[UIImage imageNamed:humanVsHumanImageResource]
                                        atIndex:[NewGameController segmentIndexForGameType:GoGameTypeHumanVsHuman]
                                       animated:NO];
  [self.segmentedControl insertSegmentWithImage:[UIImage imageNamed:computerVsComputerImageResource]
                                        atIndex:[NewGameController segmentIndexForGameType:GoGameTypeComputerVsComputer]
                                       animated:NO];
  self.segmentedControl.selectedSegmentIndex = [NewGameController segmentIndexForGameType:self.theNewGameModel.gameTypeLastSelected];
  [self.segmentedControl addTarget:self action:@selector(gameTypeChanged:) forControlEvents:UIControlEventValueChanged];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureTableView
{
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureNavigationItem
{
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancel:)] autorelease];
  if (! self.loadGame)
    self.navigationItem.title = @"New Game";
  else
    self.navigationItem.title = @"Load Game";
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(done:)] autorelease];
  self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has decided to start a new game.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  if ([GoGame sharedGame].document.isDirty)
  {
    NSString* message = @"The game in progress has unsaved changes that will "
                         "be lost if you proceed. Are you sure you want to "
                         "discard the game in progress?";

    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:self.navigationItem.title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"No"
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction* action) {}];
    [alertController addAction:noAction];

    void (^yesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
    {
      [self newGame];
    };
    UIAlertAction* yesAction = [UIAlertAction actionWithTitle:@"Yes"
                                                        style:UIAlertActionStyleDefault
                                                      handler:yesActionBlock];
    [alertController addAction:yesAction];

    [self presentViewController:alertController animated:YES completion:nil];
  }
  else
  {
    [self newGame];
  }
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has decided not to start a new game.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  [self.delegate newGameController:self didStartNewGame:false];
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  if (self.loadGame)
    return MaxSection_LoadGame;
  else
    return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  if (PlayersSection == section)
  {
    switch (self.theNewGameModel.gameTypeLastSelected)
    {
      case GoGameTypeComputerVsHuman:
        return MaxPlayersSectionItemHumanVsComputer;
      case GoGameTypeHumanVsHuman:
        return MaxPlayersSectionItemHumanVsHuman;
      case GoGameTypeComputerVsComputer:
        return MaxPlayersSectionItemComputerVsComputer;
      default:
      {
        NSString* errorMessage = [NSString stringWithFormat:@"Invalid game type: %d", self.theNewGameModel.gameTypeLastSelected];
        DDLogError(@"%@: %@", self, errorMessage);
        NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:errorMessage
                                                       userInfo:nil];
        @throw exception;
      }
    }
  }
  else
  {
    if (self.loadGame)
    {
      switch (section)
      {
        case RulesetHandicapSection_LoadGame:
          return MaxRulesetHandicapSectionItem_LoadGame;
        case AdvancedSection_LoadGame:
          return MaxAdvancedSectionItem_LoadGame;
        default:
          break;
      }
    }
    else
    {
      switch (section)
      {
        case BoardSizeSection:
          return MaxBoardSizeSectionItem;
        case RulesetHandicapSection:
          if ([self isEvenGame])
            return MaxRulesetHandicapSectionItem_EvenGame;
          else
            return MaxRulesetHandicapSectionItem_UnevenGame;
        case AdvancedSection:
          return MaxAdvancedSectionItem;
        default:
          break;
      }
    }
    assert(0);
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

#pragma mark - Private helper for tableView:cellForRowAtIndexPath:()

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UITableViewCell*) createCellForTableView:(UITableView*)tableView forRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell;
  enum CellID cellID = [self cellIDForIndexPath:indexPath];
  switch (cellID)
  {
    case HumanPlayerCellID:
    case ComputerPlayerCellID:
    case BlackPlayerCellID:
    case WhitePlayerCellID:
    case SingleComputerPlayerCellID:
    {
      // Use a non-standard cell identifier because cells with player names can
      // have a non-standard text color for the detail text label
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView reusableCellIdentifier:@"PlayerCell"];
      break;
    }
    case ComputerPlayerColorCellID:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      break;
    }
    case BoardSizeCellID:
    case RulesetCellID:
    case HandicapCellID:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      break;
    }
    case EvenGameCellID:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      break;
    }
    case AdvancedCellID:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
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
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (void) configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
  enum CellID cellID = [self cellIDForIndexPath:indexPath];
  switch (cellID)
  {
    case HumanPlayerCellID:
    {
      cell.textLabel.text = @"Human";
      [self updateCell:cell withPlayer:self.theNewGameModel.humanPlayerUUID];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case ComputerPlayerCellID:
    {
      cell.textLabel.text = @"Computer";
      [self updateCell:cell withPlayer:self.theNewGameModel.computerPlayerUUID];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case ComputerPlayerColorCellID:
    {
      cell.textLabel.text = @"Computer plays white";
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      accessoryView.on = self.theNewGameModel.computerPlaysWhite ? YES : NO;
      [accessoryView addTarget:self action:@selector(toggleComputerPlaysWhite:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case BlackPlayerCellID:
    {
      cell.textLabel.text = @"Black";
      [self updateCell:cell withPlayer:self.theNewGameModel.humanBlackPlayerUUID];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case WhitePlayerCellID:
    {
      cell.textLabel.text = @"White";
      [self updateCell:cell withPlayer:self.theNewGameModel.humanWhitePlayerUUID];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case SingleComputerPlayerCellID:
    {
      cell.textLabel.text = @"Computer";
      [self updateCell:cell withPlayer:self.theNewGameModel.computerPlayerSelfPlayUUID];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case BoardSizeCellID:
    {
      cell.textLabel.text = @"Board size";
      cell.detailTextLabel.text = [GoBoard stringForSize:self.theNewGameModel.boardSize];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case RulesetCellID:
    {
      cell.textLabel.text = @"Ruleset";
      cell.detailTextLabel.text = [NewGameController rulesetName:[self currentRuleset]];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case EvenGameCellID:
    {
      cell.textLabel.text = @"Even game";
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      accessoryView.on = [self isEvenGame];
      [accessoryView addTarget:self action:@selector(toggleEvenGame:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case HandicapCellID:
    {
      cell.textLabel.text = @"Handicap";
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.theNewGameModel.handicap];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case AdvancedCellID:
    {
      cell.textLabel.text = @"Advanced settings";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    default:
    {
      assert(0);
      break;
    }
  }
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  UIViewController* modalController;
  enum CellID cellID = [self cellIDForIndexPath:indexPath];
  switch (cellID)
  {
    case HumanPlayerCellID:
    case ComputerPlayerCellID:
    case BlackPlayerCellID:
    case WhitePlayerCellID:
    case SingleComputerPlayerCellID:
    case BoardSizeCellID:
    case RulesetCellID:
    {
      NSString* screenTitle;
      NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
      int indexOfDefaultItem = -1;
      if (BoardSizeCellID == cellID)
      {
        screenTitle = @"Select board size";
        for (int boardSizeIndex = 0; boardSizeIndex < gNumberOfBoardSizes; ++boardSizeIndex)
        {
          int naturalBoardSize = GoBoardSizeMin + (boardSizeIndex * 2);
          [itemList addObject:[NSString stringWithFormat:@"%d", naturalBoardSize]];
        }
        indexOfDefaultItem = (self.theNewGameModel.boardSize - GoBoardSizeMin) / 2;
      }
      else if (RulesetCellID == cellID)
      {
        screenTitle = @"Select ruleset";
        for (enum GoRuleset ruleset = GoRulesetMin; ruleset <= GoRulesetMax; ++ruleset)
          [itemList addObject:[NewGameController rulesetName:ruleset]];
        // No default selection if the current ruleset is a custom ruleset
        enum GoRuleset currentRuleset = [self currentRuleset];
        if (currentRuleset < itemList.count)
          indexOfDefaultItem = currentRuleset;
      }
      else
      {
        screenTitle = @"Select player";
        Player* defaultPlayer = [self playerForRowAtIndexPath:indexPath];
        bool pickHumanPlayer = [self shouldPickHumanPlayerForCellID:cellID];
        NSArray* playerList = [self.playerModel playerListHuman:pickHumanPlayer];
        for (int playerIndex = 0; playerIndex < playerList.count; ++playerIndex)
        {
          Player* player = [playerList objectAtIndex:playerIndex];
          [itemList addObject:player.name];
          if (player == defaultPlayer)
            indexOfDefaultItem = playerIndex;
        }
      }
      ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                    screenTitle:screenTitle
                                                                             indexOfDefaultItem:indexOfDefaultItem
                                                                                       delegate:self];
      itemPickerController.context = [NSNumber numberWithInt:cellID];
      modalController = itemPickerController;
      break;
    }
    case HandicapCellID:
    {
      int maximumHandicap = [GoUtilities maximumHandicapForBoardSize:self.theNewGameModel.boardSize];
      modalController = [HandicapSelectionController controllerWithDelegate:self
                                                            defaultHandicap:self.theNewGameModel.handicap
                                                            maximumHandicap:maximumHandicap];
      break;
    }
    case AdvancedCellID:
    {
      NewGameAdvancedController* newGameAdvancedController = [NewGameAdvancedController controllerWithGameType:self.theNewGameModel.gameTypeLastSelected
                                                                                                      loadGame:self.loadGame];
      [self.navigationController pushViewController:newGameAdvancedController animated:YES];
      self.advancedScreenWasShown = true;
      return;
    }
    default:
    {
      // Some cells (e.g. EvenGameCellID) don't react to selection
      return;
    }
  }

  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:modalController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  navigationController.delegate = [LayoutManager sharedManager];
  [self presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection && controller.indexOfDefaultItem != controller.indexOfSelectedItem)
  {
    NSNumber* cellIDAsNumber = controller.context;
    enum CellID cellID = [cellIDAsNumber intValue];
    switch (cellID)
    {
      case HumanPlayerCellID:
      case ComputerPlayerCellID:
      case BlackPlayerCellID:
      case WhitePlayerCellID:
      case SingleComputerPlayerCellID:
      {
        bool pickHumanPlayer = [self shouldPickHumanPlayerForCellID:cellID];
        NSArray* playerList = [self.playerModel playerListHuman:pickHumanPlayer];
        Player* newPlayer = [playerList objectAtIndex:controller.indexOfSelectedItem];
        [self updateWithNewPlayer:newPlayer forCellID:cellID];
        self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
        NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:PlayersSection];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
        break;
      }
      case BoardSizeCellID:
      {
        self.theNewGameModel.boardSize = GoBoardSizeMin + (controller.indexOfSelectedItem * 2);
        NSRange indexSetRange = NSMakeRange(BoardSizeSection, 1);

        // Adjust handicap if the current handicap exceeds the maximum allowed
        // handicap for the new board size
        int maximumHandicap = [GoUtilities maximumHandicapForBoardSize:self.theNewGameModel.boardSize];
        if (self.theNewGameModel.handicap > maximumHandicap)
        {
          self.theNewGameModel.handicap = maximumHandicap;
          indexSetRange.length = RulesetHandicapSection - indexSetRange.location + 1;
        }

        self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
        NSIndexSet* indexSet = [NSIndexSet indexSetWithIndexesInRange:indexSetRange];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
        break;
      }
      case RulesetCellID:
      {
        [self applyRuleset:controller.indexOfSelectedItem];
        NSUInteger indexOfSectionToReload;
        if (self.loadGame)
          indexOfSectionToReload = RulesetHandicapSection_LoadGame;
        else
          indexOfSectionToReload = RulesetHandicapSection;
        NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:indexOfSectionToReload];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
        break;
      }
      default:
      {
        NSString* errorMessage = [NSString stringWithFormat:@"Unexpected cell ID: %d", cellID];
        DDLogError(@"%@: %@", self, errorMessage);
        NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:errorMessage
                                                       userInfo:nil];
        @throw exception;
      }
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - HandicapSelectionDelegate overrides

// -----------------------------------------------------------------------------
/// @brief HandicapSelectionDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) handicapSelectionController:(HandicapSelectionController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (self.theNewGameModel.handicap != controller.handicap)
    {
      self.theNewGameModel.handicap = controller.handicap;
      [self autoAdjustKomi];
      self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
      NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:RulesetHandicapSection];
      [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the #CellID value that corresponds to @a indexPath, taking
/// into account the values  @e self.loadGame and the @e gameTypeLastSelected
/// property in NewGameModel.
// -----------------------------------------------------------------------------
- (enum CellID) cellIDForIndexPath:(NSIndexPath*)indexPath
{
  if (PlayersSection == indexPath.section)
  {
    switch (self.theNewGameModel.gameTypeLastSelected)
    {
      case GoGameTypeComputerVsHuman:
      {
        switch (indexPath.row)
        {
          case HumanPlayerItem:
            return HumanPlayerCellID;
          case ComputerPlayerItem:
            return ComputerPlayerCellID;
          case ComputerPlayerColorItem:
            return ComputerPlayerColorCellID;
          default:
            break;
        }
        break;
      }
      case GoGameTypeHumanVsHuman:
      {
        switch (indexPath.row)
        {
          case BlackPlayerItem:
            return BlackPlayerCellID;
          case WhitePlayerItem:
            return WhitePlayerCellID;
          default:
            break;
        }
        break;
      }
      case GoGameTypeComputerVsComputer:
      {
        switch (indexPath.row)
        {
          case SingleComputerPlayerItem:
            return SingleComputerPlayerCellID;
          default:
            break;
        }
        break;
      }
      default:
      {
        NSString* errorMessage = [NSString stringWithFormat:@"Invalid game type: %d", self.theNewGameModel.gameTypeLastSelected];
        DDLogError(@"%@: %@", self, errorMessage);
        NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:errorMessage
                                                       userInfo:nil];
        @throw exception;
      }
    }
  }
  else if (! self.loadGame && BoardSizeSection == indexPath.section)
  {
    return BoardSizeCellID;
  }
  else if ((self.loadGame && RulesetHandicapSection_LoadGame == indexPath.section) ||
           (! self.loadGame && RulesetHandicapSection == indexPath.section))
  {
    if (RulesetItem == indexPath.row)
    {
      return RulesetCellID;
    }
    else
    {
      if (self.loadGame)
      {
      }
      else
      {
        switch (indexPath.row)
        {
          case EvenGameItem:
            return EvenGameCellID;
          case HandicapItem:
            return HandicapCellID;
          default:
          {
            assert(0);
            break;
          }
        }
      }
    }
  }
  else if ((self.loadGame && AdvancedSection_LoadGame == indexPath.section) ||
           (! self.loadGame && AdvancedSection == indexPath.section))
  {
    return AdvancedCellID;
  }

  NSString* errorMessage = [NSString stringWithFormat:@"Cannot determine cell ID, loadGame = %d, indexPath.section = %ld, indexPath.row = %ld, game type: %d",
                            self.loadGame, (long)indexPath.section, (long)indexPath.row, self.theNewGameModel.gameTypeLastSelected];
  DDLogError(@"%@: %@", self, errorMessage);
  NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                   reason:errorMessage
                                                 userInfo:nil];
  @throw exception;
}

// -----------------------------------------------------------------------------
/// @brief Returns the object from the player property that corresponds to the
/// table view cell identified by @a indexPath.
///
/// This is a private helper for methods that handle the picking of a new
/// player.
///
/// This method requires that theNewGameModel.gameTypeLastSelected has the
/// correct value.
///
/// Raises an @e NSInvalidArgumentException if
/// theNewGameModel.gameTypeLastSelected is not recognized.
// -----------------------------------------------------------------------------
- (Player*) playerForRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSString* playerUUID;
  enum CellID cellID = [self cellIDForIndexPath:indexPath];
  switch (cellID)
  {
    case HumanPlayerCellID:
    {
      playerUUID = self.theNewGameModel.humanPlayerUUID;
      break;
    }
    case ComputerPlayerCellID:
    {
      playerUUID = self.theNewGameModel.computerPlayerUUID;
      break;
    }
    case BlackPlayerCellID:
    {
      playerUUID = self.theNewGameModel.humanBlackPlayerUUID;
      break;
    }
    case WhitePlayerCellID:
    {
      playerUUID = self.theNewGameModel.humanWhitePlayerUUID;
      break;
    }
    case SingleComputerPlayerCellID:
    {
      playerUUID = self.theNewGameModel.computerPlayerSelfPlayUUID;
      break;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Cell ID does not represent a player cell: %d", cellID];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
  return [self.playerModel playerWithUUID:playerUUID];
}

// -----------------------------------------------------------------------------
/// @brief Determine which player type to pick for table view cell identified
/// by @a indexPath.
///
/// This is a private helper for methods that handle the picking of a new
/// player.
///
/// This method requires that theNewGameModel.gameTypeLastSelected has the
/// correct value.
///
/// Raises an @e NSInvalidArgumentException if
/// theNewGameModel.gameTypeLastSelected is not recognized.
// -----------------------------------------------------------------------------
- (bool) shouldPickHumanPlayerForCellID:(enum CellID)cellID
{
  bool pickHumanPlayer = true;
  switch (cellID)
  {
    case HumanPlayerCellID:
    {
      pickHumanPlayer = true;
      break;
    }
    case ComputerPlayerCellID:
    {
      pickHumanPlayer = false;
      break;
    }
    case BlackPlayerCellID:
    case WhitePlayerCellID:
    {
      pickHumanPlayer = true;
      break;
    }
    case SingleComputerPlayerCellID:
    {
      pickHumanPlayer = false;
      break;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Cell ID does not represent a player cell: %d", cellID];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
  return pickHumanPlayer;
}

// -----------------------------------------------------------------------------
/// @brief Updates values in theNewGameModel that match the current game type
/// (theNewGameModel.gameTypeLastSelected).
///
/// This is a private helper for itemPickerController:didMakeSelection:(). It
/// is invoked after the new player object @a newPlayer has been selected for
/// the table view cell identified by @a indexPath.
///
/// This method requires that theNewGameModel.gameTypeLastSelected has the
/// correct value.
///
/// Raises an @e NSInvalidArgumentException if
/// theNewGameModel.gameTypeLastSelected is not recognized.
// -----------------------------------------------------------------------------
- (void) updateWithNewPlayer:(Player*)newPlayer forCellID:(enum CellID)cellID
{
  NSString* newPlayerUUID = newPlayer.uuid;
  switch (cellID)
  {
    case HumanPlayerCellID:
    {
      self.theNewGameModel.humanPlayerUUID = newPlayerUUID;
      break;
    }
    case ComputerPlayerCellID:
    {
      self.theNewGameModel.computerPlayerUUID = newPlayerUUID;
      break;
    }
    case BlackPlayerCellID:
    {
      self.theNewGameModel.humanBlackPlayerUUID = newPlayerUUID;
      break;
    }
    case WhitePlayerCellID:
    {
      self.theNewGameModel.humanWhitePlayerUUID = newPlayerUUID;
      break;
    }
    case SingleComputerPlayerCellID:
    {
      self.theNewGameModel.computerPlayerSelfPlayUUID = newPlayerUUID;
      break;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Cell ID does not represent a player cell: %d", cellID];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates @a cell with information for the player identified by
/// @a playerUUID.
///
/// If @a playerUUID is an empty string, or refers to a player that does not
/// exist, @a cell is updated with a string that indicates that no player is
/// selected.
// -----------------------------------------------------------------------------
- (void) updateCell:(UITableViewCell*)cell withPlayer:(NSString*)playerUUID
{
  Player* player = [self.playerModel playerWithUUID:playerUUID];
  if (player)
  {
    cell.detailTextLabel.text = player.name;
    cell.detailTextLabel.textColor = [UIColor grayColor];
  }
  else
  {
    cell.detailTextLabel.text = @"No player selected";
    cell.detailTextLabel.textColor = [UIColor redColor];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns whether or not the current "new game" settings denote an even
/// game. A game is considered "even" if uses no handicap.
// -----------------------------------------------------------------------------
- (bool) isEvenGame
{
  return (0 == self.theNewGameModel.handicap);
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the currently selected settings are valid so that a
/// new game can be started.
///
/// This method requires that theNewGameModel.gameTypeLastSelected has the
/// correct value.
///
/// Raises an @e NSInvalidArgumentException if
/// theNewGameModel.gameTypeLastSelected is not recognized.
// -----------------------------------------------------------------------------
- (bool) isSelectionValid
{
  // Don't need to check player types, the controller logic allows only valid
  // player types
  bool isSelectionValid = true;
  switch (self.theNewGameModel.gameTypeLastSelected)
  {
    case GoGameTypeComputerVsHuman:
    {
      if (! [self.playerModel playerWithUUID:self.theNewGameModel.humanPlayerUUID] ||
          ! [self.playerModel playerWithUUID:self.theNewGameModel.computerPlayerUUID])
      {
        isSelectionValid = false;
      }
      break;
    }
    case GoGameTypeHumanVsHuman:
    {
      if (! [self.playerModel playerWithUUID:self.theNewGameModel.humanBlackPlayerUUID] ||
          ! [self.playerModel playerWithUUID:self.theNewGameModel.humanWhitePlayerUUID])
      {
        isSelectionValid = false;
      }
      break;
    }
    case GoGameTypeComputerVsComputer:
    {
      if (! [self.playerModel playerWithUUID:self.theNewGameModel.computerPlayerSelfPlayUUID])
      {
        isSelectionValid = false;
      }
      break;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid game type: %d", self.theNewGameModel.gameTypeLastSelected];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
  return isSelectionValid;
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished selecting parameters for a new
/// game. Informs the delegate that a new game needs to be started.
// -----------------------------------------------------------------------------
- (void) newGame
{
  // When the new game is started, the game type is taken from the gameType
  // property, not from gameTypeLastSelected. We write the value for gameType
  // only at the last possible moment when we are certain that the user's
  // choices in the GUI are valid (only if they are valid is the "Done" button
  // enabled).
  self.theNewGameModel.gameType = self.theNewGameModel.gameTypeLastSelected;
  [self.delegate newGameController:self didStartNewGame:true];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Game Type" segmented control. Updates
/// the table view section that displays players.
// -----------------------------------------------------------------------------
- (void) gameTypeChanged:(id)sender
{
  UISegmentedControl* segmentedControl = (UISegmentedControl*)sender;
  self.theNewGameModel.gameTypeLastSelected = [NewGameController gameTypeForSegmentIndex:segmentedControl.selectedSegmentIndex];

  self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];

  NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:PlayersSection];
  [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Computer plays white" switch. Updates
/// internal data storage only, i.e. no GUI updates are necessary.
// -----------------------------------------------------------------------------
- (void) toggleComputerPlaysWhite:(id)sender
{
  self.theNewGameModel.computerPlaysWhite = (! self.theNewGameModel.computerPlaysWhite);
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Even game" switch.
// -----------------------------------------------------------------------------
- (void) toggleEvenGame:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  bool evenGame = (accessoryView.on == YES);
  if (evenGame)
    self.theNewGameModel.handicap = 0;
  else
    self.theNewGameModel.handicap = 2;
  [self autoAdjustKomi];

  NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:RulesetHandicapSection];
  [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}

// -----------------------------------------------------------------------------
/// @brief Adjusts komi depending on the combination of the current handicap
/// and scoring system.
// -----------------------------------------------------------------------------
- (void) autoAdjustKomi
{
  self.theNewGameModel.komi = [GoUtilities defaultKomiForHandicap:self.theNewGameModel.handicap
                                                    scoringSystem:self.theNewGameModel.scoringSystem];
}

// -----------------------------------------------------------------------------
/// @brief Returns the ruleset that best describes the current "new game"
/// settings. Returns #GoRulesetCustom if no ruleset fits.
// -----------------------------------------------------------------------------
- (enum GoRuleset) currentRuleset
{
  GoGameRules* rules = [[[GoGameRules alloc] init] autorelease];
  rules.koRule = self.theNewGameModel.koRule;
  rules.scoringSystem = self.theNewGameModel.scoringSystem;
  rules.lifeAndDeathSettlingRule = self.theNewGameModel.lifeAndDeathSettlingRule;
  rules.disputeResolutionRule = self.theNewGameModel.disputeResolutionRule;
  rules.fourPassesRule = self.theNewGameModel.fourPassesRule;
  return [GoUtilities rulesetForRules:rules];
}

// -----------------------------------------------------------------------------
/// @brief Modifies the "new game" settings so that they reflect the combination
/// of settings and rules for which @a ruleset is a shorthand.
// -----------------------------------------------------------------------------
- (void) applyRuleset:(enum GoRuleset)ruleset
{
  GoGameRules* rules = [GoUtilities rulesForRuleset:ruleset];
  self.theNewGameModel.koRule = rules.koRule;
  self.theNewGameModel.scoringSystem = rules.scoringSystem;
  self.theNewGameModel.lifeAndDeathSettlingRule = rules.lifeAndDeathSettlingRule;
  self.theNewGameModel.disputeResolutionRule = rules.disputeResolutionRule;
  self.theNewGameModel.fourPassesRule = rules.fourPassesRule;
  [self autoAdjustKomi];
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
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid game type: %d", gameType];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
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
+ (enum GoGameType) gameTypeForSegmentIndex:(NSInteger)segmentIndex
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
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid segment index: %ld", (long)segmentIndex];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a ruleset that is suitable for
/// displaying in the UI.
///
/// Raises an @e NSInvalidArgumentException if @a ruleset is not recognized.
// -----------------------------------------------------------------------------
+ (NSString*) rulesetName:(enum GoRuleset)ruleset
{
  switch (ruleset)
  {
    case GoRulesetAGA:
      return @"AGA";
    case GoRulesetIGS:
      return @"IGS (Pandanet)";
    case GoRulesetChinese:
      return @"Chinese";
    case GoRulesetJapanese:
      return @"Japanese";
    case GoRulesetLittleGo:
      return @"Little Go";
    case GoRulesetCustom:
      return @"Custom";
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid ruleset: %d", ruleset];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

@end
