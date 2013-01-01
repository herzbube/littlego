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
#import "StatusLineController.h"
#import "ScoringModel.h"
#import "PlayView.h"
#import "../main/ApplicationDelegate.h"
#import "../go/GoGame.h"
#import "../go/GoMove.h"
#import "../go/GoPlayer.h"
#import "../go/GoPoint.h"
#import "../go/GoScore.h"
#import "../go/GoVertex.h"
#import "../player/Player.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for StatusLineController.
// -----------------------------------------------------------------------------
@interface StatusLineController()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
/// @name GUI updating
//@{
- (void) updateStatusLine;
//@}
/// @name Notification responders
//@{
- (void) goGameWillCreate:(NSNotification*)notification;
- (void) goGameDidCreate:(NSNotification*)notification;
- (void) goGameStateChanged:(NSNotification*)notification;
- (void) computerPlayerThinkingChanged:(NSNotification*)notification;
- (void) goScoreScoringModeDisabled:(NSNotification*)notification;
- (void) goScoreCalculationStarts:(NSNotification*)notification;
- (void) goScoreCalculationEnds:(NSNotification*)notification;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) UILabel* statusLine;
@property(nonatomic, assign) ScoringModel* scoringModel;
//@}
@end


@implementation StatusLineController

@synthesize statusLine;
@synthesize scoringModel;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an StatusLineController instance
/// that manages @a statusLine.
// -----------------------------------------------------------------------------
+ (StatusLineController*) controllerWithStatusLine:(UILabel*)statusLine
{
  StatusLineController* controller = [[StatusLineController alloc] init];
  if (controller)
  {
    [controller autorelease];
    controller.statusLine = statusLine;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an StatusLineController object.
///
/// @note This is the designated initializer of StatusLineController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.statusLine = nil;

  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  self.scoringModel = delegate.scoringModel;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goScoreScoringModeDisabled:) name:goScoreScoringModeDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  // KVO observing
  [[PlayView sharedView] addObserver:self forKeyPath:@"crossHairPoint" options:0 context:NULL];
  [[GoGame sharedGame].boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[PlayView sharedView] removeObserver:self forKeyPath:@"crossHairPoint"];
  [[GoGame sharedGame].boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  self.statusLine = nil;
  self.scoringModel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Updates the status line with text that provides feedback to the user
/// about what's going on.
// -----------------------------------------------------------------------------
- (void) updateStatusLine
{
  NSString* statusText = @"";

  PlayView* playView = [PlayView sharedView];
  if (playView.crossHairPoint)
  {
    statusText = playView.crossHairPoint.vertex.string;
    if (! playView.crossHairPointIsLegalMove)
      statusText = [statusText stringByAppendingString:@" - You can't play there"];
  }
  else
  {
    GoGame* game = [GoGame sharedGame];
    if (game.isComputerThinking)
    {
      switch (game.state)
      {
        case GoGameStateGameHasNotYetStarted:  // game state is set to started only after the GTP response is received
        case GoGameStateGameHasStarted:
        case GoGameStateGameIsPaused:          // although game is paused, computer may still be thinking
          statusText = [game.currentPlayer.player.name stringByAppendingString:@" is thinking..."];
          break;
        default:
          break;
      }
    }
    else
    {
      if (self.scoringModel.scoringMode)
      {
        if (self.scoringModel.score.scoringInProgress)
          statusText = @"Scoring in progress...";
        else
          statusText = [NSString stringWithFormat:@"%@. Tap to mark dead stones.", [self.scoringModel.score resultString]];
      }
      else
      {
        switch (game.state)
        {
          case GoGameStateGameHasNotYetStarted:  // game state is set to started only after the GTP response is received
          case GoGameStateGameHasStarted:
          {
            GoMove* lastMove = game.lastMove;
            if (GoMoveTypePass == lastMove.type)
            {
              // TODO fix when GoColor class is added
              NSString* color;
              if (lastMove.player.black)
                color = @"Black";
              else
                color = @"White";
              statusText = [NSString stringWithFormat:@"%@ has passed", color];
            }
            break;
          }
          case GoGameStateGameHasEnded:
          {
            switch (game.reasonForGameHasEnded)
            {
              case GoGameHasEndedReasonTwoPasses:
              {
                statusText = @"Game has ended by two consecutive pass moves";
                break;
              }
              case GoGameHasEndedReasonResigned:
              {
                NSString* color;
                // TODO fix when GoColor class is added
                if (game.currentPlayer.black)
                  color = @"Black";
                else
                  color = @"White";
                statusText = [NSString stringWithFormat:@"Game has ended by resigning, %@ resigned", color];
                break;
              }
              default:
                break;
            }
            break;
          }
          default:
            break;
        }
      }
    }
  }

  self.statusLine.text = statusText;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  [oldGame.boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  [newGame.boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  [self updateStatusLine];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  [self updateStatusLine];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringModeDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeDisabled:(NSNotification*)notification
{
  // Need this to remove score summary message
  [self updateStatusLine];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationStarts notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  [self updateStatusLine];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  [self updateStatusLine];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  [self updateStatusLine];
}

@end
