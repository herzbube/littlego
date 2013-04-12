// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "StatusViewController.h"
#import "../PlayView.h"
#import "../model/ScoringModel.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoScore.h"
#import "../../go/GoVertex.h"
#import "../../player/Player.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for StatusViewController.
// -----------------------------------------------------------------------------
@interface StatusViewController()
/// @name Privately declared properties
//@{
@property(nonatomic, assign) UILabel* statusLabel;
@property(nonatomic, assign) UIActivityIndicatorView* activityIndicator;
@property(nonatomic, assign) PlayView* playView;
@property(nonatomic, assign) ScoringModel* scoringModel;
@property(nonatomic, assign) int actionsInProgress;
@property(nonatomic, assign) bool activityIndicatorNeedsUpdate;
@property(nonatomic, assign) bool viewLayoutNeedsUpdate;
@property(nonatomic, assign) bool statusLabelNeedsUpdate;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) UIView* statusView;
//@}
@end


@implementation StatusViewController

// -----------------------------------------------------------------------------
/// @brief Initializes a StatusViewController object.
///
/// @note This is the designated initializer of StatusViewController.
// -----------------------------------------------------------------------------
- (id) initWithPlayView:(PlayView*)playView scoringModel:(ScoringModel*)scoringModel
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.playView = playView;
  self.scoringModel = scoringModel;
  self.actionsInProgress = 0;
  self.activityIndicatorNeedsUpdate = false;
  self.viewLayoutNeedsUpdate = false;
  self.statusLabelNeedsUpdate = false;
  [self setupView];
  [self setupNotificationResponders];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.playView removeObserver:self forKeyPath:@"crossHairPoint"];
  [[GoGame sharedGame].boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  self.statusView = nil;
  self.statusLabel = nil;
  self.activityIndicator = nil;
  self.playView = nil;
  self.scoringModel = nil;
  [super dealloc];
}

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
  [center addObserver:self selector:@selector(goScoreScoringModeDisabled:) name:goScoreScoringModeDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(askGtpEngineForDeadStonesStarts:) name:askGtpEngineForDeadStonesStarts object:nil];
  [center addObserver:self selector:@selector(askGtpEngineForDeadStonesEnds:) name:askGtpEngineForDeadStonesEnds object:nil];
  [center addObserver:self selector:@selector(longRunningActionStarts:) name:longRunningActionStarts object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  [self.playView addObserver:self forKeyPath:@"crossHairPoint" options:0 context:NULL];
  [[GoGame sharedGame].boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupView
{
  self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.statusLabel.numberOfLines = 3;
  self.statusLabel.font = [UIFont systemFontOfSize:10];
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    self.statusLabel.textColor = [UIColor whiteColor];
  else
    self.statusLabel.textColor = [UIColor blackColor];
  self.statusLabel.backgroundColor = [UIColor clearColor];
  self.statusLabel.lineBreakMode = UILineBreakModeWordWrap;
  self.statusLabel.textAlignment = NSTextAlignmentCenter;
  // Give the view its proper height. The width will later change depending on
  // how much space the view gets within the navigation bar
  self.statusLabel.text = @"line 1\nline 2\nline 3";
  [self.statusLabel sizeToFit];
  self.statusLabel.text = nil;

  CGRect activityIndicatorFrame;
  activityIndicatorFrame.size.width = [UiElementMetrics activityIndicatorWidthAndHeight];
  activityIndicatorFrame.size.height = [UiElementMetrics activityIndicatorWidthAndHeight];
  activityIndicatorFrame.origin.x = CGRectGetMaxX(self.statusLabel.frame);
  activityIndicatorFrame.origin.y = (self.statusLabel.frame.size.height - activityIndicatorFrame.size.height) / 2;
  self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:activityIndicatorFrame] autorelease];
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
  else
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
  self.activityIndicator.hidden = YES;

  // The activity indicator is initially hidden, so we can use the label size
  // for the initial frame
  self.statusView = [[[UIView alloc] initWithFrame:self.statusLabel.bounds] autorelease];
  [self.statusView addSubview:self.statusLabel];
  [self.statusView addSubview:self.activityIndicator];
  // Don't use self, we don't want to trigger the setter
  _statusViewWidth = self.statusView.frame.size.width;
}

// -----------------------------------------------------------------------------
/// @brief Updates the status view frame with the new width. May also adjust
/// the text, i.e. make it longer or shorter depending on the new width.
// -----------------------------------------------------------------------------
- (void) setStatusViewWidth:(int)newWidth
{
  if (self.statusViewWidth == newWidth)
    return;
  _statusViewWidth = newWidth;
  CGRect frame = self.statusView.frame;
  frame.size.width = self.statusViewWidth;
  self.statusView.frame = frame;

  self.viewLayoutNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. See class
/// documentation for details.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if (self.actionsInProgress > 0)
    return;
  [self updateStatusView];
}

