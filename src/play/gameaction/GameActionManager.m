// -----------------------------------------------------------------------------
// Copyright 2015-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameActionManager.h"
#import "../controller/DiscardFutureNodesAlertController.h"
#import "../model/BoardSetupModel.h"
#import "../model/BoardViewModel.h"
#import "../model/MarkupModel.h"
#import "../model/ScoringModel.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeMarkup.h"
#import "../../go/GoNodeSetup.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoScore.h"
#import "../../command/gtp/InterruptComputerCommand.h"
#import "../../command/boardposition/ChangeAndDiscardCommand.h"
#import "../../command/boardposition/PlayCommand.h"
#import "../../command/boardsetup/DiscardAllSetupStonesCommand.h"
#import "../../command/boardsetup/HandleBoardSetupInteractionCommand.h"
#import "../../command/boardsetup/SetupFirstMoveColorCommand.h"
#import "../../command/game/PauseGameCommand.h"
#import "../../command/markup/DiscardAllMarkupCommand.h"
#import "../../command/markup/HandleMarkupEditingInteractionCommand.h"
#import "../../command/move/ComputerSuggestMoveCommand.h"
#import "../../command/node/ChangeNodeSelectionAsyncCommand.h"
#import "../../command/scoring/ToggleScoringStateOfStoneGroupCommand.h"
#import "../../command/ChangeUIAreaPlayModeCommand.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../shared/LayoutManager.h"
#import "../../ui/UiSettingsModel.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/MarkupUtilities.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GameActionManager.
// -----------------------------------------------------------------------------
@interface GameActionManager()
@property(nonatomic, retain) NSArray* visibleGameActions;
@property(nonatomic, retain) NSMutableDictionary* enabledStates;
@property(nonatomic, assign) bool visibleStatesNeedUpdate;
@property(nonatomic, assign) bool enabledStatesNeedUpdate;
@property(nonatomic, assign) bool scoringModeNeedUpdate;
@property(nonatomic, assign) GameInfoViewController* gameInfoViewController;
@property(nonatomic, retain) MoreGameActionsController* moreGameActionsController;
@property(nonatomic, assign) ItemPickerController* itemPickerController;
@property(nonatomic, retain) DiscardFutureNodesAlertController* discardFutureNodesAlertController;
@end


@implementation GameActionManager

#pragma mark - Shared handling

// -----------------------------------------------------------------------------
/// @brief Shared instance of GameActionManager.
// -----------------------------------------------------------------------------
static GameActionManager* sharedGameActionManager = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared GameActionManager object.
// -----------------------------------------------------------------------------
+ (GameActionManager*) sharedGameActionManager
{
  @synchronized(self)
  {
    if (! sharedGameActionManager)
      sharedGameActionManager = [[GameActionManager alloc] init];
    return sharedGameActionManager;
  }
}

