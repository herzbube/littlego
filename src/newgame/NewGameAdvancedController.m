// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "NewGameAdvancedController.h"
#import "NewGameModel.h"
#import "../go/GoUtilities.h"
#import "../main/ApplicationDelegate.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewVariableHeightCell.h"
#import "../utility/NSStringAdditions.h"

// Constants
NSString* disputeResolutionRuleText = @"Dispute resolution";


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the table view that makes up the
/// "New game > Advanced settings" subscreen.
// -----------------------------------------------------------------------------
enum NewGameTableViewSection
{
  KomiSection,
  KoRuleScoringSystemSection,
  LifeAndDeathSettlingRuleSection,
  DisputeResolutionRuleSection,
  FourPassesRuleSection,
  MaxSection,
  MaxSection_ComputerVsComputerGame = LifeAndDeathSettlingRuleSection + 1,
  MaxSection_LifeAndDeathSettlingRuleThreePasses = DisputeResolutionRuleSection + 1
};

// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the table view that makes up the
/// "New game > Advanced settings" subscreen, when in "load game" mode.
// -----------------------------------------------------------------------------
enum NewGameTableViewSection_LoadGame
{
  KoRuleScoringSystemSection_LoadGame,
  LifeAndDeathSettlingRuleSection_LoadGame,
  DisputeResolutionRuleSection_LoadGame,
  FourPassesRuleSection_LoadGame,
  MaxSection_LoadGame,
  MaxSection_ComputerVsComputerGame_LoadGame = KoRuleScoringSystemSection_LoadGame + 1,
  MaxSection_LifeAndDeathSettlingRuleThreePasses_LoadGame = DisputeResolutionRuleSection_LoadGame + 1
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
/// @brief Enumerates items in the KoRuleScoringSystemSection.
// -----------------------------------------------------------------------------
enum KoRuleScoringSystemSectionItem
{
  KoRuleItem,
  ScoringSystemItem,
  MaxKoRuleScoringSystemSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the LifeAndDeathSettlingRuleSection.
// -----------------------------------------------------------------------------
enum LifeAndDeathSettlingRuleSectionItem
{
  LifeAndDeathSettlingRuleItem,
  MaxLifeAndDeathSettlingRuleSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DisputeResolutionRuleSection.
// -----------------------------------------------------------------------------
enum DisputeResolutionRuleSectionItem
{
  DisputeResolutionRuleItem,
  MaxDisputeResolutionRuleSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the FourPassesRuleSection.
// -----------------------------------------------------------------------------
enum FourPassesRuleSectionItem
{
  FourPassesRuleItem,
  MaxFourPassesRuleSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates all table view sections that can ever appear in the
/// "Advanced new game settings" table view, without regard to the conditions
/// under which they appear.
///
/// This enumeration exists to simplify controller logic. Using this enumeration
/// allows to write a single switch() statement instead of writing complicated
/// complicated nested switch/if statements.
// -----------------------------------------------------------------------------
enum SectionID
{
  KomiSectionID,
  KoRuleScoringSystemSectionID,
  LifeAndDeathSettlingRuleSectionID,
  DisputeResolutionRuleSectionID,
  FourPassesRuleSectionID,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates all table view cells that can ever appear in the
/// "Advanced new game settings" table view, without regard to the conditions
/// under which they appear.
///
/// This enumeration exists to simplify controller logic. Using this enumeration
/// allows to write a single switch() statement instead of writing complicated
/// complicated nested switch/if statements.
// -----------------------------------------------------------------------------
enum CellID
{
  KomiCellID,
  KoRuleCellID,
  ScoringSystemCellID,
  LifeAndDeathSettlingRuleCellID,
  DisputeResolutionRuleCellID,
  FourPassesRuleCellID,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// NewGameAdvancedController.
// -----------------------------------------------------------------------------
@interface NewGameAdvancedController()
@property(nonatomic, assign) bool loadGame;
@property(nonatomic, assign) enum GoGameType gameType;
@property(nonatomic, assign) NewGameModel* theNewGameModel;
@end


@implementation NewGameAdvancedController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a NewGameAdvancedController instance
/// of grouped style.
///
/// @a loadGame is true to indicate that the intent of starting the new game is
/// to load an archived game. @a loadGame is false to indicate that the new game
/// should be started in the regular fashion. The two modes display different
/// UI elements.
// -----------------------------------------------------------------------------
+ (NewGameAdvancedController*) controllerWithGameType:(enum GoGameType)gameType
                                             loadGame:(bool)loadGame
{
  NewGameAdvancedController* controller = [[NewGameAdvancedController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.loadGame = loadGame;
    controller.gameType = gameType;
    controller.theNewGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NewGameAdvancedController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.theNewGameModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Advanced settings";
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  if (self.gameType == GoGameTypeComputerVsComputer)
  {
    if (self.loadGame)
      return MaxSection_ComputerVsComputerGame_LoadGame;
    else
      return MaxSection_ComputerVsComputerGame;
  }
  else if (GoLifeAndDeathSettlingRuleThreePasses == self.theNewGameModel.lifeAndDeathSettlingRule)
  {
    if (self.loadGame)
      return MaxSection_LifeAndDeathSettlingRuleThreePasses_LoadGame;
    else
      return MaxSection_LifeAndDeathSettlingRuleThreePasses;
  }
  else
  {
    if (self.loadGame)
      return MaxSection_LoadGame;
    else
      return MaxSection;
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  enum SectionID sectionID = [self sectionIDForSection:section];
  switch (sectionID)
  {
    case KomiSectionID:
      return MaxKomiSectionItem;
    case KoRuleScoringSystemSectionID:
      return MaxKoRuleScoringSystemSectionItem;
    case LifeAndDeathSettlingRuleSectionID:
      if (self.gameType == GoGameTypeComputerVsComputer)
        return 0;  // we only want to show a footer
      else
        return MaxLifeAndDeathSettlingRuleSectionItem;
    case DisputeResolutionRuleSectionID:
      return MaxDisputeResolutionRuleSectionItem;
    case FourPassesRuleSectionID:
      return MaxFourPassesRuleSectionItem;
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
  enum SectionID sectionID = [self sectionIDForSection:section];
  switch (sectionID)
  {
    case LifeAndDeathSettlingRuleSectionID:
    {
      if (self.gameType == GoGameTypeComputerVsComputer)
        return (@"Here you would normally be able to select life & death "
                "settling rules. In a computer vs. computer game these rules "
                "are not available, though, because they only make sense for "
                "human players.");
      else
        return (@"Select the number of pass moves after which normal play should "
                "end and the game should enter the life & death settling phase. "
                "If you select '2 passes', play can be resumed to settle "
                "life & death disputes without discarding any moves. If you "
                "select '3 passes', the third pass move must be discarded in "
                "order to resume play. The latter option is used to implement "
                "the IGS ruleset.");
    }
    case DisputeResolutionRuleSectionID:
    {
      return (@"If in the life & death settling phase, players cannot agree on "
              "which stones are dead and which stones are alive, players must "
              "resume play to resolve the dispute. The option selected here "
              "decides who plays first: If you select 'Alternating play', the "
              "player who plays first is the opponent of the last player to "
              "pass. If you select 'Non-alternating play', either player is "
              "allowed to play first.");
    }
    case FourPassesRuleSectionID:
    {
      return (@"If players resume play in order to resolve a life & death "
              "dispute, but neither player wants to play and both players pass "
              "a second time, the result are 4 consecutive pass moves. The "
              "option selected here decides what this should mean: Either the "
              "4 consecutive pass moves have no special meaning, or the game "
              "ends immediately after the fourth pass move, with all stones on "
              "the board deemed ALIVE ! The latter option is used to implement "
              "the AGA ruleset.");
    }
    default:
    {
      break;
    }
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  enum CellID cellID = [self cellIDForIndexPath:indexPath];
  UITableViewCell* cell;
  if (DisputeResolutionRuleCellID == cellID)
  {
    cell = [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
    if (GoLifeAndDeathSettlingRuleThreePasses == self.theNewGameModel.lifeAndDeathSettlingRule)
      cell.accessoryType = UITableViewCellAccessoryNone;
    else
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  else
  {
    cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }

  switch (cellID)
  {
    case KomiCellID:
    {
      cell.textLabel.text = @"Komi";
      cell.detailTextLabel.text = [NSString stringWithKomi:self.theNewGameModel.komi numericZeroValue:false];
      break;
    }
    case KoRuleCellID:
    {
      cell.textLabel.text = @"Ko rule";
      cell.detailTextLabel.text = [NSString stringWithKoRule:self.theNewGameModel.koRule];
      break;
    }
    case ScoringSystemCellID:
    {
      cell.textLabel.text = @"Scoring system";
      cell.detailTextLabel.text = [NSString stringWithScoringSystem:self.theNewGameModel.scoringSystem];
      break;
    }
    case LifeAndDeathSettlingRuleCellID:
    {
      cell.textLabel.text = @"Life & death settling after";
      cell.detailTextLabel.text = [NewGameAdvancedController lifeAndDeathSettlingRuleName:self.theNewGameModel.lifeAndDeathSettlingRule];
      break;
    }
    case DisputeResolutionRuleCellID:
    {
      TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;
      variableHeightCell.descriptionLabel.text = disputeResolutionRuleText;
      variableHeightCell.valueLabel.text = [NewGameAdvancedController disputeResolutionRuleName:self.theNewGameModel.disputeResolutionRule];
      break;
    }
    case FourPassesRuleCellID:
    {
      cell.textLabel.text = @"Four passes";
      cell.detailTextLabel.text = [NewGameAdvancedController fourPassesRuleName:self.theNewGameModel.fourPassesRule];
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

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  enum CellID cellID = [self cellIDForIndexPath:indexPath];
  if (DisputeResolutionRuleCellID == cellID)
  {
    NSString* valueText = [NewGameAdvancedController disputeResolutionRuleName:self.theNewGameModel.disputeResolutionRule];
    bool hasDisclosureIndicator = (GoLifeAndDeathSettlingRuleThreePasses != self.theNewGameModel.lifeAndDeathSettlingRule);
    return [TableViewVariableHeightCell heightForRowInTableView:tableView
                                                descriptionText:disputeResolutionRuleText
                                                      valueText:valueText
                                         hasDisclosureIndicator:hasDisclosureIndicator];
  }
  else
  {
    return tableView.rowHeight;
  }
}

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
    case KomiCellID:
    {
      modalController = [KomiSelectionController controllerWithDelegate:self
                                                            defaultKomi:self.theNewGameModel.komi];
      break;
    }
    default:
    {
      NSString* title;
      NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
      int indexOfDefaultItem = -1;
      switch (cellID)
      {
        case KoRuleCellID:
        {
          title = @"Ko rule";
          enum GoKoRule defaultKoRule = self.theNewGameModel.koRule;
          for (int koRule = 0; koRule <= GoKoRuleMax; ++koRule)
          {
            NSString* koRuleString = [NSString stringWithKoRule:koRule];
            [itemList addObject:koRuleString];
            if (koRule == defaultKoRule)
              indexOfDefaultItem = koRule;
          }
          break;
        }
        case ScoringSystemCellID:
        {
          title = @"Scoring system";
          enum GoScoringSystem defaultScoringSystem = self.theNewGameModel.scoringSystem;
          for (int scoringSystem = 0; scoringSystem <= GoScoringSystemMax; ++scoringSystem)
          {
            NSString* scoringSystemString = [NSString stringWithScoringSystem:scoringSystem];
            [itemList addObject:scoringSystemString];
            if (scoringSystem == defaultScoringSystem)
              indexOfDefaultItem = scoringSystem;
          }
          break;
        }
        case LifeAndDeathSettlingRuleCellID:
        {
          title = @"Life & death settling after";
          enum GoLifeAndDeathSettlingRule defaultLifeAndDeathSettlingRule = self.theNewGameModel.lifeAndDeathSettlingRule;
          for (int lifeAndDeathSettlingRule = 0; lifeAndDeathSettlingRule <= GoLifeAndDeathSettlingRuleMax; ++lifeAndDeathSettlingRule)
          {
            NSString* lifeAndDeathSettlingRuleString = [NewGameAdvancedController lifeAndDeathSettlingRuleName:lifeAndDeathSettlingRule];
            [itemList addObject:lifeAndDeathSettlingRuleString];
            if (lifeAndDeathSettlingRule == defaultLifeAndDeathSettlingRule)
              indexOfDefaultItem = lifeAndDeathSettlingRule;
          }
          break;
        }
        case DisputeResolutionRuleCellID:
        {
          if (GoLifeAndDeathSettlingRuleThreePasses == self.theNewGameModel.lifeAndDeathSettlingRule)
            return;

          title = @"Dispute resolution";
          enum GoDisputeResolutionRule defaultDisputeResolutionRule = self.theNewGameModel.disputeResolutionRule;
          for (int disputeResolutionRule = 0; disputeResolutionRule <= GoDisputeResolutionRuleMax; ++disputeResolutionRule)
          {
            NSString* disputeResolutionRuleString = [NewGameAdvancedController disputeResolutionRuleName:disputeResolutionRule];
            [itemList addObject:disputeResolutionRuleString];
            if (disputeResolutionRule == defaultDisputeResolutionRule)
              indexOfDefaultItem = disputeResolutionRule;
          }
          break;
        }
        case FourPassesRuleCellID:
        {
          title = @"Four passes rule";
          enum GoFourPassesRule defaultFourPassesRule = self.theNewGameModel.fourPassesRule;
          for (int fourPassesRule = 0; fourPassesRule <= GoFourPassesRuleMax; ++fourPassesRule)
          {
            NSString* fourPassesRuleString = [NewGameAdvancedController fourPassesRuleName:fourPassesRule];
            [itemList addObject:fourPassesRuleString];
            if (fourPassesRule == defaultFourPassesRule)
              indexOfDefaultItem = fourPassesRule;
          }
          break;
        }
        default:
        {
          assert(0);
          return;
        }
      }
      ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                          title:title
                                                                             indexOfDefaultItem:indexOfDefaultItem
                                                                                       delegate:self];
      itemPickerController.context = indexPath;
      modalController = itemPickerController;
      break;
    }
  }
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:modalController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
}

#pragma mark - KomiSelectionDelegate overrides

// -----------------------------------------------------------------------------
/// @brief KomiSelectionDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) komiSelectionController:(KomiSelectionController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (self.theNewGameModel.komi != controller.komi)
    {
      self.theNewGameModel.komi = controller.komi;
      NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:KomiSection];
      [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection && controller.indexOfDefaultItem != controller.indexOfSelectedItem)
  {
    NSIndexPath* indexPathContext = controller.context;
    enum CellID cellID = [self cellIDForIndexPath:indexPathContext];
    switch (cellID)
    {
      case KoRuleCellID:
      {
        self.theNewGameModel.koRule = controller.indexOfSelectedItem;
        break;
      }
      case ScoringSystemCellID:
      {
        self.theNewGameModel.scoringSystem = controller.indexOfSelectedItem;
        if (! self.loadGame && 0 == self.theNewGameModel.handicap)
        {
          [self autoAdjustKomi];
          NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:KomiSection];
          [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
        }
        break;
      }
      case LifeAndDeathSettlingRuleCellID:
      {
        self.theNewGameModel.lifeAndDeathSettlingRule = controller.indexOfSelectedItem;
        if (GoLifeAndDeathSettlingRuleThreePasses == self.theNewGameModel.lifeAndDeathSettlingRule)
        {
          self.theNewGameModel.disputeResolutionRule = GoDisputeResolutionRuleAlternatingPlay;
          self.theNewGameModel.fourPassesRule = GoFourPassesRuleFourPassesHaveNoSpecialMeaning;
        }
        [self.tableView reloadData];
        break;
      }
      case DisputeResolutionRuleCellID:
      {
        self.theNewGameModel.disputeResolutionRule = controller.indexOfSelectedItem;
        break;
      }
      case FourPassesRuleCellID:
      {
        self.theNewGameModel.fourPassesRule = controller.indexOfSelectedItem;
        break;
      }
      default:
      {
        assert(0);
        break;
      }
    }
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:indexPathContext.section];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the #SectionID value that corresponds to @a section.
// -----------------------------------------------------------------------------
- (enum SectionID) sectionIDForSection:(NSInteger)section
{
  if (self.loadGame)
  {
    switch (section)
    {
      case KoRuleScoringSystemSection_LoadGame:
        return KoRuleScoringSystemSectionID;
      case LifeAndDeathSettlingRuleSection_LoadGame:
        return LifeAndDeathSettlingRuleSectionID;
      case DisputeResolutionRuleSection_LoadGame:
        return DisputeResolutionRuleSectionID;
      case FourPassesRuleSection_LoadGame:
        return FourPassesRuleSectionID;
      default:
        break;
    }
  }
  else
  {
    switch (section)
    {
      case KomiSection:
        return KomiSectionID;
      case KoRuleScoringSystemSection:
        return KoRuleScoringSystemSectionID;
      case LifeAndDeathSettlingRuleSection:
        return LifeAndDeathSettlingRuleSectionID;
      case DisputeResolutionRuleSection:
        return DisputeResolutionRuleSectionID;
      case FourPassesRuleSection:
        return FourPassesRuleSectionID;
      default:
        break;
    }
  }

  NSString* errorMessage = [NSString stringWithFormat:@"Cannot determine section ID, loadGame = %d, section = %d",
                            self.loadGame, section];
  DDLogError(@"%@: %@", self, errorMessage);
  NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                   reason:errorMessage
                                                 userInfo:nil];
  @throw exception;
}

// -----------------------------------------------------------------------------
/// @brief Returns the #CellID value that corresponds to @a indexPath.
// -----------------------------------------------------------------------------
- (enum CellID) cellIDForIndexPath:(NSIndexPath*)indexPath
{
  enum SectionID sectionID = [self sectionIDForSection:indexPath.section];
  switch (sectionID)
  {
    case KomiSectionID:
    {
      switch (indexPath.row)
      {
        case KomiItem:
          return KomiCellID;
        default:
          break;
      }
      break;
    }
    case KoRuleScoringSystemSectionID:
    {
      switch (indexPath.row)
      {
        case KoRuleItem:
          return KoRuleCellID;
        case ScoringSystemItem:
          return ScoringSystemCellID;
        default:
          break;
      }
      break;
    }
    case LifeAndDeathSettlingRuleSectionID:
    {
      switch (indexPath.row)
      {
        case LifeAndDeathSettlingRuleItem:
          return LifeAndDeathSettlingRuleCellID;
        default:
          break;
      }
      break;
    }
    case DisputeResolutionRuleSectionID:
    {
      switch (indexPath.row)
      {
        case DisputeResolutionRuleItem:
          return DisputeResolutionRuleCellID;
        default:
          break;
      }
      break;
    }
    case FourPassesRuleSectionID:
    {
      switch (indexPath.row)
      {
        case FourPassesRuleItem:
          return FourPassesRuleCellID;
        default:
          break;
      }
      break;
    }
    default:
    {
      break;
    }
  }

  NSString* errorMessage = [NSString stringWithFormat:@"Cannot determine cell ID, loadGame = %d, sectionID = %d, indexPath.section = %d, indexPath.row = %d",
                            self.loadGame, sectionID, indexPath.section, indexPath.row];
  DDLogError(@"%@: %@", self, errorMessage);
  NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                   reason:errorMessage
                                                 userInfo:nil];
  @throw exception;
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
/// @brief Returns a string representation of @a lifeAndDeathSettlingRule that
/// is suitable for displaying in the UI.
///
/// Raises an @e NSInvalidArgumentException if @a lifeAndDeathSettlingRule is
/// not recognized.
// -----------------------------------------------------------------------------
+ (NSString*) lifeAndDeathSettlingRuleName:(enum GoLifeAndDeathSettlingRule)lifeAndDeathSettlingRule
{
  switch (lifeAndDeathSettlingRule)
  {
    case GoLifeAndDeathSettlingRuleTwoPasses:
      return @"2 passes";
    case GoLifeAndDeathSettlingRuleThreePasses:
      return @"3 passes";
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid life & death settling rule: %d", lifeAndDeathSettlingRule];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a disputeResolutionRule that is
/// suitable for displaying in the UI.
///
/// Raises an @e NSInvalidArgumentException if @a disputeResolutionRule is not
/// recognized.
// -----------------------------------------------------------------------------
+ (NSString*) disputeResolutionRuleName:(enum GoDisputeResolutionRule)disputeResolutionRule
{
  switch (disputeResolutionRule)
  {
    case GoDisputeResolutionRuleAlternatingPlay:
      return @"Alternating play";
    case GoDisputeResolutionRuleNonAlternatingPlay:
      return @"Non-alternating play";
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid dispute resolution rule rule: %d", disputeResolutionRule];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a fourPassesRule that is suitable
/// for displaying in the UI.
///
/// Raises an @e NSInvalidArgumentException if @a fourPassesRule is not
/// recognized.
// -----------------------------------------------------------------------------
+ (NSString*) fourPassesRuleName:(enum GoFourPassesRule)fourPassesRule
{
  switch (fourPassesRule)
  {
    case GoFourPassesRuleFourPassesEndTheGame:
      return @"End game";
    case GoFourPassesRuleFourPassesHaveNoSpecialMeaning:
      return @"No special meaning";
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid four passes rule: %d", fourPassesRule];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

@end
