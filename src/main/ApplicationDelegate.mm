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


// -----------------------------------------------------------------------------
/// @mainpage
///
/// Little Go is an iOS application that lets the user play the game of Go
/// against another human, or against the computer.
///
/// The two main classes of the project are ApplicationDelegate and GoGame.
///
/// The main file to read for new developers is README.developer.
// -----------------------------------------------------------------------------


// Project includes
#import "ApplicationDelegate.h"
#import "../gtp/GtpClient.h"
#import "../gtp/GtpEngine.h"
#import "../newgame/NewGameModel.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/PlayerModel.h"
#import "../play/PlayViewModel.h"
#import "../play/ScoringModel.h"
#import "../play/SoundHandling.h"
#import "../archive/ArchiveViewModel.h"
#import "../debug/GtpCommandModel.h"
#import "../debug/GtpLogModel.h"
#import "../command/CommandProcessor.h"
#import "../command/LoadOpeningBookCommand.h"
#import "../command/backup/BackupGameCommand.h"
#import "../command/backup/CleanBackupCommand.h"
#import "../command/backup/RestoreGameCommand.h"
#import "../command/game/PauseGameCommand.h"
#import "../go/GoGame.h"
#import "../utility/UserDefaultsUpdater.h"

// Library includes
#include <cocoalumberjack/DDTTYLogger.h>
#include <cocoalumberjack/DDFileLogger.h>

// System includes
#include <string>
#include <vector>
#include <iostream>  // for cout
#include <sys/stat.h>  // for mkfifo


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ApplicationDelegate.
// -----------------------------------------------------------------------------
@interface ApplicationDelegate()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIApplicationDelegate protocol
//@{
- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions;
- (void) applicationWillResignActive:(UIApplication*)application;
- (void) applicationDidEnterBackground:(UIApplication*)application;
- (void) applicationWillEnterForeground:(UIApplication*)application;
- (void) applicationDidBecomeActive:(UIApplication*)application;
- (void) applicationDidReceiveMemoryWarning:(UIApplication*)application;
//@}
/// @name MBProgressHUDDelegate protocol
//@{
- (void) hudWasHidden:(MBProgressHUD*)progressHUD;
//@}
/// @name Private helpers
//@{
- (void) launchAsynchronously;
- (void) launchWithProgressHUD:(MBProgressHUD*)progressHUD;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) DDFileLogger* fileLogger;
//@}
@end


@implementation ApplicationDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize applicationReadyForAction;
@synthesize resourceBundle;
@synthesize gtpClient;
@synthesize gtpEngine;
@synthesize theNewGameModel;
@synthesize playerModel;
@synthesize gtpEngineProfileModel;
@synthesize scoringModel;
@synthesize playViewModel;
@synthesize soundHandling;
@synthesize game;
@synthesize archiveViewModel;
@synthesize gtpLogModel;
@synthesize gtpCommandModel;
@synthesize fileLogger;


