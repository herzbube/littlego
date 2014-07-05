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


// 3rdparty library includes (uses "" instead of <> syntax because QuincyKit
// is compiled into the project, not linked against as an external library)
#import "../../3rdparty/install/quincykit/BWQuincyManager.h"

// Forward declarations
@class GtpClient;
@class GtpEngine;
@class NewGameModel;
@class PlayerModel;
@class GtpEngineProfileModel;
@class BoardViewModel;
@class BoardViewMetrics;
@class BoardPositionModel;
@class ScoringModel;
@class SoundHandling;
@class GoGame;
@class ArchiveViewModel;
@class GtpLogModel;
@class GtpCommandModel;
@class CrashReportingModel;
@class LoggingModel;
@class MainTabBarController;
@class UiSettingsModel;


// -----------------------------------------------------------------------------
/// @brief The ApplicationDelegate class implements the role of delegate of the
/// UIApplication main object.
///
/// As an additional responsibility, it creates instances of GtpEngine and
/// GtpClient and sets them up to communicate with each other.
///
/// @note Since this project does not use any .xib files, the party responsible
/// for creating an instance of ApplicationDelegate is the project's main()
/// function (actually the main() function informs another global function,
/// UIApplicationMain(), which type instantiate). The single instance of
/// ApplicationDelegate then becomes available to clients via the class method
/// sharedDelegate().
// -----------------------------------------------------------------------------
@interface ApplicationDelegate : NSObject <UIApplicationDelegate,
                                           BWQuincyManagerDelegate>
{
}

+ (ApplicationDelegate*) sharedDelegate;
+ (ApplicationDelegate*) newDelegate;

- (void) setupCrashReporting;
- (void) setupLogging;
- (void) setupApplicationLaunchMode;
- (void) setupFolders;
- (void) setupResourceBundle;
- (void) setupRegistrationDomain;
- (void) setupUserDefaults;
- (void) setupSound;
- (void) setupGUI;
- (void) setupFuego;
- (void) writeUserDefaults;
- (NSString*) contentOfTextResource:(NSString*)resourceName;
- (NSString*) logFolder;

/// @brief The main application window.
@property(nonatomic, retain) UIWindow* window;
/// @brief The main application controller.
@property(nonatomic, retain) MainTabBarController* tabBarController;
/// @brief Indicates how the application was launched.
///
/// This property initially has the value #ApplicationLaunchModeUnknown. At the
/// very beginning of the application launch process this property is set to its
/// final value. The mode thus determined is then used to direct the remainder
/// of the application launch process. Once the application is running the
/// property can still be queried to see what happened during application
/// launch.
@property(nonatomic, assign) enum ApplicationLaunchMode applicationLaunchMode;
/// @brief Refers to the last .sgf file passed into the app via the system's
/// document interaction mechanism. Is nil if no .sgf file was ever passed in.
@property(nonatomic, retain) NSURL* documentInteractionURL;
/// @brief Flag is true if user defaults should be written to the user defaults
/// system at the appropriate times. Flag is false if user defaults should never
/// be written to the user defaults system.
///
/// This property exists for the purpose of unit testing.
@property(nonatomic, assign) bool writeUserDefaultsEnabled;
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
/// @brief Model object that stores attributes used to manage the view hierarchy
/// that displays the Go board.
@property(nonatomic, retain) BoardViewModel* boardViewModel;
/// @brief Model object that calculates locations and sizes of Go board elements
/// as they are seen in the view hierarchy that displays the Go board.
@property(nonatomic, retain) BoardViewMetrics* boardViewMetrics;
/// @brief Model object that manages data related to the board position
/// displayed on the Play view.
@property(nonatomic, retain) BoardPositionModel* boardPositionModel;
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
/// @brief Model object that stores attributes that describe the behaviour of
/// the crash reporting service.
@property(nonatomic, retain) CrashReportingModel* crashReportingModel;
/// @brief Model object that stores attributes that are relevant for the
/// logging service.
@property(nonatomic, retain) LoggingModel* loggingModel;
/// @brief Model object that stores attributes relating to the general user
/// interface appearance.
@property(nonatomic, retain) UiSettingsModel* uiSettingsModel;

@end