// -----------------------------------------------------------------------------
/// @brief Releases the shared GameActionManager object.
// -----------------------------------------------------------------------------
+ (void) releaseSharedGameActionManager
{
  @synchronized(self)
  {
    if (sharedGameActionManager)
    {
      [sharedGameActionManager release];
      sharedGameActionManager = nil;
    }
  }
}

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GameActionManager object.
///
/// @note This is the designated initializer of GameActionManager.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.uiDelegate = nil;
  self.viewControllerPresenterDelegate = nil;
  self.visibleGameActions = [NSArray array];
  self.enabledStates = [NSMutableDictionary dictionary];
  for (int gameAction = GameActionFirst; gameAction <= GameActionLast; ++gameAction)
    [self.enabledStates setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithInt:gameAction]];
  self.visibleStatesNeedUpdate = false;
  self.enabledStatesNeedUpdate = false;
  self.scoringModeNeedUpdate = false;
  self.gameInfoViewController = nil;
  self.moreGameActionsController = nil;
  self.itemPickerController = nil;
  self.discardFutureNodesAlertController = [[[DiscardFutureNodesAlertController alloc] init] autorelease];
  self.commandDelegate = self.discardFutureNodesAlertController;
  [self setupNotificationResponders];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameActionManager object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.visibleGameActions = nil;
  self.enabledStates = nil;
  self.gameInfoViewController = nil;
  self.moreGameActionsController = nil;
  self.itemPickerController = nil;
  self.uiDelegate = nil;
  self.commandDelegate = nil;
  self.viewControllerPresenterDelegate = nil;
  self.discardFutureNodesAlertController = nil;
  [super dealloc];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(uiAreaPlayModeDidChange:) name:uiAreaPlayModeDidChange object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(boardViewPanningGestureWillStart:) name:boardViewPanningGestureWillStart object:nil];
  [center addObserver:self selector:@selector(boardViewPanningGestureWillEnd:) name:boardViewPanningGestureWillEnd object:nil];
  [center addObserver:self selector:@selector(setupPointDidChange:) name:setupPointDidChange object:nil];
  [center addObserver:self selector:@selector(allSetupStonesDidDiscard:) name:allSetupStonesDidDiscard object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationWillBegin:) name:boardViewAnimationWillBegin object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationDidEnd:) name:boardViewAnimationDidEnd object:nil];
  [center addObserver:self selector:@selector(markupOnPointsDidChange:) name:markupOnPointsDidChange object:nil];
  [center addObserver:self selector:@selector(allMarkupDidDiscard:) name:allMarkupDidDiscard object:nil];
  [center addObserver:self selector:@selector(currentBoardPositionDidChange:) name:currentBoardPositionDidChange object:nil];
  [center addObserver:self selector:@selector(numberOfBoardPositionsDidChange:) name:numberOfBoardPositionsDidChange object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // Note: UIApplicationWillChangeStatusBarOrientationNotification is also sent
  // if a view controller is modally presented on iPhone while in
  // UIInterfaceOrientationPortraitUpsideDown. This is unexpected and not
  // something we want, because our notification handler dismisses a controller
  // that might be the one doing the presenting, which would cause a crash. So
  // here we make sure that we react to the notification only on iPad - which
  // is exactly the device we want to handle anyway because popovers exist only
  // on iPad.
  if ([LayoutManager sharedManager].uiType == UITypePad)
    [center addObserver:self selector:@selector(statusBarOrientationWillChange:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];

  // KVO observing
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  [appDelegate.boardSetupModel addObserver:self forKeyPath:@"boardSetupStoneColor" options:0 context:NULL];
  [appDelegate.boardViewModel addObserver:self forKeyPath:@"computerAssistanceType" options:0 context:NULL];
  [appDelegate.markupModel addObserver:self forKeyPath:@"selectedSymbolMarkupStyle" options:0 context:NULL];
  [appDelegate.markupModel addObserver:self forKeyPath:@"markupType" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for dealloc.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  [appDelegate.boardSetupModel removeObserver:self forKeyPath:@"boardSetupStoneColor"];
  [appDelegate.boardViewModel removeObserver:self forKeyPath:@"computerAssistanceType"];
  [appDelegate.markupModel removeObserver:self forKeyPath:@"selectedSymbolMarkupStyle"];
  [appDelegate.markupModel removeObserver:self forKeyPath:@"markupType"];
}

#pragma mark - Handlers for board interactions

// -----------------------------------------------------------------------------
/// @brief Places a stone on behalf of the player whose turn it currently is,
/// at the intersection identified by @a point.
// -----------------------------------------------------------------------------
- (void) playAtIntersection:(GoPoint*)point
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring playAtIntersection", self);
    return;
  }
  PlayCommand* command = [[[PlayCommand alloc] initWithPoint:point] autorelease];
  [self.commandDelegate gameActionManager:self playOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Toggles either the "dead state" or the "seki state" of the stone
/// group that covers the intersection identified by @a point. Is invoked only
/// while the UI area "Play" is in scoring mode.
// -----------------------------------------------------------------------------
- (void) toggleScoringStateOfStoneGroupAtIntersection:(GoPoint*)point
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring toggleScoringStateOfStoneGroupAtIntersection", self);
    return;
  }

  [[[[ToggleScoringStateOfStoneGroupCommand alloc] initWithPoint:point] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Handles a board setup interaction at the intersection identified by
/// @a point. Is invoked only while the UI area "Play" is in board setup mode.
// -----------------------------------------------------------------------------
- (void) handleBoardSetupAtIntersection:(GoPoint*)point
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring handleBoardSetupAtIntersection", self);
    return;
  }

  HandleBoardSetupInteractionCommand* command = [[[HandleBoardSetupInteractionCommand alloc] initWithPoint:point] autorelease];
  [self.commandDelegate gameActionManager:self discardOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Handles setting up the side that is to play first to
/// @a firstMoveColor. Is invoked only while the UI area "Play" is in board
/// setup mode.
// -----------------------------------------------------------------------------
- (void) handleSetupFirstMove:(enum GoColor)firstMoveColor
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring handleSetupFirstMove", self);
    return;
  }

  SetupFirstMoveColorCommand* command = [[[SetupFirstMoveColorCommand alloc] initWithFirstMoveColor:firstMoveColor] autorelease];
  [self.commandDelegate gameActionManager:self discardOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Handles a single tap at the intersection identified by @a point
/// while the UI area "Play" is in markup editing mode. @a markupTool and
/// @a markupType identify the markup tool and, more specifically, the markup
/// type that is currently selected in the UI.
// -----------------------------------------------------------------------------
- (void) handleMarkupEditingSingleTapAtIntersection:(GoPoint*)point
                                         markupTool:(enum MarkupTool)markupTool
                                         markupType:(enum MarkupType)markupType
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring handleMarkupEditingSingleTapAtIntersection:markupTool:markupType:", self);
    return;
  }

  if (markupTool == MarkupToolEraser)
  {
    [[[[HandleMarkupEditingInteractionCommand alloc] initEraseMarkupAtPoint:point] autorelease] submit];
  }
  else if (markupTool == MarkupToolConnection)
  {
    [[[[HandleMarkupEditingInteractionCommand alloc] initEraseConnectionAtPoint:point] autorelease] submit];
  }
  else
  {
    [[[[HandleMarkupEditingInteractionCommand alloc] initPlaceNewMarkupAtPoint:point
                                                                    markupTool:markupTool
                                                                    markupType:markupType] autorelease] submit];
  }
}

// -----------------------------------------------------------------------------
/// @brief Handles placing a markup symbol of type @a symbol at @a point after
/// the symbol was moved with a panning gesture from a previous location. Is
/// invoked only while the UI area "Play" is in markup editing mode.
// -----------------------------------------------------------------------------
- (void) handleMarkupEditingPlaceMovedSymbol:(enum GoMarkupSymbol)symbol
                                     atPoint:(GoPoint*)point
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring handleMarkupEditingPlaceMovedSymbol:atPoint:", self);
    return;
  }

  [[[[HandleMarkupEditingInteractionCommand alloc] initPlaceMovedSymbol:symbol
                                                                atPoint:point] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Handles placing a markup connection of type @a connection starting
/// at @a fromPoint and going to @a endPoint. The connection is placed after a
/// panning gesture completes. If @a connectionWasMoved is @e false the
/// connection is a new connection, if @a connectionWasMoved is @e true the
/// connection already existed but either its starting or end point was moved
/// from a previous location. Is invoked only while the UI area "Play" is in
/// markup editing mode.
// -----------------------------------------------------------------------------
- (void) handleMarkupEditingPlaceNewOrMovedConnection:(enum GoMarkupConnection)connection
                                            fromPoint:(GoPoint*)fromPoint
                                              toPoint:(GoPoint*)toPoint
                                   connectionWasMoved:(bool)connectionWasMoved
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring handleMarkupEditingPlaceNewOrMovedConnection:fromPoint:toPoint:connectionWasMoved:", self);
    return;
  }

  [[[[HandleMarkupEditingInteractionCommand alloc] initPlaceNewOrMovedConnection:connection
                                                                       fromPoint:fromPoint
                                                                         toPoint:toPoint
                                                              connectionWasMoved:connectionWasMoved] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Handles placing a markup label of type @a label with text
/// @a labelText at @a point after the label was moved with a panning gesture
/// from a previous location. Is invoked only while the UI area "Play" is in
/// markup editing mode.
// -----------------------------------------------------------------------------
- (void) handleMarkupEditingPlaceMovedLabel:(enum GoMarkupLabel)label
                              withLabelText:(NSString*)labelText
                                    atPoint:(GoPoint*)point;
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring handleMarkupEditingPlaceMovedLabel:withLabelText:atPoint:", self);
    return;
  }

  [[[[HandleMarkupEditingInteractionCommand alloc] initPlaceMovedLabel:label
                                                         withLabelText:labelText
                                                               atPoint:point] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Handles erasing all markup in an entire rectangular area defined by
/// @a fromPoint and @a endPoint, which are diagonally opposed corners of the
/// rectangle. Is invoked only while the UI area "Play" is in markup editing
/// mode.
// -----------------------------------------------------------------------------
- (void) handleMarkupEditingEraseMarkupInRectangleFromPoint:(GoPoint*)fromPoint
                                                    toPoint:(GoPoint*)toPoint
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring handleMarkupEditingEraseMarkupInRectangleFromPoint:toPoint:", self);
    return;
  }

  [[[[HandleMarkupEditingInteractionCommand alloc] initEraseMarkupInRectangleFromPoint:fromPoint
                                                                               toPoint:toPoint] autorelease] submit];
}

#pragma mark - Handlers for node tree interactions

// -----------------------------------------------------------------------------
/// @brief Selects the node @a node, i.e. changes the current board position
/// to display the content of @a node. Also changes the current game variation
/// if @a node is not in the current game variation.
// -----------------------------------------------------------------------------
- (void) selectNode:(GoNode*)node
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring selectNode:", self);
    return;
  }

  [[[[ChangeNodeSelectionAsyncCommand alloc] initWithNode:node] autorelease] submit];
}

