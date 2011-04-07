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
// -----------------------------------------------------------------------------
@interface GoBoardRegion : NSObject
{
}

+ (GoBoardRegion*) regionWithPoints:(NSArray*)points;
+ (GoBoardRegion*) regionWithPoint:(GoPoint*)point;
- (int) size;
- (bool) hasPoint:(GoPoint*)point;
- (void) addPoint:(GoPoint*)point;
- (void) removePoint:(GoPoint*)point;
- (void) joinRegion:(GoBoardRegion*)region;
- (bool) isStoneGroup;
- (bool) hasBlackStones;
- (int) liberties;

/// @brief List of GoPoint objects in this GoBoardRegion. The list is
/// unordered.
@property(assign) NSArray* points;
/// @brief A random color that can be used to mark GoPoints in this
/// GoBoardRegion. This is intended as a debugging aid.
@property(retain) UIColor* color;

@end
