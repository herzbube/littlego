// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "ChangeUIAreaPlayModeCommand.h"
#import "game/ResumePlayCommand.h"
#import "../go/GoGame.h"
#import "../go/GoScore.h"
#import "../go/GoUtilities.h"
#import "../main/ApplicationDelegate.h"
#import "../play/model/ScoringModel.h"
#import "../shared/ApplicationStateManager.h"
#import "../ui/UiSettingsModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// ChangeUIAreaPlayModeCommand.
// -----------------------------------------------------------------------------
@interface ChangeUIAreaPlayModeCommand()
@property(nonatomic, assign) enum UIAreaPlayMode newUIAreaPlayMode;
@property(nonatomic, retain) NSArray* oldAndNewModes;
@end


@implementation ChangeUIAreaPlayModeCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a ChangeUIAreaPlayModeCommand object.
///
/// @note This is the designated initializer of ChangeUIAreaPlayModeCommand.
// -----------------------------------------------------------------------------
- (id) initWithUIAreaPlayMode:(enum UIAreaPlayMode)uiAreaPlayMode
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.newUIAreaPlayMode = uiAreaPlayMode;
  self.oldAndNewModes = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ChangeUIAreaPlayModeCommand
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.oldAndNewModes = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  DDLogInfo(@"Switch UI area 'Play' mode to %d", self.newUIAreaPlayMode);

  UiSettingsModel* uiSettingsModel = [ApplicationDelegate sharedDelegate].uiSettingsModel;
  enum UIAreaPlayMode oldUIAreaPlayMode = uiSettingsModel.uiAreaPlayMode;

  // We gracefully handle clients that invoke this command even though there's
  // nothing to do. In some places of the application it might be inconvenient
  // to have to deal with the application delegate or the UiSettingsModel.
  if (oldUIAreaPlayMode == self.newUIAreaPlayMode)
  {
    DDLogInfo(@"UI area 'Play' already has the desired mode");
    return true;
  }

  self.oldAndNewModes = @[[NSNumber numberWithInt:oldUIAreaPlayMode],
                          [NSNumber numberWithInt:self.newUIAreaPlayMode]];

  // Post the notification before we do anything
  [self postNotification:uiAreaPlayModeWillChange];

  // The UIAreaPlayMode value that we set here can be saved to disk at different
  // times than the state in the Go model objects, notably the scoring data in
  // GoScore and GoBoardRegion. Both sets of information are saved when the app
  // is suspended, but in the event of an app crash the two sets of information
  // on disk may not be in sync. The solution is that when the app launches, the
  // UIAreaPlayMode value takes precedence over the data in the Go model
  // objects, with the potential outcome that the score from the previous app
  // session is lost. See the relevant comment in SetupApplicationCommand for
  // more details.
  uiSettingsModel.uiAreaPlayMode = self.newUIAreaPlayMode;

  // Perform scoring mode handling after we've changed the value in
  // UiSettingsModel. GoScore posts a notification to which many observers
  // respond by querying the current value in UiSettingsModel, so the model
  // already must have the new value.
  if (oldUIAreaPlayMode == UIAreaPlayModeScoring)
  {
    GoScore* score = [GoGame sharedGame].score;
    [score disableScoring];

    [[ApplicationStateManager sharedManager] applicationStateDidChange];
  }
  else if (self.newUIAreaPlayMode == UIAreaPlayModeScoring)
  {
    GoScore* score = [GoGame sharedGame].score;
    [score enableScoring];
    [score calculateWaitUntilDone:false];

    [[ApplicationStateManager sharedManager] applicationStateDidChange];
  }

  // Post the notification after we have finished
  [self postNotification:uiAreaPlayModeDidChange];

  // Perform auto-resume handling after posting uiAreaPlayModeDidChange. This
  // guarantees that the order of notifications remains constant even if
  // control returns from autoResumePlayIfNecessary() before play is actually
  // resumed (due to an alert being displayed).
  if (oldUIAreaPlayMode == UIAreaPlayModeScoring && self.newUIAreaPlayMode == UIAreaPlayModePlay)
    [self autoResumePlayIfNecessary];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Posts the notification with the specified name to the global
/// notification center. This method makes sure that the notification is posted
/// synchronously and on the main thread.
// -----------------------------------------------------------------------------
- (void) postNotification:(NSString*)notificationName
{
  // The command may be executed in a secondary thread (example: when a new game
  // is started). Observers who listen for the notification will likely perform
  // changes in the UI, so we must make sure that the notification is posted
  // on the main thread. We also must use waitUntilDone:YES here to guarantee
  // that UIAreaPlayModeWillChange is delivered before UIAreaPlayModeDidChange.
  [self performSelector:@selector(postNotificationOnMainThread:)
               onThread:[NSThread mainThread]
             withObject:notificationName
          waitUntilDone:YES];
}

// -----------------------------------------------------------------------------
/// @brief Private helper. Is invoked in the context of the main thread.
// -----------------------------------------------------------------------------
- (void) postNotificationOnMainThread:(NSString*)notificationName
{
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self.oldAndNewModes];
}

// -----------------------------------------------------------------------------
/// @brief Resumes play if the user preferences and the current game state
/// allow it.
// -----------------------------------------------------------------------------
- (void) autoResumePlayIfNecessary
{
  if (! [ApplicationDelegate sharedDelegate].scoringModel.autoScoringAndResumingPlay)
    return;
  GoGame* game = [GoGame sharedGame];
  bool shouldAllowResumePlay = [GoUtilities shouldAllowResumePlay:game];
  if (! shouldAllowResumePlay)
    return;
  // ResumePlayCommand may show an alert, so code execution may return to us
  // before play is actually resumed
  [[[[ResumePlayCommand alloc] init] autorelease] submit];
}

@end
