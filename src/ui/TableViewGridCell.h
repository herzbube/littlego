// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Enumerates column styles used
// -----------------------------------------------------------------------------
enum GridCellColumnStyle
{
  ValueGridCellColumnStyle,
  TitleGridCellColumnStyle
};

// Forward declarations
@class TableViewGridCell;


// -----------------------------------------------------------------------------
/// @brief The TableViewGridCellDelegate protocol must be implemented by the
/// delegate of TableViewGridCell.
// -----------------------------------------------------------------------------
@protocol TableViewGridCellDelegate
- (NSInteger) numberOfColumnsInGridCell:(TableViewGridCell*)gridCell;
- (enum GridCellColumnStyle) gridCell:(TableViewGridCell*)gridCell styleInColumn:(NSInteger)column;
- (NSString*) gridCell:(TableViewGridCell*)gridCell textForColumn:(NSInteger)column;
@end


// -----------------------------------------------------------------------------
/// @brief The TableViewGridCell class implements a custom table view cell
/// that displays partitions its horizontal stretch into an arbitrary number of
/// columns. If a table view displays multiple TableViewGridCell's in a row the
/// overall visual effect is that of a grid.
///
/// TableViewGridCell adds its UI elements as subview to its content view and
/// arranges them according to the following schema:
///
/// @verbatim
/// +---------------------------------------------------------------+
/// |               $               $               $               |
/// |  +---------+  $  +---------+  $  +---------+  $  +---------+  |
/// |  | UILabel |  $  | UILabel |  $  | UILabel |  $  | UILabel |  |
/// |  +---------+  $  +---------+  $  +---------+  $  +---------+  |
/// |               $               $               $               |
/// +---------------------------------------------------------------+
/// @endverbatim
///
/// The vertical separators between columns (depicted by "$" characters in the
/// schema above) are actually drawn as vertical lines. This achieves the
/// visual effect of a grid.
///
/// TableViewGridCell must be configured with a delegate object. The delegate
/// must adopt the TableViewGridCellDelegate protocol. This protocol contains
/// methods that are used by the cell to query the delegate about things such
/// as "how many columns should I display" or "which style should I use for a
/// the label of a given column", etc. The role of TableViewGridCellDelegate is
/// similar to a combination of UITableViewDelegate and UITableViewDataSource.
///
/// Notes and constraints:
/// - TableViewGridCell expects to be displayed in a table view of grouped
///   style. It should be possible to adapt the class with only minor source
///   code changes so that it can also be used in a table view of plain style.
/// - TableViewGridCell can only be used without indentation
/// - TableViewGridCell was not designed to be used in editing mode
// -----------------------------------------------------------------------------
@interface TableViewGridCell : UITableViewCell
{
}

+ (TableViewGridCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier;
- (void) setupCellContent;

@property(nonatomic, assign) id<TableViewGridCellDelegate> delegate;


@end
