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
#import "ActivityIndicatorController.h"
#import "ScoringModel.h"
#import "../main/ApplicationDelegate.h"
#import "../go/GoGame.h"
#import "../go/GoScore.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ActivityIndicatorController.
// -----------------------------------------------------------------------------
@interface ActivityIndicatorController()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
/// @name GUI updating
//@{
- (void) updateActivityIndicator;
//@}
/// @name Notification responders
//@{
- (void) computerPlayerThinkingChanged:(NSNotification*)notification;
- (void) goScoreCalculationStarts:(NSNotification*)notification;
- (void) goScoreCalculationEnds:(NSNotification*)notification;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) UIActivityIndicatorView* activityIndicator;
@property(nonatomic, assign) ScoringModel* scoringModel;
//@}
@end


@implementation ActivityIndicatorController

@synthesize activityIndicator;
@synthesize scoringModel;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an ActivityIndicatorController
/// instance that manages @a activityIndicator.
// -----------------------------------------------------------------------------
+ (ActivityIndicatorController*) controllerWithActivityIndicator:(UIActivityIndicatorView*)activityIndicator
{
  ActivityIndicatorController* controller = [[ActivityIndicatorController alloc] init];
  if (controller)
  {
    [controller autorelease];
    controller.activityIndicator = activityIndicator;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an ActivityIndicatorController object.
///
/// @note This is the designated initializer of ActivityIndicatorController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.activityIndicator = nil;
  
  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  self.scoringModel = delegate.scoringModel;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ActivityIndicatorController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.activityIndicator = nil;
  self.scoringModel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Starts/stops animation of the activity indicator, to provide feedback
/// to the user about operations that take a long time.
// -----------------------------------------------------------------------------
- (void) updateActivityIndicator
{
  if (self.scoringModel.scoringMode)
  {
    if (self.scoringModel.score.scoringInProgress)
      [self.activityIndicator startAnimating];
    else
      [self.activityIndicator stopAnimating];
  }
  else
  {
    if ([[GoGame sharedGame] isComputerThinking])
      [self.activityIndicator startAnimating];
    else
      [self.activityIndicator stopAnimating];
  }
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  [self updateActivityIndicator];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationStarts notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  [self updateActivityIndicator];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  [self updateActivityIndicator];
}

@end
