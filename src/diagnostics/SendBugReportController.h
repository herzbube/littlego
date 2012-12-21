// -----------------------------------------------------------------------------
// Copyright 2012 Patrick Näf (herzbube@herzbube.ch)
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


// System includes
#import <MessageUI/MFMailComposeViewController.h>

// Forward declarations
@class SendBugReportController;


// -----------------------------------------------------------------------------
/// @brief The SendBugReportControllerDelegate protocol must be implemented by
/// the delegate of SendBugReportController.
///
/// Although both methods in this protocol are marked as optional, the delegate
/// @b must implement the one that matches the method that is invoked on
/// SendBugReportController.
// -----------------------------------------------------------------------------
@protocol SendBugReportControllerDelegate
@optional
/// @brief This method is invoked after @a sendBugReportController has finished
/// managing the process of sending a bug report.
///
/// When the delegate receives this message, the bug report may or may not have
/// been sent - there is no way to distinguish between the two cases. Sending
/// the report may have failed because the device is not configured for email,
/// or because the user has cancelled the operation. Even if the report has been
/// submitted, the actual email may still be waiting in the outgoing mail queue
/// to be sent when there is again a network connection.
///
/// @note When the delegate receives this message, it is guaranteed that any
/// alert that was displayed as part of the "send a bug report" process has
/// been dismissed by the user.
- (void) sendBugReportDidFinish:(SendBugReportController*)sendBugReportController;
/// @brief This method is invoked after @a sendBugReportController has finished
/// generating the diagnostics information file.
///
/// @note When the delegate receives this message, it is guaranteed that any
/// alert that was displayed as part of the generation process has been
/// dismissed by the user.
- (void) generateDiagnosticsInformationFileDidFinish:(SendBugReportController*)sendBugReportController;
@end


// -----------------------------------------------------------------------------
/// @brief The SendBugReportController class is responsible for managing the
/// process of sending a bug report.
///
/// The process consists of two distinct parts:
/// - Collecting diagnostics information in a single .zip archive that can be
///   attached to the bug report
/// - Displaying a "send email" view, pre-filled with all necessary information
///   and the .zip archive attached, so that the user only has to tap the "send"
///   button to send the message. The user can further edit the email message
///   before sending it.
///
/// Invoke sendBugReport:() to trigger the entire two-step process. The method
/// returns before the process has finished. To get a notification when the
/// process has finished you need to configure SendBugReportController with a
/// delegate.
///
/// Invoke generateDiagnosticsInformationFile() to just generate the file with
/// diagnostics information (part one of the whole "send a bug report" process).
// -----------------------------------------------------------------------------
@interface SendBugReportController : NSObject <MFMailComposeViewControllerDelegate>
{
}

+ (SendBugReportController*) controller;
- (void) sendBugReport:(UIViewController*)aModalViewControllerParent;
- (void) generateDiagnosticsInformationFile;

/// @brief This is the delegate that will be informed when the process of
/// sending a bug report has finished. Setting the delegate is optional.
@property(nonatomic, assign) id<SendBugReportControllerDelegate> delegate;

@end
