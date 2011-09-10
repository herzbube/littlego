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



// Forward declarations
@class ArchiveGame;


// -----------------------------------------------------------------------------
/// @brief The ArchiveViewModel class provides data used to populate the Archive
/// view, as well as user defaults data that describe how the data needs to be
/// displayed (e.g. sorting criteria).
// -----------------------------------------------------------------------------
@interface ArchiveViewModel : NSObject
{
}

- (id) init;
- (void) readUserDefaults;
- (void) writeUserDefaults;
- (ArchiveGame*) gameAtIndex:(int)index;

/// @brief Number of objects in gameList.
///
/// This property exists purely as a convenience to clients, since the object
/// count is also available from the gameList array.
@property(readonly) int gameCount;
/// @brief Array stores objects of type ArchiveGame. The array is already
/// ordered according to the sortCriteria and sortAscending properties.
@property(readonly, retain) NSArray* gameList;
/// @brief Describes the criteria that was used to sort the objects in gameList.
@property enum ArchiveSortCriteria sortCriteria;
/// @brief True if objects in gameList are sorted ascending, false if they are
/// sorted descending.
@property bool sortAscending;

@end
