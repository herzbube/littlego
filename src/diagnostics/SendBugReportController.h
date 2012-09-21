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
/// Invoke sendBugReport() to trigger the process. When the method returns the
/// report may or may not have been sent - there is no way to distinguish
/// between the two cases. Sending the report may have failed because the device
/// is not configured for email, or because the user has cancelled the
/// operation. Even if the report has been submitted, the actual email may still
/// be waiting in the outgoing mail queue to be sent when there is again a
/// network connection.
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

@end
