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


// Forward declarations
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The GoBoardRegion class is a collection of neighbouring GoPoint
/// objects.
///
/// @ingroup go
///
/// GoPoint objects within a GoBoardRegion either all have a stone placed on
/// them (in which case the GoBoardRegion represents a stone group), or they all
/// have no stone (in which case the GoBoardRegion represents an empty area).
/// If the GoBoardRegion represents a stone group, all stones are of the same
/// color.
///
/// Every GoPoint object is always part of a GoBoardRegion. At the beginning of
/// a game there is a single GoBoardRegion that represents the entire board; it
/// contains all existing GoPoint objects. As the game progresses, the initial
/// GoBoardRegion is fragmented into smaller GoBoardRegion objects.
///
/// GoBoardRegion is retained by its GoPoint objects (see the GoPoint::region
/// property). A GoBoardRegion is therefore released when it is no longer
/// referenced by any GoPoint objects.
///
///
/// @par Scoring mode
///
/// GoBoardRegion assumes that if scoring mode is enabled (via setting of the
/// correspondingly named property) the state of the Go board remains static,
/// i.e. no stones are placed or removed. Operating under this assumption,
/// GoBoardRegion starts to aggressively cache information that is otherwise
/// computed dynamically. The benefit is improved performance during scoring.
///
/// Clients do not need to know or care about which pieces of information are
/// cached, this is an implementation detail.
// -----------------------------------------------------------------------------
@interface GoBoardRegion : NSObject <NSCoding>
{
}

+ (GoBoardRegion*) region;
+ (GoBoardRegion*) regionWithPoint:(GoPoint*)point;
- (int) size;
- (void) addPoint:(GoPoint*)point;
- (void) removePoint:(GoPoint*)point;
- (void) joinRegion:(GoBoardRegion*)region;
- (bool) isStoneGroup;
- (enum GoColor) color;
- (int) liberties;
- (NSArray*) adjacentRegions;

/// @brief List of GoPoint objects in this GoBoardRegion. The list is
/// unordered.
@property(nonatomic, readonly, retain) NSArray* points;
/// @brief A random color that can be used to mark GoPoints in this
/// GoBoardRegion. This is intended as a debugging aid.
@property(nonatomic, retain) UIColor* randomColor;
/// @brief Flag is true if scoring mode is enabled. See class documentation for
/// details.
@property(nonatomic, assign) bool scoringMode;
/// @brief During scoring denotes which territory this GoBoardRegion belongs to.
@property(nonatomic, assign) enum GoColor territoryColor;
/// @brief Flag is true if the territory scoring algorithm detected an
/// inconsistency and was unable to assign a territory color to this region.
///
/// If this flag is true, the property @e territoryColor has value #GoColorNone.
/// However, it cannot be concluded from this that the region is truly neutral.
@property(nonatomic, assign) bool territoryInconsistencyFound;
/// @brief During scoring denotes whether the stones in the stone group
/// represented by this GoBoardRegion are dead or alive. Is false if this
/// GoBoardRegion is not a stone group.
@property(nonatomic, assign) bool deadStoneGroup;

@end
