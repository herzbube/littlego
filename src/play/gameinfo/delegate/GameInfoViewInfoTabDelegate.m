// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameInfoViewInfoTabDelegate.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoGameInfo.h"
#import "../../../ui/TableViewCellFactory.h"
#import "../../../ui/TableViewVariableHeightCell.h"
#import "../../../ui/UIViewControllerAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Info" tab of the
/// "Game Info" table view.
// -----------------------------------------------------------------------------
enum GameInfoInfoTabTableViewSection
{
  GameDataSection,
  BasicGameInfoSection,
  BlackPlayerSection,
  WhitePlayerSection,
  ContextSection,
  MaxSection,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GameDataSection.
// -----------------------------------------------------------------------------
enum GameDataSectionItem
{
  RecorderNameItem,
  SourceNameItem,
  AnnotationAuthorItem,
  CopyrightInformationItem,
  MaxGameDataSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the BasicGameInfoSection.
// -----------------------------------------------------------------------------
enum BasicGameInfoSectionItem
{
  GameNameItem,
  GameInformationItem,
  GameDatesItem,
  RulesNameItem,
  OpeningInformationItem,
  MaxBasicGameInfoSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the BlackPlayerSection.
// -----------------------------------------------------------------------------
enum BlackPlayerSectionItem
{
  BlackPlayerNameItem,
  BlackPlayerRankItem,
  BlackPlayerTeamNameItem,
  MaxBlackPlayerSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the WhitePlayerSection.
// -----------------------------------------------------------------------------
enum WhitePlayerSectionItem
{
  WhitePlayerNameItem,
  WhitePlayerRankItem,
  WhitePlayerTeamNameItem,
  MaxWhitePlayerSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ContextSection.
// -----------------------------------------------------------------------------
enum ContextSectionItem
{
  GameLocationItem,
  EventNameItem,
  RoundInformationItem,
  MaxContextSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates all table view cells that can ever appear in the
/// "Info tab" of the "Game Info" table view, without regard to the conditions
/// under which they appear.
///
/// This enumeration exists to simplify controller logic. Using this enumeration
/// allows to write a single switch() statement instead of writing complicated
/// nested switch/if statements.
// -----------------------------------------------------------------------------
enum CellId
{
  CellIdRecorderName,
  CellIdSourceName,
  CellIdAnnotationAuthor,
  CellIdCopyrightInformation,
  CellIdGameName,
  CellIdGameInformation,
  CellIdGameDates,
  CellIdRulesName,
  CellIdOpeningInformation,
  CellIdBlackPlayerName,
  CellIdBlackPlayerRank,
  CellIdBlackPlayerTeamName,
  CellIdWhitePlayerName,
  CellIdWhitePlayerRank,
  CellIdWhitePlayerTeamName,
  CellIdGameLocation,
  CellIdEventName,
  CellIdRoundInformation,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties and properties for
/// GameInfoViewInfoTabDelegate.
// -----------------------------------------------------------------------------
@interface GameInfoViewInfoTabDelegate()
@property(nonatomic, assign) UIViewController* presentingViewController;
@property(nonatomic, assign) UITableView* tableView;
@property(nonatomic, retain) GoGameInfo* gameInfo;
@end


@implementation GameInfoViewInfoTabDelegate

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GameInfoViewInfoTabDelegate object.
///
/// @note This is the designated initializer of GameInfoViewInfoTabDelegate.
// -----------------------------------------------------------------------------
- (id) initWithPresentingViewController:(UIViewController*)presentingViewController
                              tableView:(UITableView*)tableView
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.presentingViewController = presentingViewController;
  self.tableView = tableView;
  self.gameInfo = [GoGame sharedGame].gameInfo;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoViewInfoTabDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.presentingViewController = nil;
  self.tableView = nil;
  self.gameInfo = nil;

