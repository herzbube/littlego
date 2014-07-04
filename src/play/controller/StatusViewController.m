// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "../model/ScoringModel.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoScore.h"
#import "../../go/GoVertex.h"
#import "../../main/ApplicationDelegate.h"
#import "../../player/Player.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for StatusViewController.
// -----------------------------------------------------------------------------
@interface StatusViewController()
/// @name Privately declared properties
//@{
@property(nonatomic, assign) UILabel* statusLabel;
@property(nonatomic, assign) UIActivityIndicatorView* activityIndicator;
@property(nonatomic, assign) bool activityIndicatorNeedsUpdate;
@property(nonatomic, assign) bool statusLabelNeedsUpdate;
//@}
@end


@implementation StatusViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a StatusViewController object.
///
/// @note This is the designated initializer of StatusViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self releaseObjects];
  self.activityIndicatorNeedsUpdate = false;
  self.statusLabelNeedsUpdate = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StatusViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  [self releaseObjects];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.statusLabel = nil;
  self.activityIndicator = nil;
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [self createViews];
  [self setupViewHierarchy];
  [self configureViews];
  [self setupAutoLayoutConstraints];
  [self setupNotificationResponders];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) createViews
{
  [super loadView];
  self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectZero] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.statusLabel];
  [self.view addSubview:self.activityIndicator];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  self.statusLabel.numberOfLines = 0;
  CGFloat fontSize;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    fontSize = 9.0f;
  else
    fontSize = 10.0f;
  self.statusLabel.font = [UIFont systemFontOfSize:fontSize];
  self.statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
  self.statusLabel.textAlignment = NSTextAlignmentCenter;

  self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
  self.activityIndicator.hidden = YES;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.statusLabel, @"statusLabel",
                                   self.activityIndicator, @"activityIndicator",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-0-[statusLabel]-0-[activityIndicator]-0-|",
                            @"V:|-0-[statusLabel]-0-|",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.view];
  [AutoLayoutUtility alignFirstView:self.activityIndicator
                     withSecondView:self.statusLabel
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goScoreScoringDisabled:) name:goScoreScoringDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(askGtpEngineForDeadStonesStarts:) name:askGtpEngineForDeadStonesStarts object:nil];
  [center addObserver:self selector:@selector(askGtpEngineForDeadStonesEnds:) name:askGtpEngineForDeadStonesEnds object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  [[GoGame sharedGame].boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [[ApplicationDelegate sharedDelegate].scoringModel addObserver:self forKeyPath:@"scoreMarkMode" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[GoGame sharedGame].boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [[ApplicationDelegate sharedDelegate].scoringModel removeObserver:self forKeyPath:@"scoreMarkMode"];
}

// -----------------------------------------------------------------------------
/// @brief Updates the status view with a new size.
// -----------------------------------------------------------------------------
- (void) setStatusViewSize:(CGSize)statusViewSize;
{
  CGRect bounds = self.view.bounds;
  bounds.size = statusViewSize;
  self.view.bounds = bounds;
  [self.view setNeedsLayout];
  [self.view layoutIfNeeded];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. See class
/// documentation for details.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;
  [self updateStatusView];
}

// -----------------------------------------------------------------------------
/// @brief Updates the status view with text that provides feedback to the user
/// about what's going on. Also starts/stops animating the activity indicator.
// -----------------------------------------------------------------------------
- (void) updateStatusView
{
  [self updateActivityIndicator];
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

  GoGame* game = [GoGame sharedGame];
  bool activityIndicatorShouldAnimate = false;
  if (game.score.scoringEnabled)
  {
    if (game.score.askGtpEngineForDeadStonesInProgress)
      activityIndicatorShouldAnimate = true;
    else
      activityIndicatorShouldAnimate = false;
  }
  else
  {
    if ([game isComputerThinking])
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
    }
  }
  else
  {
    if (self.activityIndicator.isAnimating)
    {
      [self.activityIndicator stopAnimating];
      self.activityIndicator.hidden = YES;
    }
  }
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

//  if (self.playView.crossHairPoint)
  if (false)
  {
//    statusText = self.playView.crossHairPoint.vertex.string;
//    if (! self.playView.crossHairPointIsLegalMove)
//    {
//      enum GoMoveIsIllegalReason isIllegalReason = self.playView.crossHairPointIsIllegalReason;
//      switch (isIllegalReason)
//      {
//        case GoMoveIsIllegalReasonSuicide:
//        case GoMoveIsIllegalReasonSimpleKo:
//        case GoMoveIsIllegalReasonSuperko:
//        case GoMoveIsIllegalReasonUnknown:
//        {
//          NSString* isIllegalReason = [NSString stringWithMoveIsIllegalReason:self.playView.crossHairPointIsIllegalReason];
//          statusText = [statusText stringByAppendingString:@" - Cannot play: "];
//          statusText = [statusText stringByAppendingString:isIllegalReason];
//          break;
//        }
//        default:
//        {
//          // No special message if intersection is occupied, that's too basic
//          break;
//        }
//      }
//    }
  }
  else
  {
    GoGame* game = [GoGame sharedGame];
    if (game.isComputerThinking)
    {
      switch (game.state)
      {
        case GoGameStateGameHasStarted:
        case GoGameStateGameIsPaused:          // although game is paused, computer may still be thinking
        {
          switch (game.reasonForComputerIsThinking)
          {
            case GoGameComputerIsThinkingReasonComputerPlay:
            {
              NSString* playerName = game.currentPlayer.player.name;
              if (game.isComputerPlayersTurn)
                statusText = [playerName stringByAppendingString:@" is thinking..."];
              else
                statusText = [NSString stringWithFormat:@"Computer is playing for %@...", playerName];
              break;
            }
            case GoGameComputerIsThinkingReasonPlayerInfluence:
            {
              statusText = @"Updating player influence...";
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
        default:
          break;
      }
    }
    else
    {
      GoScore* score = [GoGame sharedGame].score;
      if (score.scoringEnabled)
      {
        if (score.scoringInProgress)
          statusText = @"Scoring in progress...";
        else
        {
          statusText = [[GoGame sharedGame].score resultString];
          if (GoScoreMarkModeDead == [ApplicationDelegate sharedDelegate].scoringModel.scoreMarkMode)
            statusText = [statusText stringByAppendingString:@" - Tap to mark dead stones"];
          else
            statusText = [statusText stringByAppendingString:@" - Tap to mark stones in seki"];
        }
      }
      else
      {
        if (GoGameStateGameHasStarted == game.state ||
            (GoGameStateGameHasEnded == game.state && ! game.boardPosition.isLastPosition))
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
        }
        else if (GoGameStateGameHasEnded == game.state)
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
              statusText = [NSString stringWithFormat:@"%@ resigned", color];
              break;
            }
            default:
              break;
          }
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
/// @brief Responds to the #goScoreScoringDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringDisabled:(NSNotification*)notification
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
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
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
