// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
@class GoGameResult;


// -----------------------------------------------------------------------------
/// @brief The GoGameInfo class stores "game info" properties, i.e. information
/// that describes the game in a general way and that does not have any
/// influence on the game logic. All of the properties have direct
/// correspondences in SGF.
///
/// @ingroup go
///
/// The following SGF game info properties are treated specially and are not
/// stored in GoGameInfo, because they take an active role in game play:
/// - HA (handicap). This is stored in GoGame.
/// - KM (komi). This is stored in GoGame.
/// - TM (time limit). This is stored in GoTimeSettings.
/// - OT (overtime). This is stored in GoTimeSettings.
///
/// @par Pre-FF[4] SGF game info properties
///
/// SGF game info properties that predate the FF[4] version of the SGF
/// specification are also not stored in GoGameInfo. Rationale: The app writes
/// SGF files in the FF[4] format, therefore properties that are not part of
/// FF[4] should not be in those files. But as soon as a pre-FF[4] property is
/// added to GoGameInfo, it should also be made visible in the UI and the
/// expectation then is that the information is preserved when the game is
/// saved to the archive.
///
/// The following pre-FF[4] SGF properties are listed and classified with
/// property type "game-info" on the unified property index page of the
/// SGF specification [1].
///
/// - BS/WS (black/white species). A number indicating whether the black or
///   white player is human (value 0) or computer (value 1 or greater). This is
///   an FF[1] - FF[3] property. Note that on the pages dedicated to earlier
///   versions of the SGF standard ([2] and [3]) these properties are classified
///   as root properties.
/// - ID (game ID). A string that identifies the game. This is
///   an FF[3] property.
///
/// [1] https://www.red-bean.com/sgf/proplist_ff.html
/// [2] https://www.red-bean.com/sgf/ff1_3/ff3.html
/// [3] https://www.red-bean.com/sgf/ff1_3/ff1.html
// -----------------------------------------------------------------------------
@interface GoGameInfo : NSObject <NSSecureCoding>
{
}

/// @name Game data information
//@{
/// @brief The name of the user (or program) who recorded or entered the game
/// data.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property US.
@property(nonatomic, strong) NSString* recorderName;

/// @brief The name of the source of the game data (e.g. book, journal, etc.).
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property SO.
@property(nonatomic, strong) NSString* sourceName;

/// @brief The name of the person who made the annotations to the game.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property AN.
@property(nonatomic, strong) NSString* annotationAuthor;

/// @brief The copyright information for the game data (including the
/// annotations).
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property CP.
@property(nonatomic, strong) NSString* copyrightInformation;
//@}

/// @name Basic game information
//@{
/// @brief The name of the game (e.g. for easily finding the game again within
/// a collection).
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property GN.
@property(nonatomic, strong) NSString* gameName;

/// @brief Information about the game (e.g. background information, a game
/// summary, etc.).
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property GC.
@property(nonatomic, strong) NSString* gameInformation;

/// @brief The dates when the game was played.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property DT.
@property(nonatomic, strong) NSString* gameDates;

/// @brief The name of the rules used for the game.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property RU.
@property(nonatomic, strong) NSString* rulesName;

/// @brief The result of the game.
///
/// This property must never be @e nil. The GoGameResult object's @e dataType
/// property has the value #GoGameResultDataTypeNoResult to indicate that there
/// is no game result. The default value is such a GoGameResult object.
///
/// @see GoGameResult
@property(nonatomic, retain) GoGameResult* gameResult;
//@}

/// @name Extra game information
//@{
/// @brief Information about the opening played.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property ON.
@property(nonatomic, strong) NSString* openingInformation;
//@}

/// @name Player information
//@{
/// @brief The name of the black player.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// When a new game is started from scratch, or by loading a game from the
/// archive, this property is initialized with the value of the @e name property
/// of the Player object that is associated with the game's black player. When
/// the game is loaded from the archive, a value stored in the SGF data then
/// overwrites the @e name property value.
///
/// The value of this property corresponds to the value of the SGF property PB.
@property(nonatomic, strong) NSString* blackPlayerName;

/// @brief The rank of the black player.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property BR.
@property(nonatomic, strong) NSString* blackPlayerRank;

/// @brief The name of the black player's team.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property BT.
@property(nonatomic, strong) NSString* blackPlayerTeamName;

/// @brief The name of the white player.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// When a new game is started from scratch, or by loading a game from the
/// archive, this property is initialized with the value of the @e name property
/// of the Player object that is associated with the game's black player. When
/// the game is loaded from the archive, a value stored in the SGF data then
/// overwrites the @e name property value.
///
/// The value of this property corresponds to the value of the SGF property PW.
@property(nonatomic, strong) NSString* whitePlayerName;

/// @brief The rank of the white player.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property WR.
@property(nonatomic, strong) NSString* whitePlayerRank;

/// @brief The name of the white player's team.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property WT.
@property(nonatomic, strong) NSString* whitePlayerTeamName;
//@}

/// @name Context in which the game was played
//@{
/// @brief The name or description of the location where the game
/// was played.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property PC.
@property(nonatomic, strong) NSString* gameLocation;

/// @brief The name of the event (e.g. tournament) where the game
/// was played.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property EV.
@property(nonatomic, strong) NSString* eventName;

/// @brief The information that describes the round in which the
/// game was played.
///
/// Is @e nil to indicate that this property has no value. The default value is
/// @e nil.
///
/// The value of this property corresponds to the value of the SGF property RO.
@property(nonatomic, strong) NSString* roundInformation;
//@}

@end
