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
/// displayed in the UI.
@property(nonatomic, readonly) NSString* name;
/// @brief The filename of the .sgf file.
@property(retain) NSString* fileName;
/// @brief The modification date of the .sgf file.
@property(retain) NSString* fileDate;
/// @brief The size of the .sgf file.
@property(retain) NSString* fileSize;

@end
