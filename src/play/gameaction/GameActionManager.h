// -----------------------------------------------------------------------------
// Copyright 2015-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameInfoViewController.h"
#import "../controller/MoreGameActionsController.h"
#import "../../ui/ItemPickerController.h"

// Forward declarations
@class GameActionManager;
@class CommandBase;
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The UI delegate of GameActionManager must adopt the
/// GameActionManagerUIDelegate protocol. The UI delegate is responsible for
/// managing the UI representation of game actions.
// -----------------------------------------------------------------------------
@protocol GameActionManagerUIDelegate
@required
/// @brief The delegate must make sure that only those game actions listed in
/// @a gameActions are visible. The dictionary has the same structure as the
/// one returned by GameActionManager's visibleStatesOfGameActions().
- (void) gameActionManager:(GameActionManager*)manager
       updateVisibleStates:(NSDictionary*)gameActions;
/// @brief The delegate must enable or disable the UI element that corresponds
/// to @a gameAction, according to the value of @a enable.
- (void) gameActionManager:(GameActionManager*)manager
                    enable:(BOOL)enable
                gameAction:(enum GameAction)gameAction;
/// @brief The delegate must update the icon of the UI element that corresponds
/// to @a gameAction.
- (void) gameActionManager:(GameActionManager*)manager
    updateIconOfGameAction:(enum GameAction)gameAction;
@end

// -----------------------------------------------------------------------------
/// @brief The command delegate of GameActionManager must adopt the
/// GameActionManagerCommandDelegate protocol. The command delegate is
/// responsible for handling the execution of certain commands. This handling
/// includes the possible display of an alert which the user must confirm before
/// the command is actually executed.
// -----------------------------------------------------------------------------
@protocol GameActionManagerCommandDelegate
/// @brief This method is invoked when the user attempts to play a move. The
/// delegate executes @a command, possibly displaying an alert first which the
/// user must confirm.
- (void) gameActionManager:(GameActionManager*)manager playOrAlertWithCommand:(CommandBase*)command;
/// @brief This method is invoked when the user attempts to discard board
/// positions. The delegate executes @a command, possibly displaying an alert
/// first which the user must confirm.
- (void) gameActionManager:(GameActionManager*)manager discardOrAlertWithCommand:(CommandBase*)command;
@end

// -----------------------------------------------------------------------------
/// @brief The GameActionManagerViewControllerPresenterDelegate protocol lets
/// GameActionManager delegate the details of presenting and dismissing view
/// controllers, while keeping control over when these operations take place.
///
/// The presenter does not need to know the specific type of the
/// GameInfoViewController, so GameActionManager uses the base class type
/// UIViewController to pass the view controller object to the presenter.
// -----------------------------------------------------------------------------
@protocol GameActionManagerViewControllerPresenterDelegate
- (void) gameActionManager:(GameActionManager*)gameActionManager
        pushViewController:(UIViewController*)viewController;
- (void) gameActionManager:(GameActionManager*)gameActionManager
         popViewController:(UIViewController*)viewController;
                       - (void) gameActionManager:(GameActionManager*)gameActionManager
presentNavigationControllerWithRootViewController:(UIViewController*)rootViewController
                                usingPopoverStyle:(bool)usePopoverStyle
                                popoverSourceView:(UIView*)sourceView
                             popoverBarButtonItem:(UIBarButtonItem*)barButtonItem;
                       - (void) gameActionManager:(GameActionManager*)gameActionManager
dismissNavigationControllerWithRootViewController:(UIViewController*)rootViewController;
@end


// -----------------------------------------------------------------------------
/// @brief The GameActionManager class defines an abstract set of game actions
/// (e.g. "pass"). GameActionManager also defines the behaviour of these actions
/// (i.e. what they do) and when they are available. In addition,
/// GameActionManager provides handlers for some interactions with the board.
///
/// GameActionManager requires a third party - the so-called "UI delegate" - to
/// provide a visual representation of the actions it manages. UIControls such
/// as UIButton are commonly used for this. GameActionManager provides action
/// handler methods that can easily be connected to the corresponding
/// UIControls' actions.
///
/// GameActionManager observes the application state to determine when each
/// game action should be available. GameActionManager distinguishes between
/// two forms of making a game action available: Showing/hiding the visual
/// representation, and enabling/disabling touch interaction with the visual
/// representation. GameActionManager informs its UI delegate when one of these
/// state changes is required.
///
/// For some of the game actions GameActionManager delegates the handling of
/// command execution to a so-called "command delegate". This handling includes
/// the possible display of an alert which the user must confirm before the
/// command is actually executed.
// -----------------------------------------------------------------------------
@interface GameActionManager : NSObject <MoreGameActionsControllerDelegate, GameInfoViewControllerCreator, ItemPickerDelegate>
{
}

+ (GameActionManager*) sharedGameActionManager;
+ (void) releaseSharedGameActionManager;
+ (SEL) handlerForGameAction:(enum GameAction)gameAction;

- (void) playAtIntersection:(GoPoint*)point;
- (void) toggleScoringStateOfStoneGroupAtIntersection:(GoPoint*)point;
- (void) handleBoardSetupAtIntersection:(GoPoint*)point;
- (void) handleSetupFirstMove:(enum GoColor)firstMoveColor;
- (void) handleMarkupEditingAtIntersection:(GoPoint*)point
                                markupTool:(enum MarkupTool)markupTool
                                markupType:(enum MarkupType)markupType
                            markupWasMoved:(bool)markupWasMoved;
- (void) placeMarkupSymbol:(enum GoMarkupSymbol)symbol
                   atPoint:(GoPoint*)point
            markupWasMoved:(bool)markupWasMoved;
- (void) placeMarkupConnection:(enum GoMarkupConnection)connection
                     fromPoint:(GoPoint*)fromPoint
                       toPoint:(GoPoint*)toPoint
                markupWasMoved:(bool)markupWasMoved;
- (void) placeMarkupLabel:(enum GoMarkupLabel)label
            withLabelText:(NSString*)labelText
                  atPoint:(GoPoint*)point
           markupWasMoved:(bool)markupWasMoved;
- (void) eraseMarkupInRectangleFromPoint:(GoPoint*)fromPoint toPoint:(GoPoint*)toPoint;

- (void) pass:(id)sender;
- (void) discardBoardPosition:(id)sender;
- (void) computerPlay:(id)sender;
- (void) computerSuggestMove:(id)sender;
- (void) pause:(id)sender;
- (void) continue:(id)sender;
- (void) interrupt:(id)sender;
- (void) scoringStart:(id)sender;
- (void) playStart:(id)sender;
- (void) switchSetupStoneColorToWhite:(id)sender;
- (void) switchSetupStoneColorToBlack:(id)sender;
- (void) discardAllSetupStones:(id)sender;
- (void) selectMarkupType:(id)sender;
- (void) discardAllMarkup:(id)sender;
- (void) gameInfo:(id)sender;
- (void) moreGameActions:(id)sender;

- (NSDictionary*) visibleStatesOfGameActions;

@property(nonatomic, assign) id<GameActionManagerUIDelegate> uiDelegate;
@property(nonatomic, assign) id<GameActionManagerCommandDelegate> commandDelegate;
@property(nonatomic, assign) id<GameActionManagerViewControllerPresenterDelegate> viewControllerPresenterDelegate;

@end
