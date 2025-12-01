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
/// @brief The ArchiveGame class collects data used to describe an archived game
/// that exists as an .sgf file in the application's document folder.
///
/// Note that the UI presented to the user should not refer to archived games
/// as files. Do not use the value of the @e fileName property to display a
/// reference to an archived game in the UI - instead use the @e name property.
// -----------------------------------------------------------------------------
@interface ArchiveGame : NSObject
{
}

- (id) init;
- (id) initWithFileName:(NSString*)aFileName fileAttributes:(NSDictionary*)fileAttributes;
- (void) updateFileAttributes:(NSDictionary*)fileAttributes;
- (NSComparisonResult) compare:(ArchiveGame*)aGame;

/// @brief The name of the archived game. The value of this property should be
/// displayed in the UI. The value of this property is derived from the value
/// of @a fileName, i.e. changing @a fileName will automatically change the
/// value of this property.
@property(nonatomic, assign, readonly) NSString* name;
/// @brief The filename of the .sgf file.
@property(nonatomic, retain) NSString* fileName;
/// @brief The modification date of the .sgf file.
@property(nonatomic, retain) NSString* fileDate;
/// @brief The size of the .sgf file.
@property(nonatomic, retain) NSString* fileSize;
/// @brief A monotonically increasing counter indicating how many times the
/// underlying .sgf file's content has changed since the ArchiveGame object was
/// created.
///
/// When the ArchiveGame object is initialized the property value is 0. The
/// property value then increases by 1 every time a filesystem operation changes
/// the underlying .sgf file's content. The typical use case for this is when a
/// save operation overwrites the file.
///
/// KVO can be used on the property to detect content changes. A reaction may
/// be to reload the file content.
@property(nonatomic, assign) unsigned long fileContentRevision;
/// @brief Indicates whether a filesystem operation has deleted the underlying
/// .sgf file since the ArchiveGame object was created.
///
/// When the ArchiveGame object is initialized the property value is @e false.
/// The property value changes to @e true when a delete filesystem operation
/// occurs. The property value can never change back to @e false again - if a
/// new .sgf file with the same name is created, a new ArchiveGame object is
/// created to represent that new file.
///
/// KVO can be used on the property to detect that the ArchiveGame has become
/// obsolete. A reaction may be to discard the file content associated with.
/// the ArchiveGame.
@property(nonatomic, assign) bool fileDeleted;

@end
