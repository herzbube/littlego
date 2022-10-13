// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoNodeSetup.h"
#import "GoBoard.h"
#import "GoGame.h"
#import "GoPoint.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoNodeSetup.
// -----------------------------------------------------------------------------
@interface GoNodeSetup()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoColor previousSetupFirstMoveColor;
//@}
@property(nonatomic, retain) NSMutableArray* mutableBlackSetupStones;
@property(nonatomic, retain) NSMutableArray* mutableWhiteSetupStones;
@property(nonatomic, retain) NSMutableArray* mutableNoSetupStones;
@property(nonatomic, retain) NSMutableArray* mutablePreviousBlackSetupStones;
@property(nonatomic, retain) NSMutableArray* mutablePreviousWhiteSetupStones;
@end


@implementation GoNodeSetup

// -----------------------------------------------------------------------------
/// @brief Initializes a GoNodeSetup object.
///
/// @note This is the designated initializer of GoNodeSetup.
// -----------------------------------------------------------------------------
- (id) initWithGame:(GoGame*)game
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.mutableBlackSetupStones = nil;
  self.mutableWhiteSetupStones = nil;
  self.mutableNoSetupStones = nil;
  self.setupFirstMoveColor = GoColorNone;
  self.mutablePreviousBlackSetupStones = nil;
  self.mutablePreviousWhiteSetupStones = nil;
  self.previousSetupFirstMoveColor = GoColorNone;

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

  // TODO xxx
//  self.type = [decoder decodeIntForKey:goMoveTypeKey];
//  self.player = [decoder decodeObjectForKey:goMovePlayerKey];
//  _point = [decoder decodeObjectForKey:goMovePointKey];  // don't use self, otherwise we trigger the setter!
//  // The previous/next moves were not archived. Whoever is unarchiving this
//  // GoMove is responsible for setting the previous/next move.
//  self.previous = nil;
//  self.next = nil;
//  self.capturedStones = [decoder decodeObjectForKey:goMoveCapturedStonesKey];
//  self.moveNumber = [decoder decodeIntForKey:goMoveMoveNumberKey];
//  // The hash was not archived. Whoever is unarchiving this GoMove is
//  // responsible for re-calculating the hash.
//  self.zobristHash = 0;
//  self.goMoveValuation = [decoder decodeIntForKey:goMoveGoMoveValuationKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoNodeSetup object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.mutableBlackSetupStones = nil;
  self.mutableWhiteSetupStones = nil;
  self.mutableNoSetupStones = nil;
  self.mutablePreviousBlackSetupStones = nil;
  self.mutablePreviousWhiteSetupStones = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  // TODO xxx
//  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
//  [encoder encodeInt:self.type forKey:goMoveTypeKey];
//  [encoder encodeObject:self.player forKey:goMovePlayerKey];
//  [encoder encodeObject:self.point forKey:goMovePointKey];
//  // The GoMove objects for the next/previous move are not archived because
//  // in a game with many moves (e.g. a thousand moves) the result would be a
//  // stack overflow (archiving the next GoMove object causes that object to
//  // access its own next GoMove object, and so on).
//  [encoder encodeObject:self.capturedStones forKey:goMoveCapturedStonesKey];
//  [encoder encodeInt:self.moveNumber forKey:goMoveMoveNumberKey];
//  [encoder encodeInt:self.goMoveValuation forKey:goMoveGoMoveValuationKey];
//  // GoZobristTable is not archived, instead a new GoZobristTable object with
//  // random values is created each time when a game is unarchived. Zobrist
//  // hashes created by the previous GoZobristTable object are thus invalid.
//  // This is the reason why we don't archive self.zobristHash here - it doesn't
//  // make sense to archive an invalid value. A side effect of not archiving
//  // self.zobristHash is that the overall archive becomes smaller.
}

#pragma mark - NSObject overrides

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoNodeSetup object.
///
/// This method is invoked when GoNodeSetup needs to be represented as a string,
/// i.e. by NSLog, or when the debugger command "po" is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GoNodeSetup(%p): blackSetupStones = %@, whiteSetupStones = %@, noSetupStones = %@, setupFirstMoveColor = %d", self, _mutableBlackSetupStones, _mutableWhiteSetupStones, _mutableNoSetupStones, _setupFirstMoveColor];
}

