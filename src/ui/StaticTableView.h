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


// -----------------------------------------------------------------------------
/// @brief The StaticTableView class is a UIView subclass that displays a
/// statically sized non-scrolling UITableView. Its purpose is to provide a
/// standard-looking table view that takes up as little vertical space as
/// possible.
///
/// The use case for which StaticTableView was designed was a view layout that
/// vertically stacks a table view and one or more other input fields, and the
/// table view must not push the input fields located below it towards the
/// screen bottom.
///
/// A standard UITableView vertically expands as much as possible and even with
/// only a few cells makes it impossible (or at least I couldn't figure out a
/// way how to do it) to place other views directly below the last cell.
/// StaticTableView avoids this by statically assigning a height to the
/// UITableView it contains that is equal to the UITableView's content size.
/// The obvious limitation of this is that StaticTableView can only be used
/// with a limited number of cells.
///
/// StaticTableView exposes the UITableView that it displays so that clients
/// can interact with the UITableView in the usual way, i.e. set the delegate
/// and/or data source. StaticTableView will detect and changes to the
/// UITableView's content size.
///
/// @todo StaticTableView has been found to work unreliably, depending on
/// the context in which it is used. For instance, when embedded into
/// ItemPickerController it works nicely on iPhones when the controller is
/// presented in a popover, but when the controller is presented modally
/// the internal UITableView does not set its content size to a correct value,
/// resulting in the UITableView being sized with insufficient height. The
/// reason for this has not been investigated. Also, no other experiments with
/// embedding StaticTableView have been made.
// -----------------------------------------------------------------------------
@interface StaticTableView : UIView
{
}

- (id) initWithFrame:(CGRect)rect style:(UITableViewStyle)tableViewStyle;

@property(nonatomic, assign, readonly) UITableView* tableView;

@end