#pragma mark - Mapping of game actions to handler methods

// -----------------------------------------------------------------------------
/// @brief Returns the selector of the handler method that should be invoked
/// on the shared GameActionManager object when @a gameAction is executed.
// -----------------------------------------------------------------------------
+ (SEL) handlerForGameAction:(enum GameAction)gameAction
{
  switch (gameAction)
  {
    case GameActionPass:
      return @selector(pass:);
    case GameActionDiscardBoardPosition:
      return @selector(discardBoardPosition:);
    case GameActionComputerPlay:
      return @selector(computerPlay:);
    case GameActionComputerSuggestMove:
      return @selector(computerSuggestMove:);
    case GameActionPause:
      return @selector(pause:);
    case GameActionContinue:
      return @selector(continue:);
    case GameActionInterrupt:
      return @selector(interrupt:);
    case GameActionScoringStart:
      return @selector(scoringStart:);
    case GameActionPlayStart:
      return @selector(playStart:);
    case GameActionSwitchSetupStoneColorToWhite:
      return @selector(switchSetupStoneColorToWhite:);
    case GameActionSwitchSetupStoneColorToBlack:
      return @selector(switchSetupStoneColorToBlack:);
    case GameActionDiscardAllSetupStones:
      return @selector(discardAllSetupStones:);
    case GameActionSelectMarkupType:
      return @selector(selectMarkupType:);
    case GameActionDiscardAllMarkup:
      return @selector(discardAllMarkup:);
    case GameActionGameInfo:
      return @selector(gameInfo:);
    case GameActionMoreGameActions:
      return @selector(moreGameActions:);
    case GameActionMoves:   // obsolete game action
    default:
      return nil;
  }
}

