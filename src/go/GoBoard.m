// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "../main/ApplicationDelegate.h"
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
- (void) setupBoard;
- (void) setupGoPoints;
- (void) setupStarPoints;
//@}
/// @name NSCoding protocol
//@{
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
//@}
/// @name Other methods
//@{
- (NSString*) description;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoBoardSize size;
@property(nonatomic, retain, readwrite) NSArray* starPoints;
//@}
- (NSArray*) starPointVertexes;
@end


@implementation GoBoard

@synthesize size;
@synthesize starPoints;

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoBoard instance which uses the
/// "New Game" default board size.
// -----------------------------------------------------------------------------
+ (GoBoard*) newGameBoard
{
  NewGameModel* model = [ApplicationDelegate sharedDelegate].theNewGameModel;
  return [GoBoard boardWithSize:model.boardSize];
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoBoard instance of size @a size.
///
/// Raises an @e NSInvalidArgumentException if @a size is #GoBoardSizeUndefined
/// or otherwise invalid.
// -----------------------------------------------------------------------------
+ (GoBoard*) boardWithSize:(enum GoBoardSize)size;
{
  switch (size)
  {
    case GoBoardSize7:
    case GoBoardSize9:
    case GoBoardSize11:
    case GoBoardSize13:
    case GoBoardSize15:
    case GoBoardSize17:
    case GoBoardSize19:
    {
      break;
    }
    case GoBoardSizeUndefined:
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Board size %d is invalid", size]
                                                     userInfo:nil];
      @throw exception;
    }
  }

  GoBoard* board = [[GoBoard alloc] initWithSize:size];
  if (board)
    [board autorelease];
  return board;
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a size that is suitable
/// for displaying in the UI.
///
/// Returns the string "Undefined" if @a size is #GoBoardSizeUndefined.
/// 
/// Raises an @e NSInvalidArgumentException if @a size is otherwise invalid.
// -----------------------------------------------------------------------------
+ (NSString*) stringForSize:(enum GoBoardSize)size
{
  switch (size)
  {
    case GoBoardSize7:
    case GoBoardSize9:
    case GoBoardSize11:
    case GoBoardSize13:
    case GoBoardSize15:
    case GoBoardSize17:
    case GoBoardSize19:
    {
      return [NSString stringWithFormat:@"%d", size];
    }
    case GoBoardSizeUndefined:
    {
      return @"Undefined";
    }
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Board size %d is invalid", size]
                                                     userInfo:nil];
      @throw exception;
    }
  }
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

  self.size = boardSize;
  m_vertexDict = [[NSMutableDictionary dictionary] retain];
  starPoints = nil;

  [self setupBoard];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;

  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;
  self.size = [decoder decodeIntForKey:goBoardSizeKey];
  m_vertexDict = [[decoder decodeObjectForKey:goBoardVertexDictKey] retain];
  self.starPoints = [decoder decodeObjectForKey:goBoardStarPointsKey];

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
/// @brief Sets up this GoBoard.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupBoard
{
  // Order of invocation is important
  [self setupGoPoints];
  [self setupStarPoints];
}

