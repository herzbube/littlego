// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The GoGameDocument class represents a GoGame instance as a document
/// that can be saved to / loaded from disk.
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoGameDocument : NSObject <NSCoding>
{
}

- (void) load:(NSString*)documentName;
- (void) save:(NSString*)documentName;

/// @brief This flag represents the document's "dirty" state, i.e. whether
/// something about the document has changed since it was last saved.
///
/// This flag is false for new instances of GoGameDocument.
///
/// The parent GoGame sets this flag to true whenever a change occurs that can
/// be saved to disk.
///
/// GoGameDocument sets this flag to false when the save or load methods are
/// invoked.
@property(nonatomic, assign, getter=isDirty) bool dirty;
/// @brief The name of the document (without the .sgf extension).
///
/// The document name is nil for new instances of GoGameDocument.
///
/// When a game is loaded from the archive, the actor who loads the game sets
/// the document name to match the name of the game that was just loaded.
///
/// GoGameDocument sets the document name when the save or load methods are
/// invoked. The value supplied to those methods is used as the new document
/// name, the previous document name is lost.
@property(nonatomic, retain, readonly) NSString* documentName;

@end
