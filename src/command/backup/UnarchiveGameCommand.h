// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "../CommandBase.h"

// Forward declarations
@class GoGame;


// -----------------------------------------------------------------------------
/// @brief The UnarchiveGameCommand class is responsible for unarchiving a
/// GoGame object from an NSCoding archive. The client executing this command
/// can access the unarchived GoGame object via the @e game property.
///
/// UnarchiveGameCommand fails if no NSCoding archive file exists, or if the
/// NSCoding archive file is not compatible with the current Go model classes.
/// The @e game property in this case is nil. In case of an incompatible
/// archive, UnarchiveGameCommand deletes the NSCoding archive file unless the
/// client executing this command prevents this by setting the
/// @e shouldRemoveArchiveFileIfUnarchivingFails property to false.
///
/// @note The object tree dangling from the unarchived GoGame object is
/// incomplete. The client executing UnarchiveGameCommand is responsible for
/// performing post-processing to complete the setup of the object tree.
///
/// @see SaveApplicationStateCommand.
// -----------------------------------------------------------------------------
@interface UnarchiveGameCommand : CommandBase
{
}

@property(nonatomic, assign) bool shouldRemoveArchiveFileIfUnarchivingFails;
@property(nonatomic, retain, readonly) GoGame* game;

@end
