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


// Project includes
#import "../../ui/EditTextController.h"
#import "../../ui/ItemPickerController.h"

// Forward declarations
@class EditEstimatedScoreController;


// -----------------------------------------------------------------------------
/// @brief The EditEstimatedScoreControllerDelegate protocol must be implemented
/// by the delegate of EditEstimatedScoreController.
// -----------------------------------------------------------------------------
@protocol EditEstimatedScoreControllerDelegate
/// @brief Notifies the delegate that the editing session has ended.
///
/// The delegate should dismiss the EditEstimatedScoreController in response to
/// this method invocation.
///
/// If @a didChangeEstimatedScore is true, the user has changed the estimated
/// score. The new estimated score values are written back to the
/// EditEstimatedScoreController object's properties @a estimatedScoreSummary
/// and @a estimatedScoreValue. If @a didChangeEstimatedScore is false, the user
/// has cancelled the editing process, or completed it without actually changing
/// the estimated score.
- (void) editEstimatedScoreControllerDidEndEditing:(EditEstimatedScoreController*)controller didChangeEstimatedScore:(bool)didChangeEstimatedScore;
@end


// -----------------------------------------------------------------------------
/// @brief The EditEstimatedScoreController class is responsible for displaying
/// a view that lets the user edit an estimated score, consisting of a score
/// summary and, if the summary indicates that a given player won, a score
/// value.
///
/// Editing the estimated score cannot be handled by ItemPickerController
/// because it requires the user to edit two items:
/// - A list of possible score summaries (black wins, white wins, tie)
/// - An actual score value (when black wins or white wins)
///
/// EditEstimatedScoreController expects to be presented modally or in a popup
/// by a navigation controller. EditEstimatedScoreController populates its own
/// navigation item with controls that are then expected to be displayed in the
/// navigation bar of the parent navigation controller.
// -----------------------------------------------------------------------------
@interface EditEstimatedScoreController : UIViewController <ItemPickerDelegate, UITextFieldDelegate, EditTextDelegate>
{
}

+ (EditEstimatedScoreController*) controllerWithEstimatedScoreSummary:(enum GoScoreSummary)estimatedScoreSummary
                                                  estimatedScoreValue:(double)estimatedScoreValue
                                                             delegate:(id<EditEstimatedScoreControllerDelegate>)delegate;

/// @brief This is the delegate that will be informed when the user has finished
/// editing the estimated score.
@property(nonatomic, assign) id<EditEstimatedScoreControllerDelegate> delegate;
/// @brief The summary of the estimated score.
@property(nonatomic, assign, readonly) enum GoScoreSummary estimatedScoreSummary;
/// @brief The estimated score value (relevant only if @e estimatedScoreSummary
/// is #GoScoreSummaryBlackWins or #GoScoreSummaryWhiteWins).
@property(nonatomic, assign, readonly) double estimatedScoreValue;

@end
