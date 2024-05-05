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


// -----------------------------------------------------------------------------
/// @brief The MarkupModel class provides user defaults data to its clients that
/// is related to viewing and placing markup on the board.
// -----------------------------------------------------------------------------
@interface MarkupModel : NSObject
{
}

- (id) init;
- (void) readUserDefaults;
- (void) writeUserDefaults;

/// @brief The markup type that is currently used when placing markup on the
/// board. Setting this property may affect the value of property @e markupTool.
@property(nonatomic, assign) enum MarkupType markupType;

/// @brief The markup tool that is currently used when placing markup on the
/// board.
///
/// The value of this property depends on the value of property @e markupType.
/// In case both properties change their value in response to @e markupType
/// being set, KVO observers will receive the notification for @e markupType
/// before the notification for @e markupTool.
@property(nonatomic, assign, readonly) enum MarkupTool markupTool;

@property(nonatomic, assign) enum SelectedSymbolMarkupStyle selectedSymbolMarkupStyle;
@property(nonatomic, assign) enum MarkupPrecedence markupPrecedence;
@property(nonatomic, assign) bool uniqueSymbols;
@property(nonatomic, assign) bool connectionToolAllowsDelete;
@property(nonatomic, assign) bool fillMarkerGaps;

@end
