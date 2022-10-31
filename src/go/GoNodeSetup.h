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


// Forward declarations
@class GoGame;
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The GoNodeSetup class collects game setup information made in the
/// game tree node that the GoNodeSetup is associated with. Game setup consists
/// of placing black and/or white stones on the board, removing existing stones
/// from the board (including handicap stones), and setting up a side (black or
/// white) to play the first move. When GoNodeSetup places or removes stones on
/// the board, a new board position with a new Zobrist hash is created.
///
/// @ingroup go
///
/// Design note: It is expected that only small parts of the board are actually
/// set up with stones. It is therefore most efficient, memory-wise and also for
/// the size of the NSCoding archive, for the previous setup information to
/// only capture the points that have stones on them. Whoever needs to work with
/// empty points can (and must) infer what these points are, at the cost of
/// additional processing time and power.
// -----------------------------------------------------------------------------
@interface GoNodeSetup : NSObject <NSCoding>
{
}

/// @name Initialization
//@{
+ (GoNodeSetup*) nodeSetupWithPreviousSetupCapturedFromGame:(GoGame*)game;
- (id) init;
//@}


/// @name Delayed initialization
//@{
/// @brief Sets the value of property @e blackSetupStones with the black setup
/// stones listed in @a points, without performing any validation. Any points
/// already in @e blackSetupStones are replaced.
///
/// Raises @e NSInvalidArgumentException if @a points is @e nil.
- (void) setupValidatedBlackStones:(NSArray*)points;

/// @brief Sets the value of property @e whiteSetupStones with the white setup
/// stones listed in @a points, without performing any validation. Any points
/// already in @e whiteSetupStones are replaced.
///
/// Raises @e NSInvalidArgumentException if @a points is @e nil.
- (void) setupValidatedWhiteStones:(NSArray*)points;

/// @brief Sets the value of property @e noSetupStones with the empty points
/// listed in @a points, without performing any validation. Any points already
/// in @e noSetupStones are replaced.
///
/// Raises @e NSInvalidArgumentException if @a points is @e nil.
- (void) setupValidatedNoStones:(NSArray*)points;
//@}


/// @name Applying and reverting setup information
//@{
/// @brief Modifies the board and the game to reflect the data that is present
/// in this GoNodeSetup.
///
/// Invoking this method is a comparatively expensive operation, because this
/// method manipulates the entire board to reflect the position that exists
/// after the setup stones in this GoNodeSetup were placed or removed.
///
/// @note applySetup() must never be invoked twice in a row. It can be invoked
/// in alternation with revertSetup() any number of times.
///
/// Raises @e NSInternalInconsistencyException if one or more GoPoint objects
/// already have the desired @e stoneState property value.
- (void) applySetup;

/// @brief Reverts the board and the game to the state they had before
/// applySetup() was invoked.
///
/// Invoking this method is a comparatively expensive operation, because this
/// method manipulates the entire board to reflect the position that exists
/// before the setup stones in this GoNodeSetup were placed or removed.
///
/// @note revertSetup() must never be invoked twice in a row. It can be invoked
/// in alternation with applySetup() any number of times, however applySetup()
/// must have been invoked at least once before.
///
/// Raises @e NSInternalInconsistencyException if this method is invoked but
/// applySetup() has never been invoked before.
///
/// Raises @e NSInternalInconsistencyException if one or more GoPoint objects
/// already have the desired @e stoneState property value.
- (void) revertSetup;
//@}


/// @name Changing setup data
//@{
/// @brief Changes the data in this GoNodeSetup so that as a result a black
/// stone is set up on intersection @a point.
///
/// Does nothing if @a point is already listed in @e blackSetupStones.
///
/// Otherwise, adds @a point to @e blackSetupStones if @a point did not already
/// have a black stone in the previous setup. In addition, @a point is removed
/// from  @e whiteSetupStones or @e noSetupStones if it is already listed in
/// one of these properties.
///
/// Raises @e NSInvalidArgumentException if @a point is @e nil.
///
/// @note This method does @b not change the value of the @e stoneState property
/// of @a point.
- (void) setupBlackStone:(GoPoint*)point;

/// @brief Changes the data in this GoNodeSetup so that as a result a white
/// stone is set up on intersection @a point.
///
/// Does nothing if @a point is already listed in @e whiteSetupStones.
///
/// Otherwise, adds @a point to @e whiteSetupStones if @a point did not already
/// have a white stone in the previous setup. In addition, @a point is removed
/// from  @e blackSetupStones or @e noSetupStones if it is already listed in
/// one of these properties.
///
/// Raises @e NSInvalidArgumentException if @a point is @e nil.
///
/// @note This method does @b not change the value of the @e stoneState property
/// of @a point.
- (void) setupWhiteStone:(GoPoint*)point;

/// @brief Changes the data in this GoNodeSetup so that as a result no
/// stone is set up on intersection @a point.
///
/// Does nothing if @a point is already listed in @e noSetupStones.
///
/// Otherwise, adds @a point to @e noSetupStones if @a point was not already
/// empty in the previous setup. In addition, @a point is removed
/// from  @e blackSetupStones or @e whiteSetupStones if it is already listed in
/// one of these properties.
///
/// Raises @e NSInvalidArgumentException if @a point is @e nil.
///
/// @note This method does @b not change the value of the @e stoneState property
/// of @a point.
- (void) setupNoStone:(GoPoint*)point;
//@}

