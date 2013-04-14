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


// Project includes
#import "ArchiveViewModel.h"
#import "ArchiveGame.h"
#import "../go/GoGame.h"
#import "../go/GoPlayer.h"
#import "../player/Player.h"
#import "../utility/PathUtilities.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ArchiveViewModel.
// -----------------------------------------------------------------------------
@interface ArchiveViewModel()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSArray* gameList;
//@}
@end


@implementation ArchiveViewModel

// -----------------------------------------------------------------------------
/// @brief Initializes a ArchiveViewModel object with user defaults data.
///
/// @note This is the designated initializer of ArchiveViewModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.archiveFolder = [PathUtilities archiveFolderPath];

  self.gameList = [NSMutableArray arrayWithCapacity:0];
  self.sortCriteria = ArchiveSortCriteriaFileName;
  self.sortAscending = true;

  [self updateGameList];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(archiveContentChanged:) name:archiveContentChanged object:nil];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ArchiveViewModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.archiveFolder = nil;
  self.gameList = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:archiveViewKey];
  self.sortCriteria = [[dictionary valueForKey:sortCriteriaKey] intValue];
  self.sortAscending = [[dictionary valueForKey:sortAscendingKey] boolValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithInt:self.sortCriteria] forKey:sortCriteriaKey];
  [dictionary setValue:[NSNumber numberWithBool:self.sortAscending] forKey:sortAscendingKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:archiveViewKey];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #archiveContentChanged notification.
// -----------------------------------------------------------------------------
- (void) archiveContentChanged:(NSNotification*)notification
{
  [self updateGameList];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (int) gameCount
{
  return self.gameList.count;
}

// -----------------------------------------------------------------------------
/// @brief Returns the game object located at position @a index in the gameList
/// array.
// -----------------------------------------------------------------------------
- (ArchiveGame*) gameAtIndex:(int)index
{
  return [self.gameList objectAtIndex:index];
}

// -----------------------------------------------------------------------------
/// @brief Returns the game object with name @a name.
// -----------------------------------------------------------------------------
- (ArchiveGame*) gameWithName:(NSString*)name
{
  NSString* fileName = [name stringByAppendingString:@".sgf"];
  return [self gameWithFileName:fileName];
}

// -----------------------------------------------------------------------------
/// @brief Returns the game object with file name @a fileName.
// -----------------------------------------------------------------------------
- (ArchiveGame*) gameWithFileName:(NSString*)fileName
{
  for (ArchiveGame* game in self.gameList)
  {
    if ([game.fileName isEqualToString:fileName])
      return game;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Updates the game list array so that its content matches the content
/// of the document folder.
// -----------------------------------------------------------------------------
- (void) updateGameList
{
  NSArray* fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.archiveFolder error:nil];
  NSMutableArray* localGameList = [NSMutableArray arrayWithCapacity:fileList.count];
  for (NSString* fileName in fileList)
  {
    if ([self shouldIgnoreFileName:fileName])
      continue;
    NSString* filePath = [self.archiveFolder stringByAppendingPathComponent:fileName];
    NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    ArchiveGame* game = [self gameWithFileName:fileName];
    if (game)
      [game updateFileAttributes:fileAttributes];
    else
      game = [[[ArchiveGame alloc] initWithFileName:fileName fileAttributes:fileAttributes] autorelease];
    [localGameList addObject:game];
  }
  // TODO: sort by file date if self.sortCriteria says so. It might be
  // interesting to have a look at NSComparator and blocks.
  NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil
                                                                   ascending:self.sortAscending
                                                                    selector:@selector(compare:)];
  [localGameList sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

  // Replace entire array to trigger KVO
  self.gameList = localGameList;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a fileName is not an archived game and should be
/// ignored by this model.
// -----------------------------------------------------------------------------
- (bool) shouldIgnoreFileName:(NSString*)fileName
{
  if ([fileName isEqualToString:@"Logs"])  // ignore logging framework folder
    return true;
  if ([fileName isEqualToString:bugReportDiagnosticsInformationFileName])
    return true;
  if ([fileName isEqualToString:inboxFolderName])  // ignore folder where document interaction places file
    return true;
  return false;
}

// -----------------------------------------------------------------------------
/// @brief Returns a unique name that can be used to save @a game right now.
/// The name is guaranteed to be unique only at the time this method is invoked.
///
/// The name is suitable for display in the UI. The name pattern is
/// "BBB vs. WWW iii", where
/// - BBB = Black player name
/// - WWW = White player name
/// - iii = Numeric counter starting with 1. The counter does not use prefix
///         zeroes.
// -----------------------------------------------------------------------------
- (NSString*) uniqueGameNameForGame:(GoGame*)game;
{
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* uniqueGameName = nil;
  NSString* prefix = [NSString stringWithFormat:@"%@ vs. %@", game.playerBlack.player.name, game.playerWhite.player.name];
  int suffix = 1;
  while (true)
  {
    uniqueGameName = [NSString stringWithFormat:@"%@ %d", prefix, suffix];
    NSString* uniqueFileName = [uniqueGameName stringByAppendingString:@".sgf"];
    NSString* uniqueFilePath = [self.archiveFolder stringByAppendingPathComponent:uniqueFileName];
    if (! [fileManager fileExistsAtPath:uniqueFilePath])
      break;
    suffix++;
  }
  return uniqueGameName;
}

// -----------------------------------------------------------------------------
/// @brief Returns a unique name for @a preferredGameName that can be used to
/// save a game right now. The name is guaranteed to be unique only at the time
/// this method is invoked.
///
/// If no other game exists with the same name, this method returns a copy of
/// @a preferredGameName.
///
/// If another game with the same name already exists, this method adds a suffix
/// to @a preferredGameName to make the preferred game name unique. The pattern
/// is "preferredGameName iii", where
/// - iii = Numeric counter starting with 1. The counter does not use prefix
///         zeroes. If a game with counter 1 already exists, the counter is
///         increased to 2, etc.
// -----------------------------------------------------------------------------
- (NSString*) uniqueGameNameForName:(NSString*)preferredGameName
{
  if (! [self gameWithName:preferredGameName])
    return [preferredGameName copy];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* uniqueGameName = nil;
  int suffix = 1;
  while (true)
  {
    uniqueGameName = [NSString stringWithFormat:@"%@ %d", preferredGameName, suffix];
    NSString* uniqueFileName = [uniqueGameName stringByAppendingString:@".sgf"];
    NSString* uniqueFilePath = [self.archiveFolder stringByAppendingPathComponent:uniqueFileName];
    if (! [fileManager fileExistsAtPath:uniqueFilePath])
      break;
    suffix++;
  }
  return uniqueGameName;
}

// -----------------------------------------------------------------------------
/// @brief Returns the full file path of the game whose name is @a name. The
/// file path may or may not refer to an already existing file.
// -----------------------------------------------------------------------------
- (NSString*) filePathForGameWithName:(NSString*)name
{
  NSString* fileName = [name stringByAppendingString:@".sgf"];
  NSString* filePath = [self.archiveFolder stringByAppendingPathComponent:fileName];
  return filePath;
}

@end
