// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoVertex.h"
#import "GoUtilities.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoNodeSetup.
// -----------------------------------------------------------------------------
@interface GoNodeSetup()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoColor previousSetupFirstMoveColor;
//@}
@property(nonatomic, assign) GoGame* game;
@property(nonatomic, retain) NSMutableArray* mutableBlackSetupStones;
@property(nonatomic, retain) NSMutableArray* mutableWhiteSetupStones;
@property(nonatomic, retain) NSMutableArray* mutableNoSetupStones;
@property(nonatomic, retain) NSMutableArray* mutablePreviousBlackSetupStones;
@property(nonatomic, retain) NSMutableArray* mutablePreviousWhiteSetupStones;
@property(nonatomic, assign) bool previousSetupInformationWasCaptured;
@end


@implementation GoNodeSetup

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
+ (GoNodeSetup*) nodeSetupWithPreviousSetupCapturedFromGame:(GoGame*)game
{
  GoNodeSetup* nodeSetup = [[[self alloc] initWithGame:game] autorelease];

  [nodeSetup capturePreviousSetupInformationFromGame:game];
  nodeSetup.previousSetupInformationWasCaptured = true;

  return nodeSetup;
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (id) initWithGame:(GoGame*)game
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.game = game;
  self.mutableBlackSetupStones = nil;
  self.mutableWhiteSetupStones = nil;
  self.mutableNoSetupStones = nil;
  self.setupFirstMoveColor = GoColorNone;
  self.mutablePreviousBlackSetupStones = nil;
  self.mutablePreviousWhiteSetupStones = nil;
  self.previousSetupFirstMoveColor = GoColorNone;
  self.previousSetupInformationWasCaptured = false;

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

  self.game = [decoder decodeObjectOfClass:[GoGame class] forKey:goNodeSetupGameKey];
  self.mutableBlackSetupStones = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSMutableArray class], [GoPoint class]]] forKey:goNodeSetupBlackSetupStonesKey];
  self.mutableWhiteSetupStones = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSMutableArray class], [GoPoint class]]] forKey:goNodeSetupWhiteSetupStonesKey];
  self.mutableNoSetupStones = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSMutableArray class], [GoPoint class]]] forKey:goNodeSetupNoSetupStonesKey];
  self.setupFirstMoveColor = [decoder decodeIntForKey:goNodeSetupSetupFirstMoveColorKey];
  self.mutablePreviousBlackSetupStones = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSMutableArray class], [GoPoint class]]] forKey:goNodeSetupPreviousBlackSetupStonesKey];
  self.mutablePreviousWhiteSetupStones = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSMutableArray class], [GoPoint class]]] forKey:goNodeSetupPreviousWhiteSetupStonesKey];
  self.previousSetupFirstMoveColor = [decoder decodeIntForKey:goNodeSetupPreviousSetupFirstMoveColorKey];
  self.previousSetupInformationWasCaptured = [decoder decodeBoolForKey:goNodeSetupPreviousSetupInformationWasCapturedKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSSecureCoding protocol method.
// -----------------------------------------------------------------------------
+ (BOOL) supportsSecureCoding
{
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoNodeSetup object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;
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
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];

  [encoder encodeObject:self.game forKey:goNodeSetupGameKey];
  [encoder encodeObject:self.mutableBlackSetupStones forKey:goNodeSetupBlackSetupStonesKey];
  [encoder encodeObject:self.mutableWhiteSetupStones forKey:goNodeSetupWhiteSetupStonesKey];
  [encoder encodeObject:self.mutableNoSetupStones forKey:goNodeSetupNoSetupStonesKey];
  [encoder encodeInt:self.setupFirstMoveColor forKey:goNodeSetupSetupFirstMoveColorKey];
  [encoder encodeObject:self.mutablePreviousBlackSetupStones forKey:goNodeSetupPreviousBlackSetupStonesKey];
  [encoder encodeObject:self.mutablePreviousWhiteSetupStones forKey:goNodeSetupPreviousWhiteSetupStonesKey];
  [encoder encodeInt:self.previousSetupFirstMoveColor forKey:goNodeSetupPreviousSetupFirstMoveColorKey];
  [encoder encodeBool:self.previousSetupInformationWasCaptured forKey:goNodeSetupPreviousSetupInformationWasCapturedKey];
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

#pragma mark - Public API - Applying and reverting setup information

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) applySetup
{
  if (! self.previousSetupInformationWasCaptured)
  {
    [self capturePreviousSetupInformationFromGame:self.game];
    self.previousSetupInformationWasCaptured = true;
  }

  [self setupPoints:self.mutableBlackSetupStones withStoneState:GoColorBlack];
  [self setupPoints:self.mutableWhiteSetupStones withStoneState:GoColorWhite];
  [self setupPoints:self.mutableNoSetupStones withStoneState:GoColorNone];

  if (self.setupFirstMoveColor != GoColorNone)
    self.game.setupFirstMoveColor = self.setupFirstMoveColor;
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) revertSetup
{
  if (! self.previousSetupInformationWasCaptured)
  {
    NSString* errorMessage = @"Failed to revert board setup prior to first move: Board setup has never been applied before.";
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  [self revertPoints:self.mutableBlackSetupStones];
  [self revertPoints:self.mutableWhiteSetupStones];
  [self revertPoints:self.mutableNoSetupStones];

  self.game.setupFirstMoveColor = self.previousSetupFirstMoveColor;
}

#pragma mark - Public API - Placing and removing stones

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setupBlackStone:(GoPoint*)point
{
  if (! point)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setupBlackStone: failed: point argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  NSMutableArray* mutableBlackSetupStones = self.mutableBlackSetupStones;

  if (mutableBlackSetupStones && [mutableBlackSetupStones containsObject:point])
    return;
  else if (_mutableWhiteSetupStones && [_mutableWhiteSetupStones containsObject:point])
    [self removeWhiteSetupStone:point];
  else if (_mutableNoSetupStones && [_mutableNoSetupStones containsObject:point])
    [self removeNoSetupStone:point];

  if (_mutablePreviousBlackSetupStones && [_mutablePreviousBlackSetupStones containsObject:point])
    return;

  if (mutableBlackSetupStones)
    [mutableBlackSetupStones addObject:point];
  else
    self.mutableBlackSetupStones = [NSMutableArray arrayWithObject:point];
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setupWhiteStone:(GoPoint*)point
{
  if (! point)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setupWhiteStone: failed: point argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  NSMutableArray* mutableWhiteSetupStones = self.mutableWhiteSetupStones;

  if (_mutableBlackSetupStones && [_mutableBlackSetupStones containsObject:point])
    [self removeBlackSetupStone:point];
  else if (mutableWhiteSetupStones && [mutableWhiteSetupStones containsObject:point])
    return;
  else if (_mutableNoSetupStones && [_mutableNoSetupStones containsObject:point])
    [self removeNoSetupStone:point];

  if (_mutablePreviousWhiteSetupStones && [_mutablePreviousWhiteSetupStones containsObject:point])
    return;

  if (mutableWhiteSetupStones)
    [mutableWhiteSetupStones addObject:point];
  else
    self.mutableWhiteSetupStones = [NSMutableArray arrayWithObject:point];
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setupNoStone:(GoPoint*)point
{
  if (! point)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"setupNoStone: failed: point argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  NSMutableArray* mutableNoSetupStones = self.mutableNoSetupStones;

  if (_mutableBlackSetupStones && [_mutableBlackSetupStones containsObject:point])
    [self removeBlackSetupStone:point];
  else if (_mutableWhiteSetupStones && [_mutableWhiteSetupStones containsObject:point])
    [self removeWhiteSetupStone:point];
  else if (mutableNoSetupStones && [mutableNoSetupStones containsObject:point])
    return;

  if ((_mutablePreviousBlackSetupStones && [_mutablePreviousBlackSetupStones containsObject:point]) ||
      (_mutablePreviousWhiteSetupStones && [_mutablePreviousWhiteSetupStones containsObject:point]))
  {
    if (mutableNoSetupStones)
      [mutableNoSetupStones addObject:point];
    else
      self.mutableNoSetupStones = [NSMutableArray arrayWithObject:point];
  }
}

#pragma mark - Public API - Changing previous setup data

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) updatePreviousSetupInformationAfterHandicapStonesDidChange:(GoGame*)game
{
  if (! game)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"updatePreviousSetupInformationAfterHandicapStonesDidChange: failed: game argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  NSArray* handicapStones = game.handicapPoints;

  for (GoPoint* blackSetupStone in self.mutableBlackSetupStones)
  {
    if ([handicapStones containsObject:blackSetupStone])
    {
      NSString* errorMessage = [NSString stringWithFormat:@"updatePreviousSetupInformationAfterHandicapStonesDidChange: failed: A new handicap stone appeared on intersection %@, but a black setup stone already exists on the intersection", blackSetupStone.vertex.string];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }
  }

  // whiteSetupStones is not relevant and does not need to be checked.
  // Regardless of whether new handicap stones appear or previously existing
  // handicap stones disappear: Overwriting one of the changing intersections
  // with a white setup stone still works.

  for (GoPoint* noSetupStone in self.mutableNoSetupStones)
  {
    if (! [handicapStones containsObject:noSetupStone])
    {
      NSString* errorMessage = [NSString stringWithFormat:@"updatePreviousSetupInformationAfterHandicapStonesDidChange: failed: A previously existing handicap stone disappeared from intersection %@, but the intersection is still being cleared", noSetupStone.vertex.string];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }
  }

  if (handicapStones.count > 0)
    self.mutablePreviousBlackSetupStones = [NSMutableArray arrayWithArray:handicapStones];
  else
    self.mutablePreviousBlackSetupStones = nil;
}

#pragma mark - Public API - Querying for expected stone state

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (enum GoColor) stoneStateAfterSetup:(GoPoint*)point
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
  return [self stoneStatePreviousToSetup:point];
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
/// @brief Returns the stone state that @a point should have before the setup in
/// this GoNodeSetup was applied to the board.
// -----------------------------------------------------------------------------
- (enum GoColor) stoneStatePreviousToSetup:(GoPoint*)point
{
  if (_mutablePreviousBlackSetupStones && [_mutablePreviousBlackSetupStones containsObject:point])
    return GoColorBlack;
  else if (_mutablePreviousWhiteSetupStones && [_mutablePreviousWhiteSetupStones containsObject:point])
    return GoColorWhite;
  else
    return GoColorNone;
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
  NSMutableArray* mutableBlackSetupStones = self.mutableBlackSetupStones;
  if (! mutableBlackSetupStones)
    return;

  [mutableBlackSetupStones removeObject:point];
  if (mutableBlackSetupStones.count == 0)
    self.mutableBlackSetupStones = nil;
}

// -----------------------------------------------------------------------------
/// @brief Removes @a point from the list of white setup stones in property
/// @e whiteSetupStones. Deallocates the array if it is empty after the removal.
// -----------------------------------------------------------------------------
- (void) removeWhiteSetupStone:(GoPoint*)point
{
  NSMutableArray* mutableWhiteSetupStones = self.mutableWhiteSetupStones;
  if (! mutableWhiteSetupStones)
    return;

  [mutableWhiteSetupStones removeObject:point];
  if (mutableWhiteSetupStones.count == 0)
    self.mutableWhiteSetupStones = nil;
}

// -----------------------------------------------------------------------------
/// @brief Removes @a point from the list of empty points in property
/// @e noSetupStones. Deallocates the array if it is empty after the removal.
// -----------------------------------------------------------------------------
- (void) removeNoSetupStone:(GoPoint*)point
{
  NSMutableArray* mutableNoSetupStones = self.mutableNoSetupStones;
  if (! mutableNoSetupStones)
    return;

  [mutableNoSetupStones removeObject:point];
  if (mutableNoSetupStones.count == 0)
    self.mutableNoSetupStones = nil;
}

// -----------------------------------------------------------------------------
/// @brief Captures setup information in @a game and stores the information in
/// the properties @e previousBlackSetupStones, @e previousWhiteSetupStones and
/// @e previousSetupFirstMoveColor.
///
/// This is an internal helper method for applySetup().
///
/// Raises @e NSInvalidArgumentException if @a game is @e nil.
// -----------------------------------------------------------------------------
- (void) capturePreviousSetupInformationFromGame:(GoGame*)game
{
  if (! game)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"capturePreviousSetupInformationFromGame: failed: game argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

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

  self.previousSetupFirstMoveColor = game.setupFirstMoveColor;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the GoPoint objects listed in @a points so that their
/// property @e stoneState has the new value @a newStoneState. @a points may be
/// @e nil, in which case this method does nothing.
///
/// If @a newStoneState is either #GoColorBlack or #GoColorWhite this places
/// a black or white setup stone, either on an empty intersection or replacing
/// a stone of the opposite color. If @a newStoneState is #GoColorNone this
/// removes an existing setup stone.
///
/// This is an internal helper method for applySetup().
///
/// Raises @e NSInternalInconsistencyException if one or more GoPoint objects
/// already have the desired @e newStoneState property value.
// -----------------------------------------------------------------------------
- (void) setupPoints:(NSArray*)points withStoneState:(enum GoColor)newStoneState
{
  if (! points)
    return;

  for (GoPoint* point in points)
    [self changePoint:point toStoneState:newStoneState];
}

// -----------------------------------------------------------------------------
/// @brief Reverts the GoPoint objects listed in @a points so that their
/// property @e stoneState has the previous value before the setup in this
/// GoNodeSetup was applied. @a points may be @e nil, in which case this method
/// does nothing.
///
/// This is an internal helper method for revertSetup().
///
/// Raises @e NSInternalInconsistencyException if one or more GoPoint objects
/// already have the previous @e stoneState value.
// -----------------------------------------------------------------------------
- (void) revertPoints:(NSArray*)points
{
  if (! points)
    return;

  for (GoPoint* point in points)
  {
    enum GoColor previousStoneState = [self stoneStatePreviousToSetup:point];
    [self changePoint:point toStoneState:previousStoneState];
  }
}

// -----------------------------------------------------------------------------
/// @brief Changes the value of the property @e stoneState of @a point to the
/// new value @a newStoneState.
///
/// If @a newStoneState is either #GoColorBlack or #GoColorWhite this places
/// a black or white setup stone, either on an empty intersection or replacing
/// a stone of the opposite color. If @a newStoneState is #GoColorNone this
/// removes an existing setup stone.
///
/// This is an internal helper method for both applySetup() and revertSetup().
///
/// Raises @e NSInvalidArgumentException if @a point is @e nil.
///
/// Raises @e NSInternalInconsistencyException if @a point already has the
/// desired @e newStoneState property value.
// -----------------------------------------------------------------------------
- (void) changePoint:(GoPoint*)point toStoneState:(enum GoColor)newStoneState
{
  if (! point)
  {
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:@"changePoint:toStoneState: failed: point argument is nil"];
    // Dummy return to make compiler happy (compiler does not see that an
    // exception is thrown)
    return;
  }

  if (point.stoneState == newStoneState)
  {
    NSString* errorMessage = @"Failed to apply or revert board setup prior to first move: ";
    if (newStoneState == GoColorNone)
      errorMessage = [errorMessage stringByAppendingString:@" Expected stone to be cleared was not present on intersection "];
    else
      errorMessage = [errorMessage stringByAppendingFormat:@" Placing a stone of color %d failed because a stone of the same color was already present on intersection ", newStoneState];
    errorMessage = [errorMessage stringByAppendingString:point.vertex.string];
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  point.stoneState = newStoneState;
  [GoUtilities movePointToNewRegion:point];
}

@end