#pragma mark - Game action handlers

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionPass.
// -----------------------------------------------------------------------------
- (void) pass:(id)sender
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring GameActionPass", self);
    return;
  }

  // When the user attempts to place a stone then the gesture handler is doing
  // the legality check. When the user attempts to play a pass move, though,
  // this handler method is the first responder and is therefore responsible for
  // the legality check. PlayCommand, and all further commands down the line,
  // expect that this check has been made before executing the command.
  enum GoMoveIsIllegalReason illegalReason;
  bool isLegalMove = [[GoGame sharedGame] isLegalPassMoveIllegalReason:&illegalReason];
  if (! isLegalMove)
  {
    NSString* isIllegalReasonString = [NSString stringWithMoveIsIllegalReason:illegalReason];
    NSString* message = [@"Playing a pass move is not possible at the moment. Reason:\n\n" stringByAppendingString:isIllegalReasonString];
    [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:@"Cannot play pass move"
                                                                                    message:message
                                                                                  okHandler:nil];
    return;
  }

  PlayCommand* command = [[[PlayCommand alloc] initPass] autorelease];
  [self.commandDelegate gameActionManager:self playOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionDiscardBoardPosition.
// -----------------------------------------------------------------------------
- (void) discardBoardPosition:(id)sender
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring GameActionDiscardBoardPosition", self);
    return;
  }
  ChangeAndDiscardCommand* command = [[[ChangeAndDiscardCommand alloc] init] autorelease];
  [self.commandDelegate gameActionManager:self discardOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionComputerPlay.
// -----------------------------------------------------------------------------
- (void) computerPlay:(id)sender
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring GameActionComputerPlay", self);
    return;
  }
  PlayCommand* command = [[[PlayCommand alloc] initComputerPlay] autorelease];
  [self.commandDelegate gameActionManager:self playOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionComputerSuggestMove.
// -----------------------------------------------------------------------------
- (void) computerSuggestMove:(id)sender
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring GameActionComputerSuggestMove", self);
    return;
  }

  GoGame* game = [GoGame sharedGame];
  enum GoColor color = game.nextMovePlayer.color;

  [[[[ComputerSuggestMoveCommand alloc] initWithColor:color] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionPause.
// -----------------------------------------------------------------------------
- (void) pause:(id)sender
{
  [[[[PauseGameCommand alloc] init] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionContinue.
// -----------------------------------------------------------------------------
- (void) continue:(id)sender
{
  PlayCommand* command = [[[PlayCommand alloc] initContinue] autorelease];
  [self.commandDelegate gameActionManager:self playOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionInterrupt.
// -----------------------------------------------------------------------------
- (void) interrupt:(id)sender
{
  [[[[InterruptComputerCommand alloc] init] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionScoringStart.
// -----------------------------------------------------------------------------
- (void) scoringStart:(id)sender
{
  // This triggers a notification to which this manager reacts
  [[[[ChangeUIAreaPlayModeCommand alloc] initWithUIAreaPlayMode:UIAreaPlayModeScoring] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionPlayStart.
// -----------------------------------------------------------------------------
- (void) playStart:(id)sender
{
  [[[[ChangeUIAreaPlayModeCommand alloc] initWithUIAreaPlayMode:UIAreaPlayModePlay] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action
/// #GameActionSwitchSetupStoneColorToWhite.
// -----------------------------------------------------------------------------
- (void) switchSetupStoneColorToWhite:(id)sender
{
  [ApplicationDelegate sharedDelegate].boardSetupModel.boardSetupStoneColor = GoColorWhite;
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action
/// #GameActionSwitchSetupStoneColorToBlack.
// -----------------------------------------------------------------------------
- (void) switchSetupStoneColorToBlack:(id)sender
{
  [ApplicationDelegate sharedDelegate].boardSetupModel.boardSetupStoneColor = GoColorBlack;
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionDiscardAllSetupStones.
// -----------------------------------------------------------------------------
- (void) discardAllSetupStones:(id)sender
{
  DiscardAllSetupStonesCommand* command = [[[DiscardAllSetupStonesCommand alloc] init] autorelease];
  [self.commandDelegate gameActionManager:self discardOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionSelectMarkupType.
// -----------------------------------------------------------------------------
- (void) selectMarkupType:(id)sender
{
  enum SelectedSymbolMarkupStyle selectedSymbolMarkupStyle = [ApplicationDelegate sharedDelegate].markupModel.selectedSymbolMarkupStyle;

  NSMutableArray* itemList = [NSMutableArray array];
  for (enum MarkupType markupType = MarkupTypeFirst; markupType <= MarkupTypeLast; markupType++)
  {
    NSString* markupTypeText = [NSString stringWithMarkupType:markupType];
    UIImage* markupTypeIcon = [UIImage iconForMarkupType:markupType selectedSymbolMarkupStyle:selectedSymbolMarkupStyle];
    [itemList addObject:@[markupTypeText, markupTypeIcon]];
  }

  int indexOfDefaultItem = [ApplicationDelegate sharedDelegate].markupModel.markupType;
  NSString* screenTitle = @"Select markup type";
  NSString* footerTitle = @"Select the type of markup that you want to place on the board. The eraser lets you delete existing markup.";

  self.itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                               screenTitle:screenTitle
                                                        indexOfDefaultItem:indexOfDefaultItem
                                                                  delegate:self];
  self.itemPickerController.footerTitle = footerTitle;
  self.itemPickerController.itemPickerControllerMode = ItemPickerControllerModeNonModal;

  bool presentInPopover = ([LayoutManager sharedManager].uiType == UITypePad);

  if (! presentInPopover)
  {
    // In modal presentation style we display a "cancel" item to provide the
    // user with a means to cancel. To contrast: In popover presentation style
    // the means to cancel exists by simply tapping outside the popover.
    self.itemPickerController.displayCancelItem = true;
  }

  UIView* sourceView = nil;
  UIBarButtonItem* barButtonItem = nil;
  if ([sender isKindOfClass:[UIBarButtonItem class]])
  {
    sourceView = nil;
    barButtonItem = sender;
  }
  else if ([sender isKindOfClass:[UIButton class]])
  {
    sourceView = sender;
    barButtonItem = nil;
  }

  [self.viewControllerPresenterDelegate gameActionManager:self
        presentNavigationControllerWithRootViewController:self.itemPickerController
                                        usingPopoverStyle:presentInPopover
                                        popoverSourceView:sourceView
                                     popoverBarButtonItem:barButtonItem];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionDiscardAllMarkup.
// -----------------------------------------------------------------------------
- (void) discardAllMarkup:(id)sender
{
  [[[[DiscardAllMarkupCommand alloc] init] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionGameInfo.
// -----------------------------------------------------------------------------
- (void) gameInfo:(id)sender
{
  if ([ApplicationDelegate sharedDelegate].uiSettingsModel.uiAreaPlayMode != UIAreaPlayModeScoring)
  {
    GoScore* score = [GoGame sharedGame].score;
    [score calculateWaitUntilDone:true];
  }

  self.gameInfoViewController = [[[GameInfoViewController alloc] init] autorelease];
  [self.viewControllerPresenterDelegate gameActionManager:self
                                       pushViewController:self.gameInfoViewController];
  // Even though we can tell the presenter to dismiss the controller, we are not
  // in sole control of dismissal, i.e. there are other events that can cause
  // GameInfoViewController to be dismissed. One known example: The user taps
  // the "Play" tab bar icon (in layouts where a tab bar is used). When
  // GameInfoViewController is dismissed it is also deallocated, so we can get
  // a notification about that from the controller itself.
  self.gameInfoViewController.gameInfoViewControllerCreator = self;
}

// -----------------------------------------------------------------------------
/// @brief Handles execution of game action #GameActionMoreGameActions.
// -----------------------------------------------------------------------------
- (void) moreGameActions:(id)sender
{
  if ([self shouldIgnoreUserInteraction])
  {
    DDLogWarn(@"%@: Ignoring GameActionMoreGameActions", self);
    return;
  }

  UIViewController* modalMaster = [ApplicationDelegate sharedDelegate].window.rootViewController;
  self.moreGameActionsController = [[[MoreGameActionsController alloc] initWithModalMaster:modalMaster delegate:self] autorelease];

  if ([sender isKindOfClass:[UIBarButtonItem class]])
  {
    UIBarButtonItem* barButtonItem = sender;
    [self.moreGameActionsController showAlertMessageFromBarButtonItem:barButtonItem];
  }
  else if ([sender isKindOfClass:[UIButton class]])
  {
    UIButton* button = sender;
    [self.moreGameActionsController showAlertMessageFromRect:button.bounds inView:button];
  }
}

#pragma mark - MoreGameActionsControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief MoreGameActionsControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) moreGameActionsControllerDidFinish:(MoreGameActionsController*)controller
{
  self.moreGameActionsController = nil;
}

#pragma mark - GameInfoViewControllerCreator overrides

// -----------------------------------------------------------------------------
/// @brief GameInfoViewControllerCreator protocol method.
// -----------------------------------------------------------------------------
- (void) gameInfoViewControllerWillDeallocate:(GameInfoViewController*)gameInfoViewController
{
  self.gameInfoViewController = nil;
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    MarkupModel* markupModel = [ApplicationDelegate sharedDelegate].markupModel;
    if (markupModel.markupType != controller.indexOfSelectedItem)
      markupModel.markupType = controller.indexOfSelectedItem;
  }

  [self.viewControllerPresenterDelegate gameActionManager:self
        dismissNavigationControllerWithRootViewController:controller];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  // Dismiss the "Game Info" view when a new game is about to be started. This
  // typically occurs when a saved game is loaded from the archive.
  if (self.gameInfoViewController)
  {
    [self.viewControllerPresenterDelegate gameActionManager:self
                                          popViewController:self.gameInfoViewController];
  }
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  self.visibleStatesNeedUpdate = true;
  self.enabledStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  self.visibleStatesNeedUpdate = true;
  self.enabledStatesNeedUpdate = true;
  self.scoringModeNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  self.visibleStatesNeedUpdate = true;
  self.enabledStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #uiAreaPlayModeDidChange notification.
// -----------------------------------------------------------------------------
- (void) uiAreaPlayModeDidChange:(NSNotification*)notification
{
  self.visibleStatesNeedUpdate = true;
  self.enabledStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationStarts notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  self.enabledStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  [[ApplicationStateManager sharedManager] applicationStateDidChange];
  self.enabledStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewPanningGestureWillStart notification.
// -----------------------------------------------------------------------------
- (void) boardViewPanningGestureWillStart:(NSNotification*)notification
{
  self.enabledStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewPanningGestureWillEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewPanningGestureWillEnd:(NSNotification*)notification
{
  self.enabledStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #setupPointDidChange notification.
// -----------------------------------------------------------------------------
- (void) setupPointDidChange:(NSNotification*)notification
{
  self.visibleStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #allSetupStonesDidDiscard notification.
// -----------------------------------------------------------------------------
- (void) allSetupStonesDidDiscard:(NSNotification*)notification
{
  self.visibleStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationWillBegin notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationWillBegin:(NSNotification*)notification
{
  self.enabledStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationDidEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationDidEnd:(NSNotification*)notification
{
  self.enabledStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #markupOnPointsDidChange notification.
// -----------------------------------------------------------------------------
- (void) markupOnPointsDidChange:(NSNotification*)notification
{
  // Show/hide the "discard all markup" game action
  self.visibleStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #allMarkupDidDiscard notification.
// -----------------------------------------------------------------------------
- (void) allMarkupDidDiscard:(NSNotification*)notification
{
  // Show/hide the "discard all markup" game action
  self.visibleStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #currentBoardPositionDidChange notification.
// -----------------------------------------------------------------------------
- (void) currentBoardPositionDidChange:(NSNotification*)notification
{
  // It's annoying to have buttons appear and disappear all the time, so
  // we try to minimize this by keeping the same buttons in the navigation
  // bar while the user is browsing board positions.
  self.enabledStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #numberOfBoardPositionsDidChange notification.
// -----------------------------------------------------------------------------
- (void) numberOfBoardPositionsDidChange:(NSNotification*)notification
{
  self.visibleStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the
/// #UIApplicationWillChangeStatusBarOrientationNotification notification.
// -----------------------------------------------------------------------------
- (void) statusBarOrientationWillChange:(NSNotification*)notification
{
  // Dismiss any popover that is still visible because it will be wrongly
  // positioned after the interface has rotated
  if (self.moreGameActionsController)
  {
    [self.moreGameActionsController cancelAlertMessage];
  }
  else if (self.itemPickerController)
  {
    [self.viewControllerPresenterDelegate gameActionManager:self
          dismissNavigationControllerWithRootViewController:self.itemPickerController];
  }
}

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];

  if (object == appDelegate.boardSetupModel)
  {
    if ([keyPath isEqualToString:@"boardSetupStoneColor"])
    {
      self.visibleStatesNeedUpdate = true;
      [self delayedUpdate];
    }
  }
  else if (object == appDelegate.boardViewModel)
  {
    if ([keyPath isEqualToString:@"computerAssistanceType"])
    {
      self.visibleStatesNeedUpdate = true;
      [self delayedUpdate];
    }
  }
  else if (object == appDelegate.markupModel)
  {
    if ([keyPath isEqualToString:@"markupType"])
    {
      [self.uiDelegate gameActionManager:self updateIconOfGameAction:GameActionSelectMarkupType];
    }
    else if ([keyPath isEqualToString:@"selectedSymbolMarkupStyle"])
    {
      [self.uiDelegate gameActionManager:self updateIconOfGameAction:GameActionSelectMarkupType];
    }
  }
}

#pragma mark - Delayed updating

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. See class
/// documentation for details.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(delayedUpdate) withObject:nil waitUntilDone:YES];
    return;
  }
  [self updateVisibleStates];
  [self updateEnabledStates];
  [self updateScoringMode];
}

#pragma mark - Game action visibility updating

// -----------------------------------------------------------------------------
/// @brief Updates the visible states of game actions to match the current
/// application state.
// -----------------------------------------------------------------------------
- (void) updateVisibleStates
{
  if (! self.visibleStatesNeedUpdate)
    return;
  self.visibleStatesNeedUpdate = false;

  NSDictionary* visibleStates = [self visibleStatesOfGameActions];

  // During a long-running operation there may have been several visibility
  // state changes. Only the final visibility state counts, though, because
  // intermediate changes were delayed. The final visibility state may be the
  // same as the original visibility state, and that's what we check here.
  // In order for the equality check to be reliable, we need the arrays to have
  // the same sort order
  NSArray* visibleGameActions = [[visibleStates allKeys] sortedArrayUsingSelector:@selector(compare:)];
  if ([self.visibleGameActions isEqualToArray:visibleGameActions])
    return;

  self.visibleGameActions = visibleGameActions;
  if (self.uiDelegate)
  {
    [self.uiDelegate gameActionManager:self
                   updateVisibleStates:visibleStates];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateVisibleStates().
// -----------------------------------------------------------------------------
- (void) addGameAction:(enum GameAction)gameAction toVisibleStatesDictionary:(NSMutableDictionary*)visibleStates
{
  NSNumber* gameActionAsNumber = [NSNumber numberWithInt:gameAction];
  NSNumber* enabledAsNumber = self.enabledStates[gameActionAsNumber];
  visibleStates[gameActionAsNumber] = enabledAsNumber;
}

// -----------------------------------------------------------------------------
/// @brief Returns an NSDictionary that contains the game actions that are
/// currently visible, along with their enabled state.
///
/// The keys of the dictionary are NSNumber objects whose intValue returns a
/// value from the GameAction enumeration. They values of the dictionary are
/// NSNumber objects whose boolValue returns the enabled state of the game
/// action.
///
/// @see GameActionManagerUIDelegate gameActionManager:updateVisibleStates().
// -----------------------------------------------------------------------------
- (NSDictionary*) visibleStatesOfGameActions
{
  NSMutableDictionary* visibleStates = [NSMutableDictionary dictionary];

  [self addGameAction:GameActionGameInfo toVisibleStatesDictionary:visibleStates];
  [self addGameAction:GameActionMoreGameActions toVisibleStatesDictionary:visibleStates];

  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  UiSettingsModel* uiSettingsModel = appDelegate.uiSettingsModel;

  if (uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
  {
    [self addGameAction:GameActionPlayStart toVisibleStatesDictionary:visibleStates];
    if (boardPosition.numberOfBoardPositions > 1)
      [self addGameAction:GameActionDiscardBoardPosition toVisibleStatesDictionary:visibleStates];
  }
  else if (uiSettingsModel.uiAreaPlayMode == UIAreaPlayModePlay)
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
      {
        if (GoGameStateGameIsPaused == game.state)
        {
          if (GoGameComputerIsThinkingReasonPlayerInfluence != game.reasonForComputerIsThinking)
            [self addGameAction:GameActionContinue toVisibleStatesDictionary:visibleStates];
        }
        else
        {
          if (GoGameStateGameHasEnded == game.state)
            [self addGameAction:GameActionScoringStart toVisibleStatesDictionary:visibleStates];
          else
            [self addGameAction:GameActionPause toVisibleStatesDictionary:visibleStates];
        }
        if (game.isComputerThinking)
        {
          [self addGameAction:GameActionInterrupt toVisibleStatesDictionary:visibleStates];
        }
        else
        {
          if (boardPosition.numberOfBoardPositions > 1)
            [self addGameAction:GameActionDiscardBoardPosition toVisibleStatesDictionary:visibleStates];
        }
        break;
      }
      default:
      {
        if (game.isComputerThinking)
        {
          [self addGameAction:GameActionInterrupt toVisibleStatesDictionary:visibleStates];
        }
        else
        {
          if (GoGameStateGameHasEnded == game.state)
          {
            [self addGameAction:GameActionScoringStart toVisibleStatesDictionary:visibleStates];
          }
          else
          {
            switch (appDelegate.boardViewModel.computerAssistanceType)
            {
              case ComputerAssistanceTypePlayForMe:
                [self addGameAction:GameActionComputerPlay toVisibleStatesDictionary:visibleStates];
                break;
              case ComputerAssistanceTypeSuggestMove:
                [self addGameAction:GameActionComputerSuggestMove toVisibleStatesDictionary:visibleStates];
                break;
              case ComputerAssistanceTypeNone:
                break;
              default:
                assert(0);
                break;
            }

            [self addGameAction:GameActionPass toVisibleStatesDictionary:visibleStates];
          }
          if (boardPosition.numberOfBoardPositions > 1)
            [self addGameAction:GameActionDiscardBoardPosition toVisibleStatesDictionary:visibleStates];
        }
        break;
      }
    }
  }
  else if (uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeBoardSetup)
  {
    [self addGameAction:GameActionPlayStart toVisibleStatesDictionary:visibleStates];

    BoardSetupModel* boardSetupModel = appDelegate.boardSetupModel;
    if (boardSetupModel.boardSetupStoneColor == GoColorBlack)
      [self addGameAction:GameActionSwitchSetupStoneColorToWhite toVisibleStatesDictionary:visibleStates];
    else
      [self addGameAction:GameActionSwitchSetupStoneColorToBlack toVisibleStatesDictionary:visibleStates];

    // TODO xxx The game action is no longer "discard all setup stones" but "discard all setup". This includes setupFirstMoveColor.
    GoNodeSetup* nodeSetup = game.boardPosition.currentNode.goNodeSetup;
    if (nodeSetup && ! nodeSetup.isEmpty)
      [self addGameAction:GameActionDiscardAllSetupStones toVisibleStatesDictionary:visibleStates];
  }
  else if (uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeEditMarkup)
  {
    [self addGameAction:GameActionPlayStart toVisibleStatesDictionary:visibleStates];
    [self addGameAction:GameActionSelectMarkupType toVisibleStatesDictionary:visibleStates];

    GoNodeMarkup* nodeMarkup = boardPosition.currentNode.goNodeMarkup;
    if (nodeMarkup && nodeMarkup.hasMarkup)
      [self addGameAction:GameActionDiscardAllMarkup toVisibleStatesDictionary:visibleStates];
  }

  return visibleStates;
}

#pragma mark - Game action enabled state updating

// -----------------------------------------------------------------------------
/// @brief Updates the enabled states of all game actions (regardless of their
/// current visible state).
// -----------------------------------------------------------------------------
- (void) updateEnabledStates
{
  if (! self.enabledStatesNeedUpdate)
    return;
  self.enabledStatesNeedUpdate = false;

  [self updatePassEnabledState];
  [self updateDiscardBoardPositionEnabledState];
  [self updateComputerPlayEnabledState];
  [self updateComputerSuggestMoveEnabledState];
  [self updatePauseEnabledState];
  [self updateContinueEnabledState];
  [self updateInterruptEnabledState];
  [self updateScoringStartEnabledState];
  [self updatePlayStartEnabledState];
  [self updateSwitchSetupStoneColorToWhiteEnabledState];
  [self updateSwitchSetupStoneColorToBlackEnabledState];
  [self updateGameActionDiscardAllSetupStonesEnabledState];
  [self updateGameActionSelectMarkupTypeEnabledState];
  [self updateGameActionDiscardAllMarkupEnabledState];
  [self updateGameInfoEnabledState];
  [self updateMoreGameActionsEnabledState];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action #GameActionPass.
// -----------------------------------------------------------------------------
- (void) updatePassEnabledState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.uiSettingsModel.uiAreaPlayMode == UIAreaPlayModePlay &&
      ! appDelegate.boardViewModel.boardViewPanningGestureIsInProgress &&
      ! appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
        break;
      default:
      {
        if (game.isComputerThinking)
          break;
        switch (game.state)
        {
          case GoGameStateGameHasStarted:
          {
            if (game.nextMovePlayerIsComputerPlayer)
              enabled = NO;
            else
              enabled = YES;
            break;
          }
          default:
            break;
        }
        break;
      }
    }
  }
  [self updateEnabledState:enabled forGameAction:GameActionPass];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action
/// #GameActionDiscardBoardPosition.
// -----------------------------------------------------------------------------
- (void) updateDiscardBoardPositionEnabledState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.boardViewModel.boardViewPanningGestureIsInProgress ||
      appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    // always disabled
  }
  else if (appDelegate.uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
  {
    if (! game.score.scoringInProgress)
      enabled = YES;
  }
  else
  {
    if (! game.isComputerThinking)
      enabled = YES;
  }
  [self updateEnabledState:enabled forGameAction:GameActionDiscardBoardPosition];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action #GameActionComputerPlay.
// -----------------------------------------------------------------------------
- (void) updateComputerPlayEnabledState
{
  [self updateComputerPlayOrSuggestMoveEnabledState:GameActionComputerPlay];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action
/// #GameActionComputerSuggestMove.
// -----------------------------------------------------------------------------
- (void) updateComputerSuggestMoveEnabledState
{
  [self updateComputerPlayOrSuggestMoveEnabledState:GameActionComputerSuggestMove];
}

// -----------------------------------------------------------------------------
/// @brief Helper for updateComputerPlayEnabledState() and
/// updateComputerSuggestMoveEnabledState(). The two game actions have
/// identical enabled/disabled criteria.
// -----------------------------------------------------------------------------
- (void) updateComputerPlayOrSuggestMoveEnabledState:(enum GameAction)gameAction
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.uiSettingsModel.uiAreaPlayMode == UIAreaPlayModePlay &&
      ! appDelegate.boardViewModel.boardViewPanningGestureIsInProgress &&
      ! appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
        break;
      default:
      {
        if (game.isComputerThinking)
          break;
        switch (game.state)
        {
          case GoGameStateGameHasStarted:
          {
            enabled = YES;
            break;
          }
          default:
            break;
        }
        break;
      }
    }
  }
  [self updateEnabledState:enabled forGameAction:gameAction];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action #GameActionPause.
// -----------------------------------------------------------------------------
- (void) updatePauseEnabledState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.uiSettingsModel.uiAreaPlayMode == UIAreaPlayModePlay &&
      ! appDelegate.boardViewModel.boardViewPanningGestureIsInProgress &&
      ! appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
      {
        switch (game.state)
        {
          case GoGameStateGameHasStarted:
            enabled = YES;
            break;
          default:
            break;
        }
        break;
      }
      default:
        break;
    }
  }
  [self updateEnabledState:enabled forGameAction:GameActionPause];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action #GameActionContinue.
// -----------------------------------------------------------------------------
- (void) updateContinueEnabledState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.uiSettingsModel.uiAreaPlayMode == UIAreaPlayModePlay &&
      ! appDelegate.boardViewModel.boardViewPanningGestureIsInProgress &&
      ! appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
      {
        switch (game.state)
        {
          case GoGameStateGameIsPaused:
            enabled = YES;
            break;
          default:
            break;
        }
        break;
      }
      default:
        break;
    }
  }
  [self updateEnabledState:enabled forGameAction:GameActionContinue];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action #GameActionInterrupt.
// -----------------------------------------------------------------------------
- (void) updateInterruptEnabledState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.boardViewModel.boardViewPanningGestureIsInProgress ||
      appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    // always disabled
  }
  else if ([ApplicationDelegate sharedDelegate].uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
  {
    if (game.score.scoringInProgress)
      enabled = YES;
  }
  else
  {
    if (game.isComputerThinking)
      enabled = YES;
  }
  [self updateEnabledState:enabled forGameAction:GameActionInterrupt];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action #GameActionScoringStart.
// -----------------------------------------------------------------------------
- (void) updateScoringStartEnabledState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeScoring ||
      game.isComputerThinking ||
      appDelegate.boardViewModel.boardViewPanningGestureIsInProgress ||
      appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    // always disabled
  }
  else
  {
    enabled = YES;
  }
  [self updateEnabledState:enabled forGameAction:GameActionScoringStart];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action #GameActionPlayStart.
// -----------------------------------------------------------------------------
- (void) updatePlayStartEnabledState
{
  BOOL enabled = NO;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    // always disabled
  }
  else
  {
    UiSettingsModel* uiSettingsModel = appDelegate.uiSettingsModel;
    switch (uiSettingsModel.uiAreaPlayMode)
    {
      case UIAreaPlayModeScoring:
      {
        GoGame* game = [GoGame sharedGame];
        if (! game.score.scoringInProgress)
          enabled = YES;
        break;
      }
      case UIAreaPlayModeBoardSetup:
      case UIAreaPlayModeEditMarkup:
      {
        enabled = YES;
        break;
      }
      default:
      {
        break;
      }
    }
  }

  [self updateEnabledState:enabled forGameAction:GameActionPlayStart];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action
/// #GameActionSwitchSetupStoneColorToWhite.
// -----------------------------------------------------------------------------
- (void) updateSwitchSetupStoneColorToWhiteEnabledState
{
  BOOL enabled = YES;
  [self updateEnabledState:enabled forGameAction:GameActionSwitchSetupStoneColorToWhite];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action
/// #GameActionSwitchSetupStoneColorToBlack.
// -----------------------------------------------------------------------------
- (void) updateSwitchSetupStoneColorToBlackEnabledState
{
  BOOL enabled = YES;
  [self updateEnabledState:enabled forGameAction:GameActionSwitchSetupStoneColorToBlack];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action
/// #GameActionDiscardAllSetupStones.
// -----------------------------------------------------------------------------
- (void) updateGameActionDiscardAllSetupStonesEnabledState
{
  BOOL enabled = NO;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.boardViewModel.boardViewPanningGestureIsInProgress ||
      appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    // always disabled
  }
  else
  {
    enabled = YES;
  }

  [self updateEnabledState:enabled forGameAction:GameActionDiscardAllSetupStones];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action #GameActionSelectMarkupType.
// -----------------------------------------------------------------------------
- (void) updateGameActionSelectMarkupTypeEnabledState
{
  BOOL enabled = YES;
  [self updateEnabledState:enabled forGameAction:GameActionSelectMarkupType];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action #GameActionDiscardAllMarkup.
// -----------------------------------------------------------------------------
- (void) updateGameActionDiscardAllMarkupEnabledState
{
  BOOL enabled = YES;
  [self updateEnabledState:enabled forGameAction:GameActionDiscardAllMarkup];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action #GameActionGameInfo.
// -----------------------------------------------------------------------------
- (void) updateGameInfoEnabledState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.boardViewModel.boardViewPanningGestureIsInProgress ||
      appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    // always disabled
  }
  else if (appDelegate.uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
  {
    if (! game.score.scoringInProgress)
      enabled = YES;
  }
  else
  {
    // It is important that the Game Info view cannot be displayed if the
    // computer is still thinking. Reason: When the computer has finished
    // thinking, some piece of game state will change. GameInfoViewController,
    // however, is not equipped to update its information dynamically. At best,
    // the Game Info view will display outdated information. At worst, the app
    // will crash - an actual case was issue #226, where the app crashed because
    // - The game ended while the Game Info view was visible
    // - GameInfoViewController reloaded some table view rows in reaction to
    //   user input on the Game Info view
    // - An unrelated table view section suddenly had a different number of
    //   rows (because the game had ended), causing UITableView to throw an
    //   exception
    if (! game.computerThinks)
      enabled = YES;
  }
  [self updateEnabledState:enabled forGameAction:GameActionGameInfo];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of game action #GameActionMoreGameActions.
// -----------------------------------------------------------------------------
- (void) updateMoreGameActionsEnabledState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (game.isComputerThinking ||
      appDelegate.boardViewModel.boardViewPanningGestureIsInProgress ||
      appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    // always disabled
  }
  else if (appDelegate.uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
  {
    if (! game.score.scoringInProgress)
      enabled = YES;
  }
  else
  {
    enabled = YES;
  }
  [self updateEnabledState:enabled forGameAction:GameActionMoreGameActions];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the specified game action to
/// @a newState. Notifies the UI delegate only if the new state is different
/// from the current state.
// -----------------------------------------------------------------------------
- (void) updateEnabledState:(BOOL)newState forGameAction:(enum GameAction)gameAction
{
  NSNumber* key = [NSNumber numberWithInt:gameAction];
  BOOL currentState = [[self.enabledStates objectForKey:key] boolValue];
  if (currentState == newState)
    return;
  [self.enabledStates setObject:[NSNumber numberWithBool:newState] forKey:key];
  [self.uiDelegate gameActionManager:self
                              enable:newState
                          gameAction:gameAction];
}

// -----------------------------------------------------------------------------
/// @brief Enables scoring mode if the current game state requires it.
// -----------------------------------------------------------------------------
- (void) updateScoringMode
{
  if (! self.scoringModeNeedUpdate)
    return;
  self.scoringModeNeedUpdate = false;

  [self autoEnableScoringIfNecessary];
}

#pragma mark - Auto scoring & resuming play

// -----------------------------------------------------------------------------
/// @brief Enables scoring mode if the user preferences and the current game
/// state allow it.
// -----------------------------------------------------------------------------
- (void) autoEnableScoringIfNecessary
{
  if (! [ApplicationDelegate sharedDelegate].scoringModel.autoScoringAndResumingPlay)
    return;
  GoGame* game = [GoGame sharedGame];
  if (GoGameStateGameHasEnded != game.state)
    return;
  // Only trigger scoring if it makes sense to do so. It specifically does
  // not make sense in the following cases:
  // - If a player resigned - that player has lost the game by his own
  //   explicit action, so we don't need to calculate a score.
  //
  // Possibly controversial: If the game ended due to four passes, all stones
  // are deemed alive. Although no life & death settling is required in this
  // case, we still activate scoring mode so that the user sees a result in the
  // status view.
  switch (game.reasonForGameHasEnded)
  {
    case GoGameHasEndedReasonTwoPasses:
    case GoGameHasEndedReasonThreePasses:
    case GoGameHasEndedReasonFourPasses:
      break;
    default:
      return;
  }

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[[[ChangeUIAreaPlayModeCommand alloc] initWithUIAreaPlayMode:UIAreaPlayModeScoring] autorelease] submit];
  }
  @finally
  {
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
  }
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if user interaction that triggers a game action should
/// currently be ignored.
// -----------------------------------------------------------------------------
- (bool) shouldIgnoreUserInteraction
{
  return [GoGame sharedGame].isComputerThinking;
}

@end
