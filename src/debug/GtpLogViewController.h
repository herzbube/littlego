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


// Forward declarations
@class GtpLogModel;


// -----------------------------------------------------------------------------
/// @brief The GtpLogViewController class is responsible for managing user
/// interaction on the "GTP Log" view.
///
/// The "GTP Log" view actually consists of two views:
/// - The frontside view is a table view that displays log items as table view
///   cells. The user may drill down into each cell to view the details of the
///   log item that backs that cell.
/// - The backside view is a text view that displays log items as a raw textual
///   log. There is no user interaction on this view except for scrolling.
///
/// The user may switch between the two views by tapping a "flip" button in the
/// controller's navigation item.
///
///
/// @par Update strategies
///
/// The frontside view is updated continuously, even if it is currently not
/// visible. There is no deeper reason for this, the implementation simply
/// has grown this way.
///
/// The backside view is updated only if it is currently visible. When it
/// becomes visible, its content is reloaded to keep up with updates that were
/// missed while the view was not visible.
///
///
/// @par Auto-scrolling
///
/// The following is true for both the frontside and the backside view: If the
/// bottom of the view is currently visible, and a new item is added to the log,
/// the view is automatically scrolled so that it displays the new item.
///
/// For the frontside (=table) view, the mechanism how this automatic scrolling
/// works can be described as follows:
/// - If a new item is added to the log, GtpLogViewController learns about the
///   event from receiving the notification #gtpLogContentChanged.
/// - Automatic scrolling is therefore invoked by the (privately declared)
///   method gtpLogContentChanged:()
/// - Automatic scrolling is only invoked if the (privately declared) property
///   lastRowIsVisible is set
/// - lastRowIsVisible is set when tableView:cellForRowAtIndexPath:() is
///   invoked to request a cell for the last item in the log
///   - This happens correctly when the view is displayed for the first time,
///     and all items currently in the log can be displayed on a single screen
///   - This also happens correctly if the user scrolls towards the end of the
///     log and the last item becomes visible
/// - lastRowIsVisible also needs to be cleared when the user scrolls towards
///   the top of the log and the last item is no longer visible
///   - Here, things become a bit tricky because UITableView does not inform
///     its delegate (GtpLogViewController) when a cell goes off the screen.
///   - GtpLogViewController could tap into the UIScrollViewDelegate protocol
///     to handle scrolling, but this protocol is geared towards working with
///     view coordinates, instead of with table view cells
///   - For this reason, the logic for clearing lastRowIsVisible works as
///     follows
///   - Whenever tableView:cellForRowAtIndexPath:() is invoked and
///     lastRowIsVisible is true, it clears lastRowIsVisible as its first
///     operation
///   - The assumption here is that tableView:cellForRowAtIndexPath:() must
///     have been invoked because the user scrolled up or down
///   - If the user scrolled up, clearing lastRowIsVisible was the correct
///     thing to do because the last item in the log is now no longer visible
///     (or it is partially visible, but this amounts to the same thing because
///     automatic scrolling should now be disabled)
///   - If the user scrolled down (theoretical case only since the view is
///     already at the bottom, i.e. it already displays the last item), clearing
///     lastRowIsVisible was the wrong thing to do, but the mistake will be
///     corrected as soon as the code in tableView:cellForRowAtIndexPath:()
///     finds out that the cell for the last item in the log was requested - it
///     then sets lastRowIsVisible once more
///   - The assumption that tableView:cellForRowAtIndexPath:() must have been
///     invoked because the user scrolled up or down is wrong in one occasion:
///     It is also invoked when the cell for a single log item needs to be
///     refreshed
///   - GtpLogViewController learns about that event from receiving the
///     notification #gtpLogItemChanged
///   - The (privately declared) method gtpLogItemChanged:() therefore sets a
///     second flag - the privately declared property
///     updateScheduledByGtpLogItemChanged - to inform
///     tableView:cellForRowAtIndexPath:() that it has *NOT* been invoked
///     because of scrolling
///   - When tableView:cellForRowAtIndexPath:() finds that
///     updateScheduledByGtpLogItemChanged is set, it therefore does *NOT* clear
///     lastRowIsVisible as its first operation
// -----------------------------------------------------------------------------
@interface GtpLogViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
}

+ (GtpLogViewController*) controller;

/// @brief The model object
@property(nonatomic, retain) GtpLogModel* model;
/// @brief The frontside view. Log items are represented by table view cells.
@property(nonatomic, retain) IBOutlet UITableView* frontSideView;
/// @brief The backside view. Log items are represented by raw text.
@property(nonatomic, retain) IBOutlet UITextView* backSideView;

@end