// -----------------------------------------------------------------------------
/// @brief Updates the status view with text that provides feedback to the user
/// about what's going on. Also starts/stops animating the activity indicator.
// -----------------------------------------------------------------------------
- (void) updateStatusView
{
  [self updateActivityIndicator];  // invoke before updateViewLayout, may trigger a view layout update
  [self updateViewLayout];
  [self updateStatusLabel];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateStatusView.
// -----------------------------------------------------------------------------
- (void) updateActivityIndicator
{
  if (! self.activityIndicatorNeedsUpdate)
    return;
  self.activityIndicatorNeedsUpdate = false;

  bool activityIndicatorShouldAnimate = false;
  if (self.scoringModel.scoringMode)
  {
    if (self.scoringModel.score.askGtpEngineForDeadStonesInProgress)
      activityIndicatorShouldAnimate = true;
    else
      activityIndicatorShouldAnimate = false;
  }
  else
  {
    if ([[GoGame sharedGame] isComputerThinking])
      activityIndicatorShouldAnimate = true;
    else
      activityIndicatorShouldAnimate = false;
  }

  if (activityIndicatorShouldAnimate)
  {
    if (! self.activityIndicator.isAnimating)
    {
      [self.activityIndicator startAnimating];
      self.activityIndicator.hidden = NO;
      self.viewLayoutNeedsUpdate = true;
    }
  }
  else
  {
    if (self.activityIndicator.isAnimating)
    {
      [self.activityIndicator stopAnimating];
      self.activityIndicator.hidden = YES;
      self.viewLayoutNeedsUpdate = true;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateStatusView.
// -----------------------------------------------------------------------------
- (void) updateViewLayout
{
  if (! self.viewLayoutNeedsUpdate)
    return;
  self.viewLayoutNeedsUpdate = false;

  CGRect statusLabelFrame = self.statusLabel.frame;
  if (self.activityIndicator.hidden)
    statusLabelFrame.size.width = self.statusView.frame.size.width;
  else
    statusLabelFrame.size.width = self.statusView.frame.size.width - self.activityIndicator.frame.size.width;
  self.statusLabel.frame = statusLabelFrame;

  CGRect activityIndicatorFrame = self.activityIndicator.frame;
  activityIndicatorFrame.origin.x = CGRectGetMaxX(statusLabelFrame);
  self.activityIndicator.frame = activityIndicatorFrame;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateStatusView.
// -----------------------------------------------------------------------------
- (void) updateStatusLabel
{
  if (! self.statusLabelNeedsUpdate)
    return;
  self.statusLabelNeedsUpdate = false;

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
        {
          NSString* playerName = game.currentPlayer.player.name;
          if (game.isComputerPlayersTurn)
            statusText = [playerName stringByAppendingString:@" is thinking..."];
          else
            statusText = [NSString stringWithFormat:@"Computer is playing for %@...", playerName];
          break;
        }
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
          statusText = [NSString stringWithFormat:@"%@ - Tap to mark dead stones", [self.scoringModel.score resultString]];
      }
      else
      {
        switch (game.state)
        {
          case GoGameStateGameHasNotYetStarted:  // game state is set to started only after the GTP response is received
          case GoGameStateGameHasStarted:
          {
            GoMove* move = game.boardPosition.currentMove;
            if (GoMoveTypePass == move.type)
            {
              // TODO fix when GoColor class is added
              NSString* color;
              if (move.player.black)
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
  self.statusLabel.text = statusText;
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
  // In case a new game is started abruptly without cleaning up state in the
  // old game
  self.activityIndicatorNeedsUpdate = true;
  // We don't get a goGameStateChanged because the old game is deallocated
  // without a state change, and the new game already starts with its correct
  // initial state
  self.statusLabelNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  self.statusLabelNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  self.activityIndicatorNeedsUpdate = true;
  self.statusLabelNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringModeDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeDisabled:(NSNotification*)notification
{
  // Need this to remove score summary message
  self.statusLabelNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  // No activity indicator update here, this is handled by
  // askGtpEngineForDeadStonesEnds because the notification is optional.
  self.statusLabelNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #askGtpEngineForDeadStonesStarts notifications.
// -----------------------------------------------------------------------------
- (void) askGtpEngineForDeadStonesStarts:(NSNotification*)notification
{
  self.activityIndicatorNeedsUpdate = true;
  // The activity indicator is displayed long enough so that it's worth to
  // display a status message. Note that we don't display a message if only
  // goScoreCalculationStarts is received, but no
  // askGtpEngineForDeadStonesStarts is received. The reason is that the actual
  // score calculations is quite fast, even on an older device such as an
  // iPhone 3GS, so an update for goScoreCalculationStarts would be followed
  // almost immediately by another update for goScoreCalculationEnds, which
  // might cause flickering.
  self.statusLabelNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #askGtpEngineForDeadStonesEnds notifications.
// -----------------------------------------------------------------------------
- (void) askGtpEngineForDeadStonesEnds:(NSNotification*)notification
{
  self.activityIndicatorNeedsUpdate = true;
  // No label update here, the "scoring in progress..." message must remain
  // until goScoreCalculationEnds is received.
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionStarts notifications.
///
/// Increases @e actionsInProgress by 1.
// -----------------------------------------------------------------------------
- (void) longRunningActionStarts:(NSNotification*)notification
{
  self.actionsInProgress++;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notifications.
///
/// Decreases @e actionsInProgress by 1. Triggers a view update if
/// @e actionsInProgress becomes 0 and @e updatesWereDelayed is true.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  self.actionsInProgress--;
  if (0 == self.actionsInProgress)
    [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  self.statusLabelNeedsUpdate = true;
  [self delayedUpdate];
}

@end
