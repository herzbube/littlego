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
#import "../CommandBase.h"
#import "../../ui/EditTextController.h"

// Forward declarations
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The HandleMarkupEditingInteractionCommand class is responsible for
/// handling a markup editing interaction. The interaction takes place either
/// at a single intersection, or between two intersections, all of which are
/// identified by GoPoint objects that are passed to one of the initializers.
///
/// After it has processed the markup editing interaction, if any markup data
/// changed HandleMarkupEditingInteractionCommand posts the notifications
/// #markupOnPointsDidChange and #nodeMarkupDataDidChange, performs a backup of
/// the current game and saves the application state.
///
/// @note Because HandleMarkupEditingInteractionCommand may show an
/// EditTextController or an alert, code execution may return to the client who
/// submitted the command before the markup editing interaction has actually
/// been processed.
///
/// It is expected that this command is only executed while the UI area "Play"
/// is in markup editing mode. If any of these conditions is not met an alert
/// is displayed and command execution fails.
// -----------------------------------------------------------------------------
@interface HandleMarkupEditingInteractionCommand : CommandBase <EditTextDelegate>
{
}

- (id) initPlaceNewMarkupAtPoint:(GoPoint*)point
                      markupTool:(enum MarkupTool)markupTool
                      markupType:(enum MarkupType)markupType;
- (id) initPlaceMovedSymbol:(enum GoMarkupSymbol)symbol
                    atPoint:(GoPoint*)point;
- (id) initPlaceNewOrMovedConnection:(enum GoMarkupConnection)connection
                           fromPoint:(GoPoint*)fromPoint
                             toPoint:(GoPoint*)toPoint
                  connectionWasMoved:(bool)connectionWasMoved;
- (id) initPlaceMovedLabel:(enum GoMarkupLabel)label
             withLabelText:(NSString*)labelText
                   atPoint:(GoPoint*)point;
- (id) initEraseMarkupAtPoint:(GoPoint*)point;
- (id) initEraseMarkupInRectangleFromPoint:(GoPoint*)fromPoint
                                   toPoint:(GoPoint*)toPoint;
- (id) initEraseConnectionAtPoint:(GoPoint*)point;

@end
