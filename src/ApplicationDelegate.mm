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
#import "gtp/GtpClient.h"
#import "gtp/GtpEngine.h"
#import "newgame/NewGameModel.h"
#import "player/PlayerModel.h"
#import "play/PlayViewModel.h"
#import "play/SoundHandling.h"
#import "archive/ArchiveViewModel.h"
#import "command/CommandProcessor.h"
#import "command/backup/BackupGameCommand.h"
#import "command/backup/CleanBackupCommand.h"
#import "command/backup/RestoreGameCommand.h"

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
@end


@implementation ApplicationDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize resourceBundle;
@synthesize gtpClient;
@synthesize gtpEngine;
@synthesize newGameModel;
@synthesize playerModel;
@synthesize playViewModel;
@synthesize soundHandling;
@synthesize game;
@synthesize archiveViewModel;


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
  @synchronized(self)
  {
    assert(sharedDelegate != nil);
    return sharedDelegate;
  }
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
  self.newGameModel = nil;
  self.playerModel = nil;
  self.playViewModel = nil;
  self.soundHandling = nil;
  self.game = nil;
  self.archiveViewModel = nil;
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

  // Changing current working directory to documents folder is important so
  // that the "savesgf" and "loadsgf" GTP commands can be submitted using a
  // simple filename only. If we had to specify the full path to the documents
  // folder, we would be in trouble because that path contains spaces, but the
  // GTP protocol does not support spaces in command arguments.
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, expandTilde);
  NSString* documentsDirectory = [paths objectAtIndex:0];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  [fileManager changeCurrentDirectoryPath:documentsDirectory];

  [self setupFolders];
  [self setupResourceBundle];
  [self setupUserDefaults];
  [self setupGUI];
  [self setupFuego];

  // TODO: Display splash screen
  // TODO Execute the command synchronously while the splash screen is visible
  [[[RestoreGameCommand alloc] init] submit];
  // TODO: Dispose of the splash screen

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
/// - Any interrupt (e.g. incoming phone call, calling up the multitasking UI)
/// - Anything that will put the app in the background
// -----------------------------------------------------------------------------
- (void) applicationWillResignActive:(UIApplication*)application
{
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that the application has become
/// active (again).
// -----------------------------------------------------------------------------
- (void) applicationDidBecomeActive:(UIApplication*)application
{
  // Send this notification just in case something changed in the documents
  // folder since the app was deactivated. Note: This is not just laziness - if
  // the user really *DID* change something via the file sharing feature of
  // iTunes, we won't be notified in any special way. The only thing that
  // happens in such a case is deactivation and reactivation.
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
  [self.newGameModel writeUserDefaults];
  [self.playerModel writeUserDefaults];
  [self.playViewModel writeUserDefaults];
  [self.archiveViewModel writeUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that the application is about to
/// come to the foreground (after having been suspended in the background).
// -----------------------------------------------------------------------------
- (void) applicationWillEnterForeground:(UIApplication*)application
{
  [[[CleanBackupCommand alloc] init] submit];
}

- (void) applicationDidReceiveMemoryWarning:(UIApplication*)application
{
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
/// @brief Sets up the various application models with values from the user
/// defaults system.
// -----------------------------------------------------------------------------
- (void) setupUserDefaults
{
  // Set up application defaults *BEFORE* loading user defaults
  NSString* defaultsPathName = [self.resourceBundle pathForResource:registrationDomainDefaultsResource ofType:nil];
  NSDictionary* defaultsDictionary = [NSDictionary dictionaryWithContentsOfFile:defaultsPathName];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];

  // Create model objects and load values from the user defaults system
  self.newGameModel = [[[NewGameModel alloc] init] autorelease];
  self.playerModel = [[[PlayerModel alloc] init] autorelease];
  self.playViewModel = [[[PlayViewModel alloc] init] autorelease];
  self.archiveViewModel = [[[ArchiveViewModel alloc] init] autorelease];
  [self.newGameModel readUserDefaults];
  [self.playerModel readUserDefaults];
  [self.playViewModel readUserDefaults];
  [self.archiveViewModel readUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the objects used to manage the GUI.
// -----------------------------------------------------------------------------
- (void) setupGUI
{
  [self.window addSubview:tabBarController.view];
  [self.window makeKeyAndVisible];
  self.soundHandling = [[SoundHandling alloc] init];
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

@end
