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
/// @defgroup go Go module
///
/// Classes in this module directly relate to an aspect of the actual Go game
/// (e.g. GoBoard represents the Go board).
// -----------------------------------------------------------------------------


// Project includes
#import "GoBoard.h"
#import "GoBoardRegion.h"
#import "GoPoint.h"
#import "GoVertex.h"
#import "../ApplicationDelegate.h"
#import "../newgame/NewGameModel.h"
#import "../gtp/GtpCommand.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoBoard.
// -----------------------------------------------------------------------------
@interface GoBoard()
/// @name Initialization and deallocation
//@{
- (id) initWithSize:(enum GoBoardSize)boardSize;
- (void) dealloc;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(readwrite) enum GoBoardSize size;
@property(readwrite) int dimensions;
//@}
- (NSArray*) starPointVertexes;
@end


@implementation GoBoard

@synthesize size;
@synthesize dimensions;
@synthesize starPoints;

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoBoard instance which uses the
/// "New Game" default board size.
// -----------------------------------------------------------------------------
+ (GoBoard*) newGameBoard
{
  NewGameModel* model = [ApplicationDelegate sharedDelegate].newGameModel;
  return [GoBoard boardWithSize:model.boardSize];
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoBoard instance of size @a size.
// -----------------------------------------------------------------------------
+ (GoBoard*) boardWithSize:(enum GoBoardSize)size;
{
  GoBoard* board = [[GoBoard alloc] initWithSize:size];
  if (board)
    [board autorelease];
  return board;
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a size that is suitable
/// for displaying in the UI.
// -----------------------------------------------------------------------------
+ (NSString*) stringForSize:(enum GoBoardSize)size
{
  switch (size)
  {
    case BoardSizeUndefined:
      return @"Undefined";
    case BoardSize7:
      return @"7";
    case BoardSize9:
      return @"9";
    case BoardSize11:
      return @"11";
    case BoardSize13:
      return @"13";
    case BoardSize15:
      return @"15";
    case BoardSize17:
      return @"17";
    case BoardSize19:
      return @"19";
    default:
      assert(false);
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the numeric dimension that corresponds to @a size. For
/// instance, 19 will be returned for the enum value #BoardSize19.
// -----------------------------------------------------------------------------
+ (int) dimensionForSize:(enum GoBoardSize)size
{
  switch (size)
  {
    case BoardSizeUndefined:
      return 0;
    case BoardSize7:
      return 7;
    case BoardSize9:
      return 9;
    case BoardSize11:
      return 11;
    case BoardSize13:
      return 13;
    case BoardSize15:
      return 15;
    case BoardSize17:
      return 17;
    case BoardSize19:
      return 19;
    default:
      assert(false);
      break;
  }
  return -1;
}

// -----------------------------------------------------------------------------
/// @brief Returns the board size that corresponds to the numeric @a dimension.
/// For instance, #BoardSize19 will be returned for the numeric value 19.
// -----------------------------------------------------------------------------
+ (enum GoBoardSize) sizeForDimension:(int)dimension
{
  switch (dimension)
  {
    case 7:
      return BoardSize7;
    case 9:
      return BoardSize9;
    case 11:
      return BoardSize11;
    case 13:
      return BoardSize13;
    case 15:
      return BoardSize15;
    case 17:
      return BoardSize17;
    case 19:
      return BoardSize19;
    default:
      assert(false);
      break;
  }
  return BoardSizeUndefined;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoBoard object with size @a boardSize.
///
/// @note This is the designated initializer of GoBoard.
// -----------------------------------------------------------------------------
- (id) initWithSize:(enum GoBoardSize)boardSize
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // Init with "undefined" value so that the setter is properly triggered
  size = BoardSizeUndefined;
  assert(boardSize != BoardSizeUndefined);
  if (boardSize == BoardSizeUndefined)
    return nil;

  // Setting this property 1) also adjusts property dimensions, and 2) triggers
  // creation of all GoPoint objects!
  self.size = boardSize;
  m_vertexDict = [[NSMutableDictionary dictionary] retain];
  starPoints = [[NSArray array] retain];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoBoard object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // Break the retain cycle between GoPoint and GoBoardRegion
  // TODO Change design so that there is no retain cycle. Currently this would
  // mean to mark up the property GoPoint.region with "assign" instead of
  // "retain", but then nobody retains GoBoardRegion...
  for (GoPoint* point in [m_vertexDict allValues])
    point.region = nil;
  [m_vertexDict release];
  [starPoints release];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Adjusts the size of this GoBoard object to @a newValue. Also adjusts
/// property @e dimensions to a value that corresponds to @a newValue.
///
/// This function should only be called while the game has not yet started.
// -----------------------------------------------------------------------------
- (void) setSize:(enum GoBoardSize)newValue
{
  @synchronized(self)
  {
    if (size == newValue)
      return;
    size = newValue;
    self.dimensions = [GoBoard dimensionForSize:newValue];

    // Removing references to GoPoint objects destroys them
    [m_vertexDict removeAllObjects];
    [starPoints release];
    starPoints = nil;

    // Create an initial GoPoint and GoBoardRegion object
    GoPoint* point = [self pointAtVertex:@"A1"];
    GoBoardRegion* region = [GoBoardRegion regionWithPoint:point];
    point.region = region;
    // On a clear board, the initial region contains all GoPoint objects.
    // Note: Moving to the next point creates the corresponding GoPoint object!
    for (; point = point.next; point != nil)
    {
      point.region = region;
      [region addPoint:point];
    }

    // Re-create the list of star points
    NSMutableArray* starPointsLocal = [NSMutableArray arrayWithCapacity:0];
    for (NSString* starPointVertex in [self starPointVertexes])
    {
      GoPoint* starPoint = [self pointAtVertex:starPointVertex];
      starPoint.starPoint = true;
      [starPointsLocal addObject:starPoint];
    }
    // Make a copy that is immutable because we hand out references to the
    // array, and we don't want clients to be able to change the array
    starPoints = [[NSArray arrayWithArray:starPointsLocal] retain];

    // GTP engine must also be notified
    [[GtpCommand command:@"clear_board"] submit];
    [[GtpCommand command:[NSString stringWithFormat:@"boardsize %d", self.dimensions]] submit];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns an enumerator that can be used to iterate over all existing
/// GoPoint objects
///
/// @todo Remove this method, clients should instead use GoPoint::next() or
/// GoPoint::previous() for iteration.
// -----------------------------------------------------------------------------
- (NSEnumerator*) pointEnumerator
{
  // The value array including the enumerator will be destroyed as soon as
  // the current execution path finishes
  return [[m_vertexDict allValues] objectEnumerator];
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object located at @a vertex.
///
/// See the GoVertex class documentation for a discussion of what a vertex is.
// -----------------------------------------------------------------------------
- (GoPoint*) pointAtVertex:(NSString*)vertex
{
  GoPoint* point = [m_vertexDict objectForKey:vertex];
  if (! point)
  {
    point = [GoPoint pointAtVertex:[GoVertex vertexFromString:vertex]];
    [m_vertexDict setObject:point forKey:vertex];
  }
  return point;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoPoint object that is a direct neighbour of @a point
/// located in direction @a direction.
///
/// Returns nil if no neighbour exists in the specified direction. For instance,
/// if @a point is at the left edge of the board, it has no left neighbour,
/// which will cause a nil value to be returned.
///
/// @note #NextDirection and #PreviousDirection are intended to iterate over
/// all existing GoPoint objects.
///
/// @internal This is the backend for the GoPoint directional properties (e.g.
/// GoPoint::left()).
// -----------------------------------------------------------------------------
- (GoPoint*) neighbourOf:(GoPoint*)point inDirection:(enum GoBoardDirection)direction
{
  struct GoVertexNumeric numericVertex = point.vertex.numeric;
  switch (direction)
  {
    case LeftDirection:
      numericVertex.x--;
      if (numericVertex.x < 1)
        return nil;
      break;
    case RightDirection:
      numericVertex.x++;
      if (numericVertex.x > self.dimensions)
        return nil;
      break;
    case UpDirection:
      numericVertex.y++;
      if (numericVertex.y > self.dimensions)
        return nil;
      break;
    case DownDirection:
      numericVertex.y--;
      if (numericVertex.y < 1)
        return nil;
      break;
    case NextDirection:
      numericVertex.x++;
      if (numericVertex.x > self.dimensions)
      {
        numericVertex.x = 1;
        numericVertex.y++;
        if (numericVertex.y > self.dimensions)
          return nil;
      }
      break;
    case PreviousDirection:
      numericVertex.x--;
      if (numericVertex.x < 1)
      {
        numericVertex.x = self.dimensions;
        numericVertex.y--;
        if (numericVertex.y < 1)
          return nil;
      }
      break;
    default:
      return nil;
  }
  GoVertex* vertex = [GoVertex vertexFromNumeric:numericVertex];
  return [self pointAtVertex:vertex.string];
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of GoPoint objects that refer to the star points for
/// the current board size. The returned list has no particular order.
// -----------------------------------------------------------------------------
- (NSArray*) starPoints
{
  return [[starPoints retain] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Returns a list of NSString vertexes that define the star points for
/// the current board size.
///
/// Returns an empty list if the current board size does not have any star
/// points.
///
/// Star point definitions are read from the user defaults system. The
/// definitions are immutable and are available only through the application
/// defaults registered at application startup.
///
/// @note Star point definitions vary depending on which information source is
/// queried. Fuego and Goban.app, for instance, do not have the same definitions
/// for some board sizes. Sensei's Library only has definitions for 9x9, 13x13
/// and 19x19. The current star point definitions in Little Go match those
/// provided by Fuego.
// -----------------------------------------------------------------------------
- (NSArray*) starPointVertexes
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:starPointsKey];
  NSString* boardSizeKey = [NSString stringWithFormat:@"%d", self.dimensions]; 
  NSString* starPointVertexListAsString = [dictionary valueForKey:boardSizeKey];
  if (starPointVertexListAsString == nil || [starPointVertexListAsString length] == 0)
    return [NSArray array];
  return [starPointVertexListAsString componentsSeparatedByString:@","];
}

@end
