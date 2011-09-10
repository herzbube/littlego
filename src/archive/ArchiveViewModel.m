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
#import "ArchiveViewModel.h"
#import "ArchiveGame.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ArchiveViewModel.
// -----------------------------------------------------------------------------
@interface ArchiveViewModel()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
- (void) updateGameList;
//@}
/// @name Notification responders
//@{
- (void) archiveContentChanged:(NSNotification*)notification;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(readwrite, retain) NSArray* gameList;
//@}
@end


@implementation ArchiveViewModel

@synthesize gameList;
@synthesize sortCriteria;
@synthesize sortAscending;


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

  self.gameList = [NSMutableArray arrayWithCapacity:0];
  self.sortCriteria = FileNameArchiveSort;
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
  [userDefaults setObject:dictionary forKey:playViewKey];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #archiveContentChanged notification.
// -----------------------------------------------------------------------------
- (void) archiveContentChanged:(NSNotification*)notification
{
  [self updateGameList];
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of save games that this model has information
/// about.
// -----------------------------------------------------------------------------
- (int) gameCount
{
  return gameList.count;
}

// -----------------------------------------------------------------------------
/// @brief Returns the game object located at position @a index in the gameList
/// array.
// -----------------------------------------------------------------------------
- (ArchiveGame*) gameAtIndex:(int)index
{
  return [gameList objectAtIndex:index];
}

// -----------------------------------------------------------------------------
/// @brief Returns the game object with file name @a fileName.
// -----------------------------------------------------------------------------
- (ArchiveGame*) gameWithFileName:(NSString*)fileName
{
  for (ArchiveGame* game in gameList)
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
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, expandTilde);
  NSString* documentsDirectory = [paths objectAtIndex:0];
  NSArray* fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];

  NSMutableArray* localGameList = [NSMutableArray arrayWithCapacity:fileList.count];
  for (NSString* fileName in fileList)
  {
    NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:nil];
    ArchiveGame* game = [self gameWithFileName:fileName];
    if (game)
      [game updateFileAttributes:fileAttributes];
    else
      game = [[[ArchiveGame alloc] initWithFileName:(NSString*)fileName fileAttributes:fileAttributes] autorelease];
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

@end
