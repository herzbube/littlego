// -----------------------------------------------------------------------------
// Copyright 2013-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "TapGestureController.h"
#import "../gameaction/GameActionManager.h"
#import "../boardview/BoardView.h"
#import "../model/MarkupModel.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/UiSettingsModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TapGestureController.
// -----------------------------------------------------------------------------
@interface TapGestureController()
/// @brief The gesture recognizer used to detect the tap gesture.
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
/// @brief True if a tapping gesture is currently allowed, false if not (e.g.
/// if scoring mode is not enabled).
@property(nonatomic, assign, getter=isTappingEnabled) bool tappingEnabled;
@end


@implementation TapGestureController

// -----------------------------------------------------------------------------
/// @brief Initializes a TapGestureController object.
///
/// @note This is the designated initializer of TapGestureController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.boardView = nil;
  [self setupTapGestureRecognizer];
  [self setupNotificationResponders];
  [self updateTappingEnabled];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TapGestureController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.boardView = nil;
  self.tapRecognizer = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupTapGestureRecognizer
{
  self.tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)] autorelease];
  self.tapRecognizer.delegate = self;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(uiAreaPlayModeDidChange:) name:uiAreaPlayModeDidChange object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardView:(BoardView*)boardView
{
  if (_boardView == boardView)
    return;
  if (_boardView && self.tapRecognizer)
    [_boardView removeGestureRecognizer:self.tapRecognizer];
  _boardView = boardView;
  if (_boardView && self.tapRecognizer)
    [_boardView addGestureRecognizer:self.tapRecognizer];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tapping gesture in the view's Go board area.
// -----------------------------------------------------------------------------
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer
{
  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  if (UIGestureRecognizerStateEnded != recognizerState)
    return;
  CGPoint tappingLocation = [gestureRecognizer locationInView:self.boardView];
  BoardViewIntersection intersection = [self.boardView intersectionNear:tappingLocation];
  if (BoardViewIntersectionIsNullIntersection(intersection))
    return;

  GameActionManager* gameActionManager = [GameActionManager sharedGameActionManager];

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  switch (appDelegate.uiSettingsModel.uiAreaPlayMode)
  {
    case UIAreaPlayModeScoring:
    {
      if (! [intersection.point hasStone])
        return;

      [gameActionManager toggleScoringStateOfStoneGroupAtIntersection:intersection.point];
      break;
    }
    case UIAreaPlayModeBoardSetup:
    {
      [gameActionManager handleBoardSetupAtIntersection:intersection.point];
      break;
    }
    case UIAreaPlayModeEditMarkup:
    {
      MarkupModel* markupModel = appDelegate.markupModel;
      if (markupModel.markupTool == MarkupToolConnection && ! markupModel.connectionToolAllowsDelete)
        return;

      [gameActionManager handleMarkupEditingSingleTapAtIntersection:intersection.point
                                                         markupTool:markupModel.markupTool
                                                         markupType:markupModel.markupType];
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief UIGestureRecognizerDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
  return self.isTappingEnabled;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  // Need to react to the application state being restored during application
  // launch
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #uiAreaPlayModeDidChange notification.
// -----------------------------------------------------------------------------
- (void) uiAreaPlayModeDidChange:(NSNotification*)notification
{
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationStarts notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Updates whether tapping is enabled.
// -----------------------------------------------------------------------------
- (void) updateTappingEnabled
{
  switch ([ApplicationDelegate sharedDelegate].uiSettingsModel.uiAreaPlayMode)
  {
    case UIAreaPlayModeScoring:
    {
      GoGame* game = [GoGame sharedGame];
      switch (game.reasonForGameHasEnded)
      {
        case GoGameHasEndedReasonFourPasses:
        {
          self.tappingEnabled = false;
          break;
        }
        default:
        {
          self.tappingEnabled = ! game.score.scoringInProgress;
          break;
        }
      }

      break;
    }
    case UIAreaPlayModeBoardSetup:
    case UIAreaPlayModeEditMarkup:
    {
      self.tappingEnabled = true;
      break;
    }
    default:
    {
      self.tappingEnabled = false;
      break;
    }
  }
}

@end
