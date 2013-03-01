// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Enumerates tags of subviews of TableViewSegmentedCell.
// -----------------------------------------------------------------------------
enum SegmentedCellSubViewTag
{
  SegmentedCellSegmentedControlTag = 1  ///< @brief Tag 0 must not be used, it is the default tag used for all framework-created views (e.g. the cell's content view)
};


// -----------------------------------------------------------------------------
/// @brief The TableViewSegmentedCell class implements a custom table view cell
/// that displays a UISegmentedControl.
///
/// The UISegmentedControl is initialized without any segments. The
/// UISegmentedControl object is exposed as a property so that clients can
/// configure the control's content and register a target-action method.
// -----------------------------------------------------------------------------
@interface TableViewSegmentedCell : UITableViewCell
{
}

+ (TableViewSegmentedCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier;

@property(nonatomic, retain, readonly) UISegmentedControl* segmentedControl;

@end
