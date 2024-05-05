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
#import "BoardViewLayerDelegateBase.h"

// Forward declarations
@class MarkupModel;


// -----------------------------------------------------------------------------
/// @brief The LabelsLayerDelegate class is responsible for drawing markup
/// labels of type #GoMarkupLabelLabel.
///
/// A separate layer is required because markup labels are not restricted to a
/// point cell, so drawing them together with other markup or symbols that are
/// restricted to a point cell (e.g. in SymbolLayerDelegate) makes it impossible
/// to have optimised drawing that is based on the premise of non-overlapping
/// point cells.
///
/// Examples that illustrate the problem if symbols and labels would be drawn
/// in the same layer:
/// - A triangle symbol is removed. It would be necessary to check if some label
///   exists on the same row that the triangle is on, and if yes to then redraw
///   the entire row, because one cannot be sure that the label does not overlap
///   into the point cell that contained the triangle. Moreover, this would
///   have to be done for all tiles that intersect with the row.
/// - A label is moved with a panning operation. On each location change all
///   tiles that have intersections with the row that the old location was in,
///   and the the row that the new location is in, would have to redraw these
///   two rows entirely.
///
/// LabelsLayerDelegate still has to do this redrawing of entire rows, but the
/// redrawing is limited to labels, which is computationally much simpler than
/// what would have to be done in SymbolsLayerDelegate. Effectively this is a
/// tradeoff between CPU usage and maintainable code vs. memory usage (an
/// additional layer costs more memory).
// -----------------------------------------------------------------------------
@interface LabelsLayerDelegate : BoardViewLayerDelegateBase
{
}

- (id) initWithTile:(id<Tile>)tile
            metrics:(BoardViewMetrics*)metrics
        markupModel:(MarkupModel*)markupModel;

@end