#pragma mark - Public API - Delayed initialization

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setupValidatedBlackStones:(NSArray*)points
{
  if (! points)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setupValidatedBlackStones: failed: points argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  if (points.count == 0)
    self.mutableBlackSetupStones = nil;
  else
    self.mutableBlackSetupStones = [NSMutableArray arrayWithArray:points];
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setupValidatedWhiteStones:(NSArray*)points
{
  if (! points)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setupValidatedWhiteStones: failed: points argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  if (points.count == 0)
    self.mutableWhiteSetupStones = nil;
  else
    self.mutableWhiteSetupStones = [NSMutableArray arrayWithArray:points];
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setupValidatedNoStones:(NSArray*)points
{
  if (! points)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setupValidatedNoStones: failed: points argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  if (points.count == 0)
    self.mutableNoSetupStones = nil;
  else
    self.mutableNoSetupStones = [NSMutableArray arrayWithArray:points];
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) capturePreviousSetupInformation:(GoGame*)game
{
  if (! game)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"capturePreviousSetupInformation: failed: game argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  self.previousSetupFirstMoveColor = game.setupFirstMoveColor;

  NSMutableArray* previousBlackSetupStones = [NSMutableArray array];
  NSMutableArray* previousWhiteSetupStones = [NSMutableArray array];

  GoPoint* point = [game.board pointAtVertex:@"A1"];
  while (point)
  {
    switch (point.stoneState)
    {
      case GoColorBlack:
        [previousBlackSetupStones addObject:point];
        break;
      case GoColorWhite:
        [previousWhiteSetupStones addObject:point];
        break;
      default:
        break;
    }
    point = point.next;
  }

  if (previousBlackSetupStones.count == 0)
    self.mutablePreviousBlackSetupStones = nil;
  else
    self.mutablePreviousBlackSetupStones = previousBlackSetupStones;

  if (previousWhiteSetupStones.count == 0)
    self.mutablePreviousWhiteSetupStones = nil;
  else
    self.mutablePreviousWhiteSetupStones = previousWhiteSetupStones;
}

#pragma mark - Public API - Applying and reverting setup information

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) applySetup
{
  // TODO xxx
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) revertSetup
{
  // TODO xxx
}

#pragma mark - Public API - Placing and removing stones

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setupBlackStone:(GoPoint*)point
{
  if (! point)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"addBlackSetupStone: failed: point argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  if (_mutableBlackSetupStones && [_mutableBlackSetupStones containsObject:point])
    return;
  else if (_mutableWhiteSetupStones && [_mutableWhiteSetupStones containsObject:point])
    [self removeWhiteSetupStone:point];
  else if (_mutableNoSetupStones && [_mutableNoSetupStones containsObject:point])
    [self removeNoSetupStone:point];

  if (_mutablePreviousBlackSetupStones && [_mutablePreviousBlackSetupStones containsObject:point])
    return;

  if (_mutableBlackSetupStones)
    [_mutableBlackSetupStones addObject:point];
  else
    _mutableBlackSetupStones = [NSMutableArray arrayWithObject:point];
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setupWhiteStone:(GoPoint*)point
{
  if (! point)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"addWhiteSetupStone: failed: point argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  if (_mutableBlackSetupStones && [_mutableBlackSetupStones containsObject:point])
    [self removeBlackSetupStone:point];
  else if (_mutableWhiteSetupStones && [_mutableWhiteSetupStones containsObject:point])
    return;
  else if (_mutableNoSetupStones && [_mutableNoSetupStones containsObject:point])
    [self removeNoSetupStone:point];

  if (_mutablePreviousWhiteSetupStones && [_mutablePreviousWhiteSetupStones containsObject:point])
    return;

  if (_mutableWhiteSetupStones)
    [_mutableWhiteSetupStones addObject:point];
  else
    _mutableWhiteSetupStones = [NSMutableArray arrayWithObject:point];
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setupNoStone:(GoPoint*)point
{
  if (! point)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"removeSetupStone: failed: point argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  if (_mutableBlackSetupStones && [_mutableBlackSetupStones containsObject:point])
    [self removeBlackSetupStone:point];
  else if (_mutableWhiteSetupStones && [_mutableWhiteSetupStones containsObject:point])
    [self removeWhiteSetupStone:point];
  else if (_mutableNoSetupStones && [_mutableNoSetupStones containsObject:point])
    return;

  if (_mutablePreviousBlackSetupStones && ! [_mutablePreviousBlackSetupStones containsObject:point] &&
      _mutablePreviousWhiteSetupStones && ! [_mutablePreviousWhiteSetupStones containsObject:point])
  {
    return;
  }

  if (_mutableNoSetupStones)
    [_mutableNoSetupStones addObject:point];
  else
    _mutableNoSetupStones = [NSMutableArray arrayWithObject:point];
}

#pragma mark - Public API - Properties

// -----------------------------------------------------------------------------
// Private getter implementation, property is documented in the header file.
// -----------------------------------------------------------------------------
- (bool) isEmpty
{
  // Previous setup information is not considered because it is not new setup
  return ((! _mutableBlackSetupStones || _mutableBlackSetupStones.count == 0) &&
          (! _mutableWhiteSetupStones || _mutableWhiteSetupStones.count == 0) &&
          (! _mutableNoSetupStones || _mutableNoSetupStones.count == 0) &&
          _setupFirstMoveColor == GoColorNone);
}

// -----------------------------------------------------------------------------
// Private getter implementation, property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSArray*) blackSetupStones
{
  return self.mutableBlackSetupStones;
}

// -----------------------------------------------------------------------------
// Private getter implementation, property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSArray*) whiteSetupStones
{
  return self.mutableWhiteSetupStones;
}

// -----------------------------------------------------------------------------
// Private getter implementation, property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSArray*) noSetupStones
{
  return self.mutableNoSetupStones;
}

// -----------------------------------------------------------------------------
// Private getter implementation, property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSArray*) previousBlackSetupStones
{
  return self.mutablePreviousBlackSetupStones;
}

// -----------------------------------------------------------------------------
// Private getter implementation, property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSArray*) previousWhiteSetupStones
{
  return self.mutablePreviousWhiteSetupStones;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Removes @a point from the list of black setup stones in property
/// @e blackSetupStones. Deallocates the array if it is empty after the removal.
// -----------------------------------------------------------------------------
- (void) removeBlackSetupStone:(GoPoint*)point
{
  if (! _mutableBlackSetupStones)
    return;

  [_mutableBlackSetupStones removeObject:point];
  if (_mutableBlackSetupStones.count == 0)
    _mutableBlackSetupStones = nil;
}

// -----------------------------------------------------------------------------
/// @brief Removes @a point from the list of white setup stones in property
/// @e whiteSetupStones. Deallocates the array if it is empty after the removal.
// -----------------------------------------------------------------------------
- (void) removeWhiteSetupStone:(GoPoint*)point
{
  if (! _mutableWhiteSetupStones)
    return;

  [_mutableWhiteSetupStones removeObject:point];
  if (_mutableWhiteSetupStones.count == 0)
    _mutableWhiteSetupStones = nil;
}

// -----------------------------------------------------------------------------
/// @brief Removes @a point from the list of empty points in property
/// @e noSetupStones. Deallocates the array if it is empty after the removal.
// -----------------------------------------------------------------------------
- (void) removeNoSetupStone:(GoPoint*)point
{
  if (! _mutableNoSetupStones)
    return;

  [_mutableNoSetupStones removeObject:point];
  if (_mutableNoSetupStones.count == 0)
    _mutableNoSetupStones = nil;
}

// TODO xxx is this method still needed?
// -----------------------------------------------------------------------------
/// @brief Returns the stone state of @a point according to the overall setup
/// information in this GoNodeSetup (both current and previous).
// -----------------------------------------------------------------------------
- (enum GoColor) stoneState:(GoPoint*)point
{
  // First check if the stone state is explicitly set in this GoNodeSetup
  if (_mutableBlackSetupStones && [_mutableBlackSetupStones containsObject:point])
    return GoColorBlack;
  else if (_mutableWhiteSetupStones && [_mutableWhiteSetupStones containsObject:point])
    return GoColorWhite;
  else if (_mutableNoSetupStones && [_mutableNoSetupStones containsObject:point])
    return GoColorNone;

  // Only now that we know that the stone state is not explicitly set in this
  // GoNodeSetup are we allowed to consult the previous setup information
  else if (_mutablePreviousBlackSetupStones && [_mutablePreviousBlackSetupStones containsObject:point])
    return GoColorBlack;
  else if (_mutablePreviousWhiteSetupStones && [_mutablePreviousWhiteSetupStones containsObject:point])
    return GoColorWhite;
  else
    return GoColorNone;
}

@end

