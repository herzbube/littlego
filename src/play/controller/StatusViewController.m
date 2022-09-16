// -----------------------------------------------------------------------------
// Copyright 2011-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "../model/MarkupModel.h"
#import "../model/ScoringModel.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoNode.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoScore.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../main/ApplicationDelegate.h"
#import "../../player/Player.h"
#import "../../shared/LayoutManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiSettingsModel.h"
#import "../../utility/ExceptionUtility.h"
#import "../../utility/MarkupUtilities.h"
#import "../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for StatusViewController.
// -----------------------------------------------------------------------------
@interface StatusViewController()
/// @brief Prevents unregistering by dealloc if registering hasn't happened
/// yet. Registering may not happen if the controller's view is never loaded.
@property(nonatomic, assign) bool notificationRespondersAreSetup;
@property(nonatomic, assign) bool autoLayoutConstraintsAreSetup;
@property(nonatomic, retain) UIView* containerView;
@property(nonatomic, retain) UILabel* statusLabel;
@property(nonatomic, retain) UIActivityIndicatorView* activityIndicator;
@property(nonatomic, assign) bool activityIndicatorNeedsUpdate;
@property(nonatomic, assign) bool statusLabelNeedsUpdate;
@property(nonatomic, retain) NSArray* stonePlacementInformation;
@property(nonatomic, retain) NSArray* markupPlacementInformation;
@property(nonatomic, retain) NSArray* selectionRectangleInformation;
@property(nonatomic, assign) bool shouldDisplayActivityIndicator;
@property(nonatomic, retain) NSLayoutConstraint* activityIndicatorWidthConstraint;
@property(nonatomic, retain) NSLayoutConstraint* activityIndicatorSpacingConstraint;
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
  self.notificationRespondersAreSetup = false;
  self.autoLayoutConstraintsAreSetup = false;
  self.activityIndicatorNeedsUpdate = false;
  self.statusLabelNeedsUpdate = false;
  self.shouldDisplayActivityIndicator = false;
  self.activityIndicatorWidthConstraint = nil;
  self.activityIndicatorSpacingConstraint = nil;
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
  self.containerView = nil;
  self.statusLabel = nil;
  self.activityIndicator = nil;
  self.stonePlacementInformation = nil;
  self.markupPlacementInformation = nil;
  self.selectionRectangleInformation = nil;
  self.activityIndicatorWidthConstraint = nil;
  self.activityIndicatorSpacingConstraint = nil;
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self createViews];
  [self setupViewHierarchy];
  [self configureViews];
  [self setupNotificationResponders];

  // New controller instances may be created in mid-game after a layout change
  self.statusLabelNeedsUpdate = true;
  self.activityIndicatorNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