  [super dealloc];
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
    case GameDataSection:
      return MaxGameDataSectionItem;
    case BasicGameInfoSection:
      return MaxBasicGameInfoSectionItem;
    case BlackPlayerSection:
      return MaxBlackPlayerSectionItem;
    case WhitePlayerSection:
      return MaxWhitePlayerSectionItem;
    case ContextSection:
      return MaxContextSectionItem;
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
    case GameDataSection:
      return @"Game data / game record information";
    case BasicGameInfoSection:
      return @"Game information";
    case BlackPlayerSection:
      return @"Black player";
    case WhitePlayerSection:
      return @"White player";
    case ContextSection:
      return @"Context in which the game was played";
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
  enum CellId cellId = [self cellIdForIndexPath:indexPath];
  UITableViewCell* cell = [self createCellWithCellId:cellId
                                        forTableView:tableView];
  [self configureCell:cell
           withCellId:cellId];
  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  enum CellId cellId = [self cellIdForIndexPath:indexPath];
  [self showEditTextControllerForCellId:cellId indexPath:indexPath];
}

#pragma mark - Private helpers for tableView:cellForRowAtIndexPath:()

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UITableViewCell*) createCellWithCellId:(enum CellId)cellId
                             forTableView:(UITableView*)tableView
{
  // All cells can contain an unpredictable amount of text, therefore a
  // variable height cell is a must
  return [TableViewCellFactory cellWithType:VariableHeightCellType tableView:tableView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (void) configureCell:(UITableViewCell*)cell
            withCellId:(enum CellId)cellId
{
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  TableViewVariableHeightCell* variableHeightCell = (TableViewVariableHeightCell*)cell;

  switch (cellId)
  {
    default:
      variableHeightCell.descriptionLabel.text = [self cellLabelForCellId:cellId];
      variableHeightCell.valueLabel.text = [self cellValueForCellId:cellId];
      break;
  }
}

#pragma mark - Private helpers for tableView:didSelectRowAtIndexPath:()

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:didSelectRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (void) showEditTextControllerForCellId:(enum CellId)cellId indexPath:(NSIndexPath*)indexPath
{
  NSString* textToEdit = [self gameInfoPropertyValueForCellId:cellId];

  // The SGF property GC is the only game info property with a Text value type,
  // i.e. it may contain newlines => we show a text view for it. All other
  // properties are SimpleText properties which may not contain newlines
  // => we show a text field for those.
  enum EditTextControllerStyle editTextControllerStyle = (cellId == CellIdGameInformation
                                                          ? EditTextControllerStyleTextView
                                                          : EditTextControllerStyleTextField);

  EditTextController* editTextController = [EditTextController controllerWithText:textToEdit
                                                                            style:editTextControllerStyle
                                                                         delegate:self];
  editTextController.title = [@"Edit " stringByAppendingString:[self cellLabelForCellId:cellId]];
  editTextController.context = indexPath;
  editTextController.footerText = [self footerTextForCellId:cellId];

  [self.presentingViewController presentNavigationControllerWithRootViewController:editTextController];
}

#pragma mark - EditTextDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController isTextValid:(NSString*)text validationErrorMessage:(NSString**)validationErrorMessage
{
  if (validationErrorMessage)
    *validationErrorMessage = nil;
  return [self controller:editTextController isValidText:text];
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  return [self controller:editTextController isValidText:text];
}

// -----------------------------------------------------------------------------
/// @brief Helper method for EditTextDelegate protocol methods.
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController isValidText:(NSString*)text
{
  return true;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel
{
  if (! didCancel && editTextController.textHasChanged)
  {
    NSString* newPropertyValue = editTextController.text;
    if (newPropertyValue && newPropertyValue.length == 0)
      newPropertyValue = nil;

    NSIndexPath* indexPath = editTextController.context;
    enum CellId cellId = [self cellIdForIndexPath:indexPath];
    [self setGameInfoPropertyForCellId:cellId withPropertyValue:newPropertyValue];

    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
  }

  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the #CellId value that corresponds to @a indexPath.
// -----------------------------------------------------------------------------
- (enum CellId) cellIdForIndexPath:(NSIndexPath*)indexPath
{
  switch (indexPath.section)
  {
    case GameDataSection:
      switch (indexPath.row)
      {
        case RecorderNameItem:
          return CellIdRecorderName;
        case SourceNameItem:
          return CellIdSourceName;
        case AnnotationAuthorItem:
          return CellIdAnnotationAuthor;
        case CopyrightInformationItem:
          return CellIdCopyrightInformation;
        default:
          break;
      }
    case BasicGameInfoSection:
      switch (indexPath.row)
      {
        case GameNameItem:
          return CellIdGameName;
        case GameInformationItem:
          return CellIdGameInformation;
        case GameDatesItem:
          return CellIdGameDates;
        case RulesNameItem:
          return CellIdRulesName;
        case OpeningInformationItem:
          return CellIdOpeningInformation;
        default:
          break;
      }
    case BlackPlayerSection:
      switch (indexPath.row)
      {
        case BlackPlayerNameItem:
          return CellIdBlackPlayerName;
        case BlackPlayerRankItem:
          return CellIdBlackPlayerRank;
        case BlackPlayerTeamNameItem:
          return CellIdBlackPlayerTeamName;
        default:
          break;
      }
    case WhitePlayerSection:
      switch (indexPath.row)
      {
        case WhitePlayerNameItem:
          return CellIdWhitePlayerName;
        case WhitePlayerRankItem:
          return CellIdWhitePlayerRank;
        case WhitePlayerTeamNameItem:
          return CellIdWhitePlayerTeamName;
        default:
          break;
      }
    case ContextSection:
      switch (indexPath.row)
      {
        case GameLocationItem:
          return CellIdGameLocation;
        case EventNameItem:
          return CellIdEventName;
        case RoundInformationItem:
          return CellIdRoundInformation;
        default:
          break;
      }
    default:
      break;
  }

  assert(0);
  return -1;
}

// -----------------------------------------------------------------------------
/// @brief Returns the game info property value that corresponds to @a cellId.
// -----------------------------------------------------------------------------
- (NSString*) cellValueForCellId:(enum CellId)cellId
{
  NSString* gameInfoPropertyValue = [self gameInfoPropertyValueForCellId:cellId];
  return [self cellValueForGameInfoPropertyValue:gameInfoPropertyValue];
}

// -----------------------------------------------------------------------------
/// @brief Returns the game info property value that corresponds to @a cellId.
// -----------------------------------------------------------------------------
- (NSString*) gameInfoPropertyValueForCellId:(enum CellId)cellId
{
  switch (cellId)
  {
    case CellIdRecorderName:
      return self.gameInfo.recorderName;
    case CellIdSourceName:
      return self.gameInfo.sourceName;
    case CellIdAnnotationAuthor:
      return self.gameInfo.annotationAuthor;
    case CellIdCopyrightInformation:
      return self.gameInfo.copyrightInformation;
    case CellIdGameName:
      return self.gameInfo.gameName;
    case CellIdGameInformation:
      return self.gameInfo.gameInformation;
    case CellIdGameDates:
      return self.gameInfo.gameDates;
    case CellIdRulesName:
      return self.gameInfo.rulesName;
    case CellIdOpeningInformation:
      return self.gameInfo.openingInformation;
    case CellIdBlackPlayerName:
      return self.gameInfo.blackPlayerName;
    case CellIdBlackPlayerRank:
      return self.gameInfo.blackPlayerRank;
    case CellIdBlackPlayerTeamName:
      return self.gameInfo.blackPlayerTeamName;
    case CellIdWhitePlayerName:
      return self.gameInfo.whitePlayerName;
    case CellIdWhitePlayerRank:
      return self.gameInfo.whitePlayerRank;
    case CellIdWhitePlayerTeamName:
      return self.gameInfo.whitePlayerTeamName;
    case CellIdGameLocation:
      return self.gameInfo.gameLocation;
    case CellIdEventName:
      return self.gameInfo.eventName;
    case CellIdRoundInformation:
      return self.gameInfo.roundInformation;
    default:
      assert(0);
      break;
  }

  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Updates the game info property that corresponds to @a cellId with
/// @a propertyValue.
// -----------------------------------------------------------------------------
- (void) setGameInfoPropertyForCellId:(enum CellId)cellId withPropertyValue:(NSString*)propertyValue
{
  switch (cellId)
  {
    case CellIdRecorderName:
      self.gameInfo.recorderName = propertyValue;
      break;
    case CellIdSourceName:
      self.gameInfo.sourceName = propertyValue;
      break;
    case CellIdAnnotationAuthor:
      self.gameInfo.annotationAuthor = propertyValue;
      break;
    case CellIdCopyrightInformation:
      self.gameInfo.copyrightInformation = propertyValue;
      break;
    case CellIdGameName:
      self.gameInfo.gameName = propertyValue;
      break;
    case CellIdGameInformation:
      self.gameInfo.gameInformation = propertyValue;
      break;
    case CellIdGameDates:
      self.gameInfo.gameDates = propertyValue;
      break;
    case CellIdRulesName:
      self.gameInfo.rulesName = propertyValue;
      break;
    case CellIdOpeningInformation:
      self.gameInfo.openingInformation = propertyValue;
      break;
    case CellIdBlackPlayerName:
      self.gameInfo.blackPlayerName = propertyValue;
      break;
    case CellIdBlackPlayerRank:
      self.gameInfo.blackPlayerRank = propertyValue;
      break;
    case CellIdBlackPlayerTeamName:
      self.gameInfo.blackPlayerTeamName = propertyValue;
      break;
    case CellIdWhitePlayerName:
      self.gameInfo.whitePlayerName = propertyValue;
      break;
    case CellIdWhitePlayerRank:
      self.gameInfo.whitePlayerRank = propertyValue;
      break;
    case CellIdWhitePlayerTeamName:
      self.gameInfo.whitePlayerTeamName = propertyValue;
      break;
    case CellIdGameLocation:
      self.gameInfo.gameLocation = propertyValue;
      break;
    case CellIdEventName:
      self.gameInfo.eventName = propertyValue;
      break;
    case CellIdRoundInformation:
      self.gameInfo.roundInformation = propertyValue;
      break;
    default:
      assert(0);
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that can be displayed in a table view cell and that
/// represents @a gameInfoPropertyValue.
// -----------------------------------------------------------------------------
- (NSString*) cellValueForGameInfoPropertyValue:(NSString*)gameInfoPropertyValue
{
  if (gameInfoPropertyValue && gameInfoPropertyValue.length > 0)
    return gameInfoPropertyValue;
  else
    return @"<Not set>";
}

// -----------------------------------------------------------------------------
/// @brief Returns the game info property value that corresponds to @a cellId.
// -----------------------------------------------------------------------------
- (NSString*) cellLabelForCellId:(enum CellId)cellId
{
  switch (cellId)
  {
    case CellIdRecorderName:
      return @"Recorder name";
    case CellIdSourceName:
      return @"Source name";
    case CellIdAnnotationAuthor:
      return @"Annotation author";
    case CellIdCopyrightInformation:
      return @"Copyright information";
    case CellIdGameName:
      return @"Game name";
    case CellIdGameInformation:
      return @"Game information";
    case CellIdGameDates:
      return @"Game dates";
    case CellIdRulesName:
      return @"Game rules";
    case CellIdOpeningInformation:
      return @"Opening information";
    case CellIdBlackPlayerName:
      return @"Black player name";
    case CellIdBlackPlayerRank:
      return @"Black player rank";
    case CellIdBlackPlayerTeamName:
      return @"Black player team name";
    case CellIdWhitePlayerName:
      return @"White player name";
    case CellIdWhitePlayerRank:
      return @"White player rank";
    case CellIdWhitePlayerTeamName:
      return @"White player team name";
    case CellIdGameLocation:
      return @"Game location";
    case CellIdEventName:
      return @"Event name";
    case CellIdRoundInformation:
      return @"Round information";
    default:
      assert(0);
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the game info property value that corresponds to @a cellId.
// -----------------------------------------------------------------------------
- (NSString*) footerTextForCellId:(enum CellId)cellId
{
  switch (cellId)
  {
    case CellIdRecorderName:
      return @"The name of the user (or program) who recorded or entered the game data.";
    case CellIdSourceName:
      return @"The name of the source of the game data (e.g. book, journal, etc.).";
    case CellIdAnnotationAuthor:
      return @"The name of the person who made the annotations to the game.";
    case CellIdCopyrightInformation:
      return @"The copyright information for the game data (including the annotations).";
    case CellIdGameName:
      return @"The name of the game (e.g. for easily finding the game again within a collection).";
    case CellIdGameInformation:
      return @"Information about the game (e.g. background information, a game summary, etc.). Newlines may be used to separate paragraphs.";
    case CellIdGameDates:
      return @"The dates when the game was played.";
    case CellIdRulesName:
      return @"The name of the rules used for the game.";
    case CellIdOpeningInformation:
      return @"Information about the opening played.";
    case CellIdBlackPlayerName:
      return @"The name of the black player.";
    case CellIdBlackPlayerRank:
      return @"The rank of the black player.";
    case CellIdBlackPlayerTeamName:
      return @"The name of the black player's team.";
    case CellIdWhitePlayerName:
      return @"The name of the white player.";
    case CellIdWhitePlayerRank:
      return @"The rank of the white player.";
    case CellIdWhitePlayerTeamName:
      return @"The name of the white player's team.";
    case CellIdGameLocation:
      return @"The name or description of the location where the game was played.";
    case CellIdEventName:
      return @"The name of the event (e.g. tournament) where the game was played.";
    case CellIdRoundInformation:
      return @"The information that describes the round in which the game was played.";
    default:
      assert(0);
      return nil;
  }
}


@end
