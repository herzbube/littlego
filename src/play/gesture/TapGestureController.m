// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "../PlayView.h"
#import "../ScoringModel.h"
#import "../../go/GoPoint.h"
#import "../../go/GoScore.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for TapGestureController.
// -----------------------------------------------------------------------------
@interface TapGestureController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Gesture handler
//@{
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer;
//@}
/// @name UIGestureRecognizerDelegate protocol
//@{
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer;
//@}
/// @name Notification responders
//@{
- (void) goScoreScoringModeEnabled:(NSNotification*)notification;
- (void) goScoreScoringModeDisabled:(NSNotification*)notification;
- (void) goScoreCalculationStarts:(NSNotification*)notification;
- (void) goScoreCalculationEnds:(NSNotification*)notification;
//@}
/// @name Updaters
//@{
- (void) updateTappingEnabled;
//@}
/// @name Private helpers
//@{
- (void) setupTapGestureRecognizer;
- (void) setupNotificationResponders;
//@}
/// @name Privately declared properties
//@{
/// @brief The view that TapGestureController manages gestures for.
@property(nonatomic, assign) PlayView* playView;
/// @brief The model that manages scoring-related data.
@property(nonatomic, assign) ScoringModel* scoringModel;
/// @brief The gesture recognizer used to detect the tap gesture.
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
/// @brief True if a tapping gesture is currently allowed, false if not (e.g.
/// if scoring mode is not enabled).
@property(nonatomic, assign, getter=isTappingEnabled) bool tappingEnabled;
@end


@implementation TapGestureController

@synthesize playView;
@synthesize scoringModel;
@synthesize tapRecognizer;
@synthesize tappingEnabled;


// -----------------------------------------------------------------------------
/// @brief Initializes a TapGestureController object that manages @a playView.
///
/// @note This is the designated initializer of TapGestureController.
// -----------------------------------------------------------------------------
- (id) initWithPlayView:(PlayView*)aPlayView scoringModel:(ScoringModel*)aScoringModel
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.playView = aPlayView;
  self.scoringModel = aScoringModel;

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
  self.playView = nil;
  self.scoringModel = nil;
  self.tapRecognizer = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupTapGestureRecognizer
{
  self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
	[self.tapRecognizer release];
	[self.playView addGestureRecognizer:self.tapRecognizer];
  self.tapRecognizer.delegate = self;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goScoreScoringModeEnabled:) name:goScoreScoringModeEnabled object:nil];
  [center addObserver:self selector:@selector(goScoreScoringModeDisabled:) name:goScoreScoringModeDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tapping gesture in the view's Go board area.
// -----------------------------------------------------------------------------
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer
{
  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  if (UIGestureRecognizerStateEnded != recognizerState)
    return;
  CGPoint tappingLocation = [gestureRecognizer locationInView:self.playView];
  GoPoint* deadStonePoint = [self.playView pointNear:tappingLocation];
  if (! deadStonePoint || ! [deadStonePoint hasStone])
    return;
  [self.scoringModel.score toggleDeadStoneStateOfGroup:deadStonePoint.region];
  [self.scoringModel.score calculateWaitUntilDone:false];
}

// -----------------------------------------------------------------------------
/// @brief UIGestureRecognizerDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
  return self.isTappingEnabled;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringModeEnabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeEnabled:(NSNotification*)notification
{
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringModeDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeDisabled:(NSNotification*)notification
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
  if (self.scoringModel.scoringMode)
    self.tappingEnabled = ! self.scoringModel.score.scoringInProgress;
  else
    self.tappingEnabled = false;
}

@end