/// @name Changing previous setup data
//@{
/// @brief Updates the property @e previousBlackSetupStones after one or more
/// handicap stones were added or removed. Obtains the current handicap stones
/// from @a game.
///
/// Raises @e NSInvalidArgumentException if @a game is @e nil.
///
/// Raises @e NSInternalInconsistencyException if a conflict between the updated
/// handicap stones and the setup data in this GoNodeSetup is detected. Whoever
/// invokes this method must have previously made sure to update the setup data
/// in this GoNodeSetup so that no such conflict is possible. Possible conflicts
/// are
/// - If a new handicap stone appears although the property @e blackSetupStones
///   already contains the point
/// - If a previously existing handicap stone disappears although the property
///   @e noSetupStones still contains the point.
- (void) updatePreviousSetupInformationAfterHandicapStonesDidChange:(GoGame*)game;
//@}

/// @name Querying for expected stone state
//@{
/// @brief Returns the stone state that @a point should have after the setup in
/// this GoNodeSetup is applied to the board.
- (enum GoColor) stoneStateAfterSetup:(GoPoint*)point;

/// @brief Returns the stone state that @a point should have before the setup in
/// this GoNodeSetup is applied to the board.
- (enum GoColor) stoneStatePreviousToSetup:(GoPoint*)point;
//@}

/// @name Properties
//@{
/// @brief @e true if the GoNodeSetup object does not contain any setup data,
/// @e false if the GoNodeSetup does contain setup data.
@property(nonatomic, assign, getter=isEmpty, readonly) bool empty;

/// @brief List of GoPoint objects on which black stones are to be placed
/// as part of the game setup prior to the first move. Already existing white
/// stones from previous board setup nodes are overwritten. The default value is
/// @e nil, which is equivalent to an empty list. The list has no particular
/// order. The list contains no duplicates.
///
/// The value of this property corresponds to the value of the SGF property AB.
@property(nonatomic, retain, readonly) NSArray* blackSetupStones;

/// @brief List of GoPoint objects on which white stones are to be placed
/// as part of the game setup prior to the first move. Already existing black
/// stones from previous board setup nodes, or from handicap, are overwritten.
/// The default value is @e nil, which is equivalent to an empty list. The list
/// has no particular order. The list contains no duplicates.
///
/// The value of this property corresponds to the value of the SGF property AW.
@property(nonatomic, retain, readonly) NSArray* whiteSetupStones;

/// @brief List of GoPoint objects on which no stones are to be placed as part
/// of the game setup prior to the first move. Already existing black or white
/// stones from previous board setup nodes, or from handicap, are removed. The
/// default value is @e nil, which is equivalent to an empty list. The list has
/// no particular order. The list contains no duplicates.
///
/// The value of this property corresponds to the value of the SGF property AE.
@property(nonatomic, retain, readonly) NSArray* noSetupStones;

/// @brief The side that is set up to play the first move. Is #GoColorNone
/// if no side is set up to play first. Note that this is @b not necessarily the
/// side that actually plays the first move - notably in a game that was loaded
/// from an .sgf file the two can be different. The default value is
/// #GoColorNone.
///
/// The value of this property corresponds to the value of the SGF property PL.
@property(nonatomic, assign) enum GoColor setupFirstMoveColor;

/// @brief List of GoPoint objects on which black stones existed before the
/// setup information in this GoNodeSetup was applied to the board. The
/// default value is @e nil, which is equivalent to an empty list. The list
/// has no particular order. The list contains no duplicates.
///
/// GoPoint objects that do not appear in this property were either white (if
/// they appear in @e previousWhiteSetupStones) or empty (if they do not appear
/// in @e previousWhiteSetupStones) before the setup information in this
/// GoNodeSetup was applied to the board.
@property(nonatomic, retain, readonly) NSArray* previousBlackSetupStones;

/// @brief List of GoPoint objects on which white stones existed before the
/// setup information in this GoNodeSetup was applied to the board. The
/// default value is @e nil, which is equivalent to an empty list. The list
/// has no particular order. The list contains no duplicates.
///
/// GoPoint objects that do not appear in this property were either white (if
/// they appear in @e previousBlackSetupStones) or empty (if they do not appear
/// in @e previousBlackSetupStones) before the setup information in this
/// GoNodeSetup was applied to the board.
@property(nonatomic, retain, readonly) NSArray* previousWhiteSetupStones;

/// @brief The side that was set up to play the first move before the value of
/// @e setupFirstMoveColor in this GoNodeSetup was applied to the game. The
/// default value is #GoColorNone.
///
/// This effectively has the value of the @e setupFirstMoveColor property of the
/// previous GoNodeSetup object. Is #GoColorNone if this is the first
/// GoNodeSetup.
@property(nonatomic, assign, readonly) enum GoColor previousSetupFirstMoveColor;
//@}

@end
