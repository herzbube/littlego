// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeTreeViewTapGestureController.h"
#import "NodeTreeView.h"
#import "../gameaction/GameActionManager.h"
#import "../model/BoardViewModel.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/UiSettingsModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// NodeTreeViewTapGestureController.
// -----------------------------------------------------------------------------
@interface NodeTreeViewTapGestureController()
/// @brief The gesture recognizer used to detect the tap gesture.
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
/// @brief True if a tapping gesture is currently allowed, false if not.
@property(nonatomic, assign, getter=isTappingEnabled) bool tappingEnabled;
@end


@implementation NodeTreeViewTapGestureController

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewTapGestureController object.
///
/// @note This is the designated initializer of
/// NodeTreeViewTapGestureController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.nodeTreeView = nil;

  [self setupTapGestureRecognizer];
  [self setupNotificationResponders];
  [self updateTappingEnabled];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewTapGestureController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  self.nodeTreeView = nil;
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
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(boardViewPanningGestureWillStart:) name:boardViewPanningGestureWillStart object:nil];
  [center addObserver:self selector:@selector(boardViewPanningGestureWillEnd:) name:boardViewPanningGestureWillEnd object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationWillBegin:) name:boardViewAnimationWillBegin object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationDidEnd:) name:boardViewAnimationDidEnd object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setNodeTreeView:(NodeTreeView*)nodeTreeView
{
  if (_nodeTreeView == nodeTreeView)
    return;
  if (_nodeTreeView && self.tapRecognizer)
    [_nodeTreeView removeGestureRecognizer:self.tapRecognizer];
  _nodeTreeView = nodeTreeView;
  if (_nodeTreeView && self.tapRecognizer)
    [_nodeTreeView addGestureRecognizer:self.tapRecognizer];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tapping gesture in the view's Go board area.
// -----------------------------------------------------------------------------
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer
{
  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  if (UIGestureRecognizerStateEnded != recognizerState)
    return;

  CGPoint tappingLocation = [gestureRecognizer locationInView:self.nodeTreeView];
  GoNode* node = [self.nodeTreeView nodeNear:tappingLocation];
  if (! node)
    return;

  GameActionManager* gameActionManager = [GameActionManager sharedGameActionManager];
  [gameActionManager selectNode:node];
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
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewPanningGestureWillStart notification.
// -----------------------------------------------------------------------------
- (void) boardViewPanningGestureWillStart:(NSNotification*)notification
{
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewPanningGestureWillEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewPanningGestureWillEnd:(NSNotification*)notification
{
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationWillBegin notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationWillBegin:(NSNotification*)notification
{
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationDidEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationDidEnd:(NSNotification*)notification
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
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  switch (appDelegate.uiSettingsModel.uiAreaPlayMode)
  {
    case UIAreaPlayModeScoring:
    {
      GoGame* game = [GoGame sharedGame];
      self.tappingEnabled = ! game.score.scoringInProgress;
      break;
    }
    case UIAreaPlayModeBoardSetup:
    case UIAreaPlayModeEditMarkup:
    {
      self.tappingEnabled = true;
      break;
    }
    case UIAreaPlayModePlay:
    {
      GoGame* game = [GoGame sharedGame];
      if (! game ||
          game.isComputerThinking ||
          appDelegate.boardViewModel.boardViewPanningGestureIsInProgress ||
          appDelegate.boardViewModel.boardViewDisplaysAnimation)
      {
        self.tappingEnabled = false;
      }
      else
      {
        self.tappingEnabled = true;
      }
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