// -----------------------------------------------------------------------------
/// @brief Creates all GoPoint objects that belong to a single GoBoardRegion.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupGoPoints
{
  // Implementation note: It is tempting to create only a single GoPoint at A1
  // and let lazy initialization in pointAtVertex:() figure out the rest. This
  // poses the problem, though, that the lazy initialiation part of
  // pointAtVertex:() would become quite expensive, because it would need to be
  // able to handle the scenario that a GoPoint is created at a time when the
  // initial big GoBoardRegion has already become fragmented into smaller
  // regions. Let's consider the tradeoffs between the two variants:
  //   1) Performing expensive setup operation during initialization of GoBoard
  //   2) Performing expensive operation during lazy initialization of a GoPoint
  // Creation of a GoBoard object is a relatively rare event (once per new
  // game), whereas creation of a GoPoint object happens much more often (up to
  // 381 times on a 19x19 board). From this point of view alone, I would already
  // say that variant 1 is probably more efficient than variant 2. But what's
  // even more important than pure efficiency is that in variant 1 the handling
  // of a single GoBoardRegion is very simple and straightforward, whereas in
  // variant 2 we would need to handle many regions, requiring a more difficult
  // implementation whose maintenance is much more prone to errors.
  //
  // Bottom line: Let's KISS :-)

  // Create an initial GoPoint and GoBoardRegion object
  GoPoint* point = [self pointAtVertex:@"A1"];
  GoBoardRegion* region = [GoBoardRegion region];

  // On a clear board, the initial region contains all GoPoint objects.
  // Note: Moving to the next point creates the corresponding GoPoint object!
  for (; point != nil; point = point.next)
    [region addPoint:point];
}

// -----------------------------------------------------------------------------
/// @brief Determines all GoPoint objects that are star points.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupStarPoints
{
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
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoBoard object.
///
/// This method is invoked when GoBoard needs to be represented as a string,
/// i.e. by NSLog, or when the debugger command "po" is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GoBoard(%p): size = %d", self, size];
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
  vertex = [vertex uppercaseString];
  GoPoint* point = [m_vertexDict objectForKey:vertex];
  if (! point)
  {
    point = [GoPoint pointAtVertex:[GoVertex vertexFromString:vertex] onBoard:self];
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
/// @note #GoBoardDirectionNext and #GoBoardDirectionPrevious are intended to
/// iterate over all existing GoPoint objects.
///
/// @internal This is the backend for the GoPoint directional properties (e.g.
/// GoPoint::left()).
// -----------------------------------------------------------------------------
- (GoPoint*) neighbourOf:(GoPoint*)point inDirection:(enum GoBoardDirection)direction
{
  struct GoVertexNumeric numericVertex = point.vertex.numeric;
  switch (direction)
  {
    case GoBoardDirectionLeft:
      numericVertex.x--;
      if (numericVertex.x < 1)
        return nil;
      break;
    case GoBoardDirectionRight:
      numericVertex.x++;
      if (numericVertex.x > size)
        return nil;
      break;
    case GoBoardDirectionUp:
      numericVertex.y++;
      if (numericVertex.y > size)
        return nil;
      break;
    case GoBoardDirectionDown:
      numericVertex.y--;
      if (numericVertex.y < 1)
        return nil;
      break;
    case GoBoardDirectionNext:
      numericVertex.x++;
      if (numericVertex.x > size)
      {
        numericVertex.x = 1;
        numericVertex.y++;
        if (numericVertex.y > size)
          return nil;
      }
      break;
    case GoBoardDirectionPrevious:
      numericVertex.x--;
      if (numericVertex.x < 1)
      {
        numericVertex.x = size;
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
// Property is documented in the header file.
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
  NSString* boardSizeKey = [NSString stringWithFormat:@"%d", self.size];
  NSString* starPointVertexListAsString = [dictionary valueForKey:boardSizeKey];
  if (starPointVertexListAsString == nil || [starPointVertexListAsString length] == 0)
    return [NSArray array];
  return [starPointVertexListAsString componentsSeparatedByString:@","];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSArray*) regions
{
  NSMutableArray* regionList = [NSMutableArray arrayWithCapacity:0];
  GoPoint* point = [self pointAtVertex:@"A1"];
  for (; point != nil; point = point.next)
  {
    GoBoardRegion* region = point.region;
    if (! [regionList containsObject:region])
      [regionList addObject:region];
  }
  return regionList;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeInt:self.size forKey:goBoardSizeKey];
  [encoder encodeObject:m_vertexDict forKey:goBoardVertexDictKey];
  [encoder encodeObject:self.starPoints forKey:goBoardStarPointsKey];
}

@end