// -----------------------------------------------------------------------------
/// @brief Shared instance of ApplicationDelegate.
// -----------------------------------------------------------------------------
static ApplicationDelegate* sharedDelegate = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared application delegate object.
///
/// TODO: Find out why Doxygen does not generate documentation for this method.
/// Cf. the convenience constructor in GtpClient, for which documentation is
/// generated.
// -----------------------------------------------------------------------------
+ (ApplicationDelegate*) sharedDelegate
{
  assert(sharedDelegate != nil);
  return sharedDelegate;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new ApplicationDelegate object and returns that object.
/// From now on, sharedDelegate() also returns the same object.
///
/// This method exists for the purpose of unit testing. In a normal environment
/// the application delegate is created when the application's main nib file is
/// loaded.
// -----------------------------------------------------------------------------
+ (ApplicationDelegate*) newDelegate
{
  sharedDelegate = [[[ApplicationDelegate alloc] init] autorelease];
  sharedDelegate.applicationReadyForAction = false;
  return sharedDelegate;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ApplicationDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.tabBarController = nil;
  self.window = nil;
  self.gtpClient = nil;
  self.gtpEngine = nil;
  self.theNewGameModel = nil;
  self.playerModel = nil;
  self.gtpEngineProfileModel = nil;
  self.playViewModel = nil;
  self.scoringModel = nil;
  self.soundHandling = nil;
  self.game = nil;
  self.archiveViewModel = nil;
  self.gtpLogModel = nil;
  self.gtpCommandModel = nil;
  self.fileLogger = nil;
  [[CommandProcessor sharedProcessor] release];
  if (self == sharedDelegate)
    sharedDelegate = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Performs major application initialization tasks.
///
/// This method is invoked after the main .nib file has been loaded, but while
/// the application is still in the inactive state.
// -----------------------------------------------------------------------------
- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
  // Make the single instance of this class available as a "shared object", or
  // Singleton.
  sharedDelegate = self;

  // Clients need to see that we are not yet ready. Flag will become true when
  // secondary thread has finished setup.
  self.applicationReadyForAction = false;

  // Delegate setup to secondary thread so that the application launches as
  // quickly as possible
  [self launchAsynchronously];

  // We don't handle any URL resources in launchOptions
  // -> always return success
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that the application is about to
/// become inactive.
///
/// Known events that trigger this:
/// - Screen locking
/// - Modifying an app's document folder via iTunes' "File sharing" feature
///   (only prior to iOS 5)
/// - Any interrupt (e.g. incoming phone call, calling up the multitasking UI)
/// - Anything that will put the app in the background
// -----------------------------------------------------------------------------
- (void) applicationWillResignActive:(UIApplication*)application
{
  if (ComputerVsComputerGame == [GoGame sharedGame].type)
  {
    PauseGameCommand* command = [[PauseGameCommand alloc] init];
    [command submit];
  }
  self.soundHandling.disabled = true;
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that the application has become
/// active (again).
// -----------------------------------------------------------------------------
- (void) applicationDidBecomeActive:(UIApplication*)application
{
  self.soundHandling.disabled = false;
  // Send this notification just in case something changed in the documents
  // folder since the app was deactivated. Note: This is not just laziness - if
  // the user really *DID* change something via the file sharing feature of
  // iTunes, we won't be notified in any special way. The only thing that
  // happens in such a case is deactivation and reactivation.
  // Update for iOS 5: This no longer works in iOS 5
  [[NSNotificationCenter defaultCenter] postNotificationName:archiveContentChanged object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that the application has entered the
/// background and is about to be suspended.
///
/// This method must complete within 5 seconds.
// -----------------------------------------------------------------------------
- (void) applicationDidEnterBackground:(UIApplication*)application
{
  [[[BackupGameCommand alloc] init] submit];
  [self writeUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that the application is about to
/// come to the foreground (after having been suspended in the background).
// -----------------------------------------------------------------------------
- (void) applicationWillEnterForeground:(UIApplication*)application
{
  [[[CleanBackupCommand alloc] init] submit];
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that system memory is running low,
/// combined with the imperative request to free as much memory as possible.
// -----------------------------------------------------------------------------
- (void) applicationDidReceiveMemoryWarning:(UIApplication*)application
{
  DDLogWarn(@"ApplicationDelegate received memory warning");
  // Save whatever data we can before the system kills the application
  [[[BackupGameCommand alloc] init] submit];
  [self writeUserDefaults];
  // Even though we can't really do anything about the situation, we still need
  // to notify the user so that he knows what's going on, or why the application
  // is probably going to be terminated in a moment.
//  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Low Memory"
//                                                  message:@"Little Go uses too much memory, it may be terminated by the system in a moment!\n\n"
//                                                           " Consider lowering the computer player's memory consumption (Settings > Players & Profiles)"
//                                                           " to prevent this warning from appearing in the future."
//                                                 delegate:nil
//                                        cancelButtonTitle:nil
//                                        otherButtonTitles:@"Ok", nil];
//  alert.tag = MemoryWarningAlertView;
//  [alert show];
}

// -----------------------------------------------------------------------------
/// @brief Sets up application logging.
// -----------------------------------------------------------------------------
- (void) setupLogging
{
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  self.fileLogger = [[[DDFileLogger alloc] init] autorelease];
  [DDLog addLogger:self.fileLogger];
  DDLogInfo(@"Log directory is %@", [self.fileLogger.logFileManager logsDirectory]);
}

// -----------------------------------------------------------------------------
/// @brief Sets up a number of folders in the application bundle, creating them
/// if they do not exist.
// -----------------------------------------------------------------------------
- (void) setupFolders
{
  // TODO: Reimplement with loop over a list that was previously filled with
  // the enum values representing the required directories
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, expandTilde);
  NSString* documentsDirectory = [paths objectAtIndex:0];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if (! [fileManager fileExistsAtPath:documentsDirectory])
  {
    [fileManager createDirectoryAtPath:documentsDirectory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
  }
  paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
  NSString* appSupportDirectory = [paths objectAtIndex:0];
  if (! [fileManager fileExistsAtPath:appSupportDirectory])
  {
    [fileManager createDirectoryAtPath:appSupportDirectory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets up the bundle that contains the application's resources. This
/// method does nothing if the @e resourceBundle property is not nil.
// -----------------------------------------------------------------------------
- (void) setupResourceBundle
{
  if (! self.resourceBundle)
    self.resourceBundle = [NSBundle mainBundle];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the registration domain in the user defaults system. This
/// must be done before application models are initialized with data from the
/// user defaults.
// -----------------------------------------------------------------------------
- (void) setupRegistrationDomain
{
  NSString* defaultsPathName = [self.resourceBundle pathForResource:registrationDomainDefaultsResource ofType:nil];
  NSDictionary* defaultsDictionary = [NSDictionary dictionaryWithContentsOfFile:defaultsPathName];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the various application models with values from the user
/// defaults system.
// -----------------------------------------------------------------------------
- (void) setupUserDefaults
{
  // Upgrade user defaults data before the model objects access it. For this to
  // work we need to have the registration defaults in place.
  [UserDefaultsUpdater upgrade];

  // Create model objects and load values from the user defaults system
  self.theNewGameModel = [[[NewGameModel alloc] init] autorelease];
  self.playerModel = [[[PlayerModel alloc] init] autorelease];
  self.gtpEngineProfileModel = [[[GtpEngineProfileModel alloc] init] autorelease];
  self.playViewModel = [[[PlayViewModel alloc] init] autorelease];
  self.scoringModel = [[[ScoringModel alloc] init] autorelease];
  self.archiveViewModel = [[[ArchiveViewModel alloc] init] autorelease];
  self.gtpLogModel = [[[GtpLogModel alloc] init] autorelease];
  self.gtpCommandModel = [[[GtpCommandModel alloc] init] autorelease];
  [self.theNewGameModel readUserDefaults];
  [self.playerModel readUserDefaults];
  [self.gtpEngineProfileModel readUserDefaults];
  [self.playViewModel readUserDefaults];
  [self.scoringModel readUserDefaults];
  [self.archiveViewModel readUserDefaults];
  [self.gtpLogModel readUserDefaults];
  [self.gtpCommandModel readUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Writes the current user preferences to the user defaults system.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  [self.theNewGameModel writeUserDefaults];
  [self.playerModel writeUserDefaults];
  [self.gtpEngineProfileModel writeUserDefaults];
  [self.playViewModel writeUserDefaults];
  [self.scoringModel writeUserDefaults];
  [self.archiveViewModel writeUserDefaults];
  [self.gtpLogModel writeUserDefaults];
  [self.gtpCommandModel writeUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the objects used to manage sound and vibration.
// -----------------------------------------------------------------------------
- (void) setupSound
{
  self.soundHandling = [[SoundHandling alloc] init];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the objects used to manage the GUI.
// -----------------------------------------------------------------------------
- (void) setupGUI
{
  [self.window addSubview:tabBarController.view];
  [self.window makeKeyAndVisible];
  // Disable edit button in the "more" navigation controller
  self.tabBarController.customizableViewControllers = [NSArray array];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the GTP engine and client (always Fuego).
///
/// In a regular desktop environment, engine and client would be launched in
/// separate processes, which would then communicate via stdin/stdout. Since
/// there is no way to launch separate processes under iOS, engine and client
/// run in separate threads, and they communicate via named pipes.
// -----------------------------------------------------------------------------
- (void) setupFuego
{
  mode_t pipeMode = S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH;
  NSString* tempDir = NSTemporaryDirectory();
  NSString* inputPipePath = [NSString pathWithComponents:[NSArray arrayWithObjects:tempDir, @"inputPipe", nil]];
  NSString* outputPipePath = [NSString pathWithComponents:[NSArray arrayWithObjects:tempDir, @"outputPipe", nil]];
  std::vector<std::string> pipeList;
  pipeList.push_back([inputPipePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
  pipeList.push_back([outputPipePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
  std::vector<std::string>::const_iterator it = pipeList.begin();
  for (; it != pipeList.end(); ++it)
  {
    std::string pipePath = *it;
    std::cout << "Creating input pipe " << pipePath << std::endl;
    // TODO: Check if pipes already exist, and/or clean them up when the
    // application shuts down
    int status = mkfifo(pipePath.c_str(), pipeMode);
    if (status == 0)
      std::cout << "Success!" << std::endl;
    else
    {
      std::cout << "Failure! Reason = ";
      switch (errno)
      {
        case EACCES:
          std::cout << "EACCES" << std::endl;
          break;
        case EEXIST:
          std::cout << "EEXIST" << std::endl;
          break;
        case ELOOP:
          std::cout << "ELOOP" << std::endl;
          break;
        case ENOENT:
          std::cout << "ENOENT" << std::endl;
          break;
        case EROFS:
          std::cout << "EROFS" << std::endl;
          break;
        default:
          std::cout << "Some other result: " << status << std::endl;
          break;
      }
    }
  }
  self.gtpClient = [GtpClient clientWithInputPipe:inputPipePath outputPipe:outputPipePath];
  self.gtpEngine = [GtpEngine engineWithInputPipe:inputPipePath outputPipe:outputPipePath];
}

// -----------------------------------------------------------------------------
/// @brief Activates the tab identified by @a tabID, making it visible to the
/// user.
///
/// This method works correctly even if the tab is located in the "More"
/// navigation controller.
// -----------------------------------------------------------------------------
- (void) activateTab:(enum TabType)tabID
{
  for (UIViewController* controller in tabBarController.viewControllers)
  {
    if (controller.tabBarItem.tag == tabID)
    {
      tabBarController.selectedViewController = controller;
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Loads the content of the text resource named @a resourceName.
// -----------------------------------------------------------------------------
- (NSString*) contentOfTextResource:(NSString*)resourceName
{
  if (! resourceName)
    return @"";
  NSURL* resourceURL = [[ApplicationDelegate sharedDelegate].resourceBundle URLForResource:resourceName
                                                                             withExtension:nil];
  NSStringEncoding usedEncoding;
  NSError* error;
  return [NSString stringWithContentsOfURL:resourceURL
                              usedEncoding:&usedEncoding
                                     error:&error];
}

// -----------------------------------------------------------------------------
/// @brief Maps TabType values to resource file names. The name that is returned
/// can be used with NSBundle to load the resource file's content.
// -----------------------------------------------------------------------------
- (NSString*) resourceNameForTabType:(enum TabType)tabType
{
  NSString* resourceName = nil;
  switch (tabType)
  {
    case ManualTab:
      resourceName = manualDocumentResource;
      break;
    case AboutTab:
      resourceName = aboutDocumentResource;
      break;
    case SourceCodeTab:
      resourceName = sourceCodeDocumentResource;
      break;
    case CreditsTab:
      resourceName = creditsDocumentResource;
      break;
    default:
      break;
  }
  return resourceName;
}

// -----------------------------------------------------------------------------
/// @brief Spins off a secondary thread which will perform the application
/// setup, then returns immediately.
// -----------------------------------------------------------------------------
- (void) launchAsynchronously
{
  // Must be invoked so that MainWindow.xib is loaded. Shortly after this method
  // returns the launch image will go away and the main window will come to the
  // front. If setupGui() were performed inside the secondary thread, the main
  // window would not be ready when the launch image goes away and the user
  // would see a white screen.
  [self setupGUI];

  UIView* theSuperView = self.tabBarController.view;
  MBProgressHUD* progressHUD = [[MBProgressHUD alloc] initWithView:theSuperView];
  [theSuperView addSubview:progressHUD];
  progressHUD.mode = MBProgressHUDModeDeterminate;
  progressHUD.determinateStyle = MBDeterminateStyleBar;
  progressHUD.dimBackground = YES;
  progressHUD.delegate = self;
  progressHUD.labelText = @"Just a moment, please...";
  [progressHUD showWhileExecuting:@selector(launchWithProgressHUD:) onTarget:self withObject:progressHUD animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Performs the entire application setup.
///
/// @note This method runs in a secondary thread. For every setup operation
/// that is performed, the progress view in @e progressHUD is updated by one
/// step.
// -----------------------------------------------------------------------------
- (void) launchWithProgressHUD:(MBProgressHUD*)progressHUD
{
  const int totalSteps = 9;
  const float stepIncrease = 1.0 / totalSteps;
  float progress = 0.0;

  [self setupLogging];
  progress += stepIncrease;
  progressHUD.progress = progress;

  [self setupFolders];
  progress += stepIncrease;
  progressHUD.progress = progress;
  
  [self setupResourceBundle];
  progress += stepIncrease;
  progressHUD.progress = progress;
  
  [self setupRegistrationDomain];
  progress += stepIncrease;
  progressHUD.progress = progress;
  
  [self setupUserDefaults];
  progress += stepIncrease;
  progressHUD.progress = progress;

  [self setupSound];
  progress += stepIncrease;
  progressHUD.progress = progress;

  [self setupFuego];
  progress += stepIncrease;
  progressHUD.progress = progress;

  self.applicationReadyForAction = true;
  [[NSNotificationCenter defaultCenter] postNotificationName:applicationIsReadyForAction object:nil];
  progress += stepIncrease;
  progressHUD.progress = progress;

  [[[LoadOpeningBookCommand alloc] init] submit];
  progress += stepIncrease;
  progressHUD.progress = progress;
}

// -----------------------------------------------------------------------------
/// @brief MBProgressHUDDelegate method
///
/// This method runs in the main thread.
// -----------------------------------------------------------------------------
- (void) hudWasHidden:(MBProgressHUD*)progressHUD
{
  [progressHUD removeFromSuperview];
  [progressHUD release];

  // Important: We must execute this command in the context of a thread that
  // survives the entire command execution - see the class documentation of
  // RestoreGameCommand for the reason why.
  [[[RestoreGameCommand alloc] init] submit];
}

@end
