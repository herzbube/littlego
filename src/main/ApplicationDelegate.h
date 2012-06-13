// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "../ui/MBProgressHUD.h"

// Forward declarations
@class GtpClient;
@class GtpEngine;
@class NewGameModel;
@class PlayerModel;
@class GtpEngineProfileModel;
@class PlayViewModel;
@class ScoringModel;
@class SoundHandling;
@class GoGame;
@class ArchiveViewModel;
@class GtpLogModel;
@class GtpCommandModel;


// -----------------------------------------------------------------------------
/// @brief The ApplicationDelegate class implements the role of delegate of the
/// UIApplication main object.
///
/// As an additional responsibility, it creates instances of GtpEngine and
/// GtpClient and sets them up to communicate with each other.
///
/// @note ApplicationDelegate is instantiated when MainWindow.xib is loaded.
/// The single instance of ApplicationDelegate is available to clients via the
/// class method sharedDelegate().
// -----------------------------------------------------------------------------
@interface ApplicationDelegate : NSObject <UIApplicationDelegate, MBProgressHUDDelegate>
{
@private
  /// @name Outlets
  /// @brief These variables are outlets and initialized in MainWindow.xib.
  //@{
  UIWindow* window;
  UITabBarController* tabBarController;
  //@}
}

+ (ApplicationDelegate*) sharedDelegate;
+ (ApplicationDelegate*) newDelegate;

- (void) setupLogging;
- (void) setupFolders;
- (void) setupResourceBundle;
- (void) setupRegistrationDomain;
- (void) setupUserDefaults;
- (void) setupSound;
- (void) setupGUI;
- (void) setupFuego;
- (void) writeUserDefaults;
- (void) activateTab:(enum TabType)tabID;
- (NSString*) contentOfTextResource:(NSString*)resourceName;
- (NSString*) resourceNameForTabType:(enum TabType)tabType;

/// @brief The main application window.
@property(nonatomic, retain) IBOutlet UIWindow* window;
/// @brief The main application controller.
@property(nonatomic, retain) IBOutlet UITabBarController* tabBarController;
/// @brief Is false during application launch, and shortly afterwards while this
/// delegate is still setting up objects that are important for the application
/// lifecycle.
///
/// Becomes true after the application delegate has finished setting everything
/// up. Just after this flag becomes true, the notification
/// #applicationIsReadyForAction is posted to the global notification center.
@property(nonatomic, assign) bool applicationReadyForAction;
/// @brief The bundle that contains the application's resources. This property
/// exists to make the application more testable.
@property(nonatomic, assign) NSBundle* resourceBundle;
/// @brief The GTP client instance.
@property(nonatomic, retain) GtpClient* gtpClient;
/// @brief The GTP engine instance.
@property(nonatomic, retain) GtpEngine* gtpEngine;
/// @brief Model object that stores attributes of a new game.
@property(nonatomic, retain) NewGameModel* theNewGameModel;
/// @brief Model object that stores player data.
@property(nonatomic, retain) PlayerModel* playerModel;
/// @brief Model object that stores GTP engine profile data.
@property(nonatomic, retain) GtpEngineProfileModel* gtpEngineProfileModel;
/// @brief Model object that stores attributes used to manage the Play view.
@property(nonatomic, retain) PlayViewModel* playViewModel;
/// @brief Model object that stores attributes used for scoring.
@property(nonatomic, retain) ScoringModel* scoringModel;
/// @brief Object that handles sounds and vibration.
@property(nonatomic, retain) SoundHandling* soundHandling;
/// @brief Object that represents the game that is currently in progress.
@property(nonatomic, retain) GoGame* game;
/// @brief Model object that stores attributes used to manage the Archive view.
@property(nonatomic, retain) ArchiveViewModel* archiveViewModel;
/// @brief Model object that stores information about the GTP log, viewable on
/// the Diagnostics view.
@property(nonatomic, retain) GtpLogModel* gtpLogModel;
/// @brief Model object that stores canned GTP commands that can be managed and
/// submitted on the Diagnostics view.
@property(nonatomic, retain) GtpCommandModel* gtpCommandModel;

@end