///
/// This override handles interface orientation changes while this controller's
/// view hierarchy is visible, and changes that occurred while this controller's
/// view hierarchy was not visible (this method is invoked when the controller's
/// view becomes visible again).
// -----------------------------------------------------------------------------
- (void) viewWillLayoutSubviews
{
  if (self.autoLayoutConstraintsAreSetup)
    return;

  // We don't setup Auto Layout constraints in loadView, instead we delay until
  // viewWillLayoutSubviews. Reason: When on UITypePhone and in landscape
  // orientation, UIKit temporarily "thinks" that the safe area layout guide of
  // this view controller's main view should honor the tab bar, even though
  // this view controller's main view does not come even near the tab bar. As
  // a result there is a temporary Auto Layout constraint that causes problems
  // if the status view is less high than 70 (the height of a tab bar).
  // Unfortunately the container view controller of this view controller does
  // exactly that - it sets up a height for the status view that is less than
  // 70. At the time viewWillLayoutSubviews is invoked, the temporary and
  // erroneous Auto Layout constraint has gone, so by delaying creation of our
  // Auto Layout constraints we work around the problem.
  [self setupAutoLayoutConstraints];
  [self updateAutoLayoutConstraints];
  self.autoLayoutConstraintsAreSetup = true;
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) createViews
{
  self.containerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectZero] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.containerView];
  [self.containerView addSubview:self.statusLabel];
  [self.containerView addSubview:self.activityIndicator];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  self.statusLabel.accessibilityIdentifier = statusLabelAccessibilityIdentifier;
  self.statusLabel.numberOfLines = 0;
  // Font size must strike a balance between remaining legible and accomodating
  // the longest possible status text in the most space-constrained application
  // state. When testing consider this:
  // - The longest possible status text is the one that includes the player
  //   name, because that name is variable and can be entered by the user.
  // - The longest status text without a variable component is the one in
  //   scoring mode, when one of the players has resigned.
  // - When testing, make sure that the longest non-variable text fits, then
  //   also test with a long player name to make sure an acceptable part of the
  //   name is still visible before it is truncated.
  CGFloat fontSize;
  switch ([LayoutManager sharedManager].uiType)
  {
    case UITypePhonePortraitOnly:
      // Label can have 3 lines. Player names can be somewhat longer than 40
      // characters but must consist of several words for line breaks.
      fontSize = 9.0f;
      break;
    case UITypePhone:
      // Portrait: See UITypePad.
      // Landscape: Label can have 4 lines. Player names about 40 characters
      // long are OK but must consist of several words for line breaks.
      fontSize = 10.0f;
      break;
    case UITypePad:
      // Label can have 3 lines. Player names can be insanely long and can
      // even consist of long words.
      fontSize = 10.0f;
      break;
    default:
      [ExceptionUtility throwInvalidUIType:[LayoutManager sharedManager].uiType];
  }
  self.statusLabel.font = [UIFont systemFontOfSize:fontSize];
  self.statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
  self.statusLabel.textAlignment = NSTextAlignmentCenter;

  if ([LayoutManager sharedManager].uiType != UITypePhonePortraitOnly)
  {
    UIInterfaceOrientation interfaceOrientation = [UiElementMetrics interfaceOrientation];
    bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
    if (! isPortraitOrientation)
    {
      self.view.backgroundColor = [UIColor blackColor];
      self.statusLabel.textColor = [UIColor whiteColor];
      self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    }
  }
  else
  {
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;

  // The container view makes sure that the status view content is within the
  // safe area, while the view controller's main view that has a background
  // color can extend to any screen edges that are outside the safe area.
  [AutoLayoutUtility fillSafeAreaOfSuperview:self.view withSubview:self.containerView];

  int horizontalSpacingSuperview;
  if ([LayoutManager sharedManager].uiType == UITypePhone)
    horizontalSpacingSuperview = [AutoLayoutUtility horizontalSpacingTableViewCell];
  else
    horizontalSpacingSuperview = 0;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];
  viewsDictionary[@"statusLabel"] = self.statusLabel;
  viewsDictionary[@"activityIndicator"] = self.activityIndicator;
  [visualFormats addObject:[NSString stringWithFormat:@"H:|-%d-[statusLabel]", horizontalSpacingSuperview]];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[activityIndicator]-%d-|", horizontalSpacingSuperview]];
  [visualFormats addObject:@"V:|-0-[statusLabel]-0-|"];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];

  [AutoLayoutUtility alignFirstView:self.activityIndicator
                     withSecondView:self.statusLabel
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self.containerView];
  self.activityIndicatorWidthConstraint = [NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0f
                                                                        constant:0.0f];
  self.activityIndicatorSpacingConstraint = [NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                                         attribute:NSLayoutAttributeLeft
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.statusLabel
                                                                         attribute:NSLayoutAttributeRight
                                                                        multiplier:1.0f
                                                                          constant:0.0f];
  [self.containerView addConstraint:self.activityIndicatorWidthConstraint];
  [self.containerView addConstraint:self.activityIndicatorSpacingConstraint];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) updateAutoLayoutConstraints
{
  if (self.shouldDisplayActivityIndicator)
  {
    // Experimentally determined custom spacing
    self.activityIndicatorSpacingConstraint.constant = 15.0f;
    self.activityIndicatorWidthConstraint.constant = self.activityIndicator.intrinsicContentSize.width;
  }
  else
  {
    self.activityIndicatorSpacingConstraint.constant = 0.0f;
    self.activityIndicatorWidthConstraint.constant = 0.0f;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  if (self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = true;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(uiAreaPlayModeDidChange:) name:uiAreaPlayModeDidChange object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(askGtpEngineForDeadStonesStarts:) name:askGtpEngineForDeadStonesStarts object:nil];
  [center addObserver:self selector:@selector(askGtpEngineForDeadStonesEnds:) name:askGtpEngineForDeadStonesEnds object:nil];
  [center addObserver:self selector:@selector(boardViewStoneLocationDidChange:) name:boardViewStoneLocationDidChange object:nil];
  [center addObserver:self selector:@selector(boardViewMarkupLocationDidChange:) name:boardViewMarkupLocationDidChange object:nil];
  [center addObserver:self selector:@selector(boardViewSelectionRectangleDidChange:) name:boardViewSelectionRectangleDidChange object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  [self setupNotificationRespondersForGame:[GoGame sharedGame]];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  [appDelegate.markupModel addObserver:self forKeyPath:@"markupType" options:0 context:NULL];
  [appDelegate.scoringModel addObserver:self forKeyPath:@"scoreMarkMode" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationRespondersForGame:(GoGame*)game
{
  if (! game)
    return;
  [game addObserver:self forKeyPath:@"nextMoveColor" options:0 context:NULL];
  [game.boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  // This one is required solely for the scenario:
  // - Current board position = First board position
  // - There was at least one move
  // - User just discarded all future moves
  // Here the status label must change from "<color> will play <move>" to
  // "<color> to move".
  [game.boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  if (! self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = false;

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self removeNotificationRespondersForGame:[GoGame sharedGame]];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  [appDelegate.markupModel removeObserver:self forKeyPath:@"markupType"];
  [appDelegate.scoringModel removeObserver:self forKeyPath:@"scoreMarkMode"];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationRespondersForGame:(GoGame*)game
{
  if (! game)
    return;
  [game removeObserver:self forKeyPath:@"nextMoveColor"];
  [game.boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [game.boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
}

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
  bool shouldDisplayActivityIndicator = false;
  if ([ApplicationDelegate sharedDelegate].uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
  {
    if (game.score.askGtpEngineForDeadStonesInProgress)
      shouldDisplayActivityIndicator = true;
    else
      shouldDisplayActivityIndicator = false;
  }
  else
  {
    if ([game isComputerThinking])
      shouldDisplayActivityIndicator = true;
    else
      shouldDisplayActivityIndicator = false;
  }

  if (shouldDisplayActivityIndicator == self.shouldDisplayActivityIndicator)
    return;  // activity indicator already has desired state
  self.shouldDisplayActivityIndicator = shouldDisplayActivityIndicator;

  [self updateAutoLayoutConstraints];

  if (shouldDisplayActivityIndicator)
    [self.activityIndicator startAnimating];
  else
    [self.activityIndicator stopAnimating];
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

  if (self.stonePlacementInformation)
  {
    GoPoint* stoneLocation = [self.stonePlacementInformation objectAtIndex:0];
    bool stoneLocationIsLegalMove = [[self.stonePlacementInformation objectAtIndex:1] boolValue];
    if (stoneLocationIsLegalMove)
    {
      statusText = stoneLocation.vertex.string;
    }
    else
    {
      statusText = stoneLocation.vertex.string;
      enum GoMoveIsIllegalReason isIllegalReason = [[self.stonePlacementInformation objectAtIndex:2] intValue];
      switch (isIllegalReason)
      {
        case GoMoveIsIllegalReasonIntersectionOccupied:
        {
          // No special message if intersection is occupied, that's too basic
          break;
        }
        default:
        {
          NSString* isIllegalReasonString = [NSString stringWithMoveIsIllegalReason:isIllegalReason];
          statusText = [statusText stringByAppendingString:@" - Cannot play: "];
          statusText = [statusText stringByAppendingString:isIllegalReasonString];
          break;
        }
      }
    }
  }
  else if (self.markupPlacementInformation)
  {
    NSNumber* markupTypeAsNumber = [self.markupPlacementInformation objectAtIndex:0];
    enum MarkupType markupType = markupTypeAsNumber.intValue;
    if (markupType == MarkupTypeConnectionArrow || markupType == MarkupTypeConnectionLine)
    {
      enum GoMarkupConnection connection = [MarkupUtilities connectionForMarkupType:markupType];
      GoPoint* fromPoint = [self.markupPlacementInformation objectAtIndex:1];
      GoPoint* toPoint = [self.markupPlacementInformation objectAtIndex:2];

      NSString* connectionTextSymbol;
      if (connection == GoMarkupConnectionArrow)
        connectionTextSymbol = @"➔";
      else
        connectionTextSymbol = @"-";

      if (fromPoint == toPoint)
        statusText = [NSString stringWithFormat:@"%@ %@ Drag to other intersection", fromPoint.vertex.string, connectionTextSymbol];
      else
        statusText = [NSString stringWithFormat:@"%@ %@ %@", fromPoint.vertex.string, connectionTextSymbol, toPoint.vertex.string];
    }
    else
    {
      GoPoint* point = [self.markupPlacementInformation objectAtIndex:1];
      statusText = point.vertex.string;
    }
  }
  else if (self.selectionRectangleInformation)
  {
    GoPoint* fromPoint = [self.selectionRectangleInformation objectAtIndex:0];
    GoPoint* toPoint = [self.selectionRectangleInformation objectAtIndex:1];

    if (fromPoint == toPoint)
      statusText = [NSString stringWithFormat:@"Erase markup on intersection - %@", fromPoint.vertex.string];
    else
      statusText = [NSString stringWithFormat:@"Erase markup in area - %@ : %@", fromPoint.vertex.string, toPoint.vertex.string];
  }
  else
  {
    GoGame* game = [GoGame sharedGame];
    if (game.isComputerThinking)
    {
      switch (game.reasonForComputerIsThinking)
      {
        case GoGameComputerIsThinkingReasonComputerPlay:
        {
          NSString* playerName = game.nextMovePlayer.player.name;
          if (game.nextMovePlayerIsComputerPlayer)
            statusText = [playerName stringByAppendingString:@" is thinking..."];
          else
            statusText = [NSString stringWithFormat:@"Computer is playing for %@...", playerName];
          break;
        }
        case GoGameComputerIsThinkingReasonMoveSuggestion:
        {
          statusText = @"Calculating move suggestion...";
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
    }
    else
    {
      ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
      UiSettingsModel* uiSettingsModel = appDelegate.uiSettingsModel;

      if (uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeScoring)
      {
        GoScore* score = game.score;
        if (score.scoringInProgress)
        {
          statusText = @"Scoring in progress...";
        }
        else
        {
          NSString* resultString = [score resultString];
          NSString* tapString;
          if (GoScoreMarkModeDead == [ApplicationDelegate sharedDelegate].scoringModel.scoreMarkMode)
            tapString = @" - Tap to mark dead stones";
          else
            tapString = @" - Tap to mark stones in seki";

          if (GoGameStateGameHasEnded != game.state ||
              [GoUtilities numberOfMovesAfterNode:game.boardPosition.currentNode] > 0)
          {
            // If the user is viewing an old board position we don't care
            // whether the game has ended, nor what the reason was - we always
            // show a status as if the game had not yet ended (which is true,
            // in a sense, since the user is viewing a board position before
            // the game has actually ended)
            statusText = [resultString stringByAppendingString:tapString];
          }
          else
          {
            switch (game.reasonForGameHasEnded)
            {
              case GoGameHasEndedReasonFourPasses:
              {
                // Interaction is not possible, so no need to add the tapping
                // message
                statusText = [resultString stringByAppendingString:@" - All stones on the board are deemed alive"];
                break;
              }
              default:
              {
                statusText = [resultString stringByAppendingString:tapString];
                break;
              }
            }
          }
        }
      }
      else if (uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeBoardSetup)
      {
        statusText = @"Tap to place or remove stones";
      }
      else if (uiSettingsModel.uiAreaPlayMode == UIAreaPlayModeEditMarkup)
      {
        MarkupModel* markupModel = appDelegate.markupModel;
        switch (markupModel.markupTool)
        {
          case MarkupToolSymbol:
            statusText = @"Tap to place or remove a symbol";
            break;
          case MarkupToolMarker:
            if (markupModel.markupType == MarkupTypeMarkerLetter)
              statusText = @"Tap to place or remove a letter marker";
            else
              statusText = @"Tap to place or remove a number marker";
            break;
          case MarkupToolLabel:
            statusText = @"Tap to place or edit a label";
            break;
          case MarkupToolConnection:
            if (markupModel.markupType == MarkupTypeConnectionArrow)
              statusText = @"Drag to place an arrow";
            else
              statusText = @"Drag to place a line";
            break;
          case MarkupToolEraser:
            statusText = @"Tap on markup to remove it";
            break;
        }
      }
      else
      {
        enum GoGameState gameState = game.state;
        if (GoGameStateGameHasStarted == gameState ||
            GoGameStateGameIsPaused == gameState ||
            (GoGameStateGameHasEnded == gameState && [GoUtilities nodeWithNextMoveExists:game.boardPosition.currentNode]))
        {
          statusText = [self statusTextForMostRecentAndNextMove:game];
        }
        else if (GoGameStateGameHasEnded == gameState)
        {
          statusText = [self statusTextForMostRecentMoveAndGameEndedReason:game];
        }
      }
    }
  }
  self.statusLabel.text = statusText;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateStatusLabel.
// -----------------------------------------------------------------------------
- (NSString*) statusTextForMostRecentAndNextMove:(GoGame*)game
{
  GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:game.boardPosition.currentNode];
  GoMove* nextMove = nodeWithMostRecentMove ? nodeWithMostRecentMove.goMove.next : nil;

  NSString* statusTextMostRecentMove = [self statusTextForMostRecentMove:nodeWithMostRecentMove];
  NSString* statusTextNextMove = [self statusTextForNextMove:nextMove inGame:game];

  return [NSString stringWithFormat:@"%@\n%@", statusTextMostRecentMove, statusTextNextMove];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateStatusLabel.
// -----------------------------------------------------------------------------
- (NSString*) statusTextForMostRecentMoveAndGameEndedReason:(GoGame*)game
{
  NSString* statusTextForGameEndedReason = [self statusTextForGameEndedReason:game];

  GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:game.boardPosition.currentNode];
  if (! nodeWithMostRecentMove)
    return statusTextForGameEndedReason;

  NSString* statusTextMostRecentMove = [self statusTextForMostRecentMove:nodeWithMostRecentMove];

  return [NSString stringWithFormat:@"%@\n%@", statusTextMostRecentMove, statusTextForGameEndedReason];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateStatusLabel and
/// statusTextForMostRecentAndNextMove.
// -----------------------------------------------------------------------------
- (NSString*) statusTextForMostRecentMove:(GoNode*)nodeWithMostRecentMove
{
  NSString* statusText;

  GoMove* mostRecentMove = nodeWithMostRecentMove ? nodeWithMostRecentMove.goMove : nil;
  if (mostRecentMove)
  {
    NSString* colorMostRecentMove = [NSString stringWithGoColor:mostRecentMove.player.color];
    if (GoMoveTypePlay == mostRecentMove.type)
      statusText = [NSString stringWithFormat:@"%@ played %@", colorMostRecentMove, mostRecentMove.point.vertex.string];
    else
      statusText = [NSString stringWithFormat:@"%@ passed", colorMostRecentMove];
  }
  else
  {
    statusText = @"Game started";
  }

  return statusText;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for statusTextForMostRecentAndNextMove.
// -----------------------------------------------------------------------------
- (NSString*) statusTextForNextMove:(GoMove*)nextMove inGame:(GoGame*)game
{
  NSString* statusText;

  if (nextMove)
  {
    NSString* colorNextMove = [NSString stringWithGoColor:nextMove.player.color];
    if (GoMoveTypePlay == nextMove.type)
      statusText = [NSString stringWithFormat:@"%@ will play %@", colorNextMove, nextMove.point.vertex.string];
    else
      statusText = [NSString stringWithFormat:@"%@ will pass", colorNextMove];
  }
  else
  {
    NSString* colorNextMove = [NSString stringWithGoColor:game.nextMoveColor];
    statusText = [NSString stringWithFormat:@"%@ to move", colorNextMove];
  }

  return statusText;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateStatusLabel.
// -----------------------------------------------------------------------------
- (NSString*) statusTextForGameEndedReason:(GoGame*)game
{
  NSString* statusText;

  switch (game.reasonForGameHasEnded)
  {
    case GoGameHasEndedReasonTwoPasses:
    {
      statusText = @"Game has ended by two consecutive pass moves";
      break;
    }
    case GoGameHasEndedReasonThreePasses:
    {
      statusText = @"Game has ended by three consecutive pass moves";
      break;
    }
    case GoGameHasEndedReasonFourPasses:
    {
      statusText = @"Game has ended by four consecutive pass moves";
      break;
    }
    case GoGameHasEndedReasonBlackWinsByResignation:
    case GoGameHasEndedReasonWhiteWinsByResignation:
    {
      NSString* color = game.reasonForGameHasEnded == GoGameHasEndedReasonBlackWinsByResignation ? @"White" : @"Black";
      statusText = [NSString stringWithFormat:@"%@ resigned", color];
      break;
    }
    case GoGameHasEndedReasonBlackWinsOnTime:
    case GoGameHasEndedReasonWhiteWinsOnTime:
    {
      NSString* color = game.reasonForGameHasEnded == GoGameHasEndedReasonBlackWinsOnTime ? @"Black" : @"White";
      statusText = [NSString stringWithFormat:@"%@ wins on time", color];
      break;
    }
    case GoGameHasEndedReasonBlackWinsByForfeit:
    case GoGameHasEndedReasonWhiteWinsByForfeit:
    {
      NSString* color = game.reasonForGameHasEnded == GoGameHasEndedReasonBlackWinsByForfeit ? @"Black" : @"White";
      statusText = [NSString stringWithFormat:@"%@ wins by forfeit", color];
      break;
    }
    default:
      statusText = nil;
      break;
  }

  return statusText;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  [self removeNotificationRespondersForGame:oldGame];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  [self setupNotificationRespondersForGame:newGame];

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
/// @brief Responds to the #uiAreaPlayModeDidChange notification.
// -----------------------------------------------------------------------------
- (void) uiAreaPlayModeDidChange:(NSNotification*)notification
{
  self.statusLabelNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  // No activity indicator update here, this is handled by
  // askGtpEngineForDeadStonesEnds because the notification is optional.
  self.statusLabelNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #askGtpEngineForDeadStonesStarts notification.
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
/// @brief Responds to the #askGtpEngineForDeadStonesEnds notification.
// -----------------------------------------------------------------------------
- (void) askGtpEngineForDeadStonesEnds:(NSNotification*)notification
{
  self.activityIndicatorNeedsUpdate = true;
  // No label update here, the "scoring in progress..." message must remain
  // until goScoreCalculationEnds is received.
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewStoneLocationDidChange notification.
// -----------------------------------------------------------------------------
- (void) boardViewStoneLocationDidChange:(NSNotification*)notification
{
  NSArray* stonePlacementInformation = notification.object;
  if (stonePlacementInformation.count > 0)
    self.stonePlacementInformation = [NSArray arrayWithArray:stonePlacementInformation];
  else
    self.stonePlacementInformation = nil;
  self.statusLabelNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewMarkupLocationDidChange notification.
// -----------------------------------------------------------------------------
- (void) boardViewMarkupLocationDidChange:(NSNotification*)notification
{
  NSArray* markupPlacementInformation = notification.object;
  if (markupPlacementInformation.count > 0)
    self.markupPlacementInformation = [NSArray arrayWithArray:markupPlacementInformation];
  else
    self.markupPlacementInformation = nil;
  self.statusLabelNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewSelectionRectangleDidChange notification.
// -----------------------------------------------------------------------------
- (void) boardViewSelectionRectangleDidChange:(NSNotification*)notification
{
  NSArray* selectionRectangleInformation = notification.object;
  if (selectionRectangleInformation.count > 0)
    self.selectionRectangleInformation = [NSArray arrayWithArray:selectionRectangleInformation];
  else
    self.selectionRectangleInformation = nil;
  self.statusLabelNeedsUpdate = true;
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
