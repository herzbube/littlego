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


// Project includes
#import "SendBugReportController.h"
#import "../command/diagnostics/GenerateDiagnosticsInformationFileCommand.h"
#import "../main/ApplicationDelegate.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for SendBugReportController.
// -----------------------------------------------------------------------------
@interface SendBugReportController()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
/// @name MFMailComposeViewControllerDelegate methods
//@{
- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
//@}
/// @name Private helpers
//@{
- (bool) canSendMail;
- (bool) generateDiagnosticsInformationFileInternal;
- (void) presentMailComposeController;
//@}
/// @name Private properties
//@{
@property(nonatomic, retain) UIViewController* modalViewControllerParent;
@property(nonatomic, retain) NSString* diagnosticsInformationFilePath;
//@}
@end


@implementation SendBugReportController

@synthesize modalViewControllerParent;
@synthesize diagnosticsInformationFilePath;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor.
// -----------------------------------------------------------------------------
+ (SendBugReportController*) controller
{
  SendBugReportController* controller = [[SendBugReportController alloc] init];
  if (controller)
    [controller autorelease];
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a SendBugReportController object.
///
/// @note This is the designated initializer of SendBugReportController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.modalViewControllerParent = nil;
  self.diagnosticsInformationFilePath = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SendBugReportController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.modalViewControllerParent = nil;
  self.diagnosticsInformationFilePath = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Triggers the "send bug report" process as described in the class
/// documentation. @a aModalViewControllerParent is used to present the "mail
/// compose" view controller.
// -----------------------------------------------------------------------------
- (void) sendBugReport:(UIViewController*)aModalViewControllerParent
{
  self.modalViewControllerParent = aModalViewControllerParent;
  if (! [self canSendMail])
    return;
  if (! [self generateDiagnosticsInformationFileInternal])
    return;
  [self presentMailComposeController];
}

// -----------------------------------------------------------------------------
/// @brief Generates the diagnostics information file for later transfer with
/// iTunes file sharing. Displays an alert to let the user know the name of the
/// file.
// -----------------------------------------------------------------------------
- (void) generateDiagnosticsInformationFile
{
  if (! [self generateDiagnosticsInformationFileInternal])
    return;
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Information generated"
                                                  message:[NSString stringWithFormat:@"Diagnostics information has been generated and is ready for transfer to your computer via iTunes file sharing. In iTunes look for the file named '%@'.", bugReportDiagnosticsInformationFileName]
                                                 delegate:nil
                                        cancelButtonTitle:nil
                                        otherButtonTitles:@"Ok", nil];
  alert.tag = AlertViewTypeDiagnosticsInformationFileGenerated;
  [alert show];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the device is configured for sending emails. Displays
/// an alert and returns false if the device is not configured.
// -----------------------------------------------------------------------------
- (bool) canSendMail
{
  bool canSendMail = [MFMailComposeViewController canSendMail];
  if (! canSendMail)
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Operation failed"
                                                    message:@"This device is not configured to send email."
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    alert.tag = AlertViewTypeCannotSendBugReport;
    [alert show];
  }
  return canSendMail;
}

// -----------------------------------------------------------------------------
/// @brief Generates the diagnostics information file. Returns true on success,
/// false on failure. Displays an alert on failure, but remains silent on
/// success.
// -----------------------------------------------------------------------------
- (bool) generateDiagnosticsInformationFileInternal
{
  GenerateDiagnosticsInformationFileCommand* command = [[GenerateDiagnosticsInformationFileCommand alloc] init];
  // The command object must survive execution so that we can get at the path
  // where the diagnosics information file was stored
  [command retain];
  bool success = [command submit];
  self.diagnosticsInformationFilePath = command.diagnosticsInformationFilePath;
  [command release];
  if (! success)
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Operation failed"
                                                    message:@"An error occurred while generating diagnostics information."
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Very funny!", nil];
    alert.tag = AlertViewTypeDiagnosticsInformationFileNotGenerated;
    [alert show];
  }
  return success;
}

// -----------------------------------------------------------------------------
/// @brief Displays the "mail compose" view controller.
// -----------------------------------------------------------------------------
- (void) presentMailComposeController
{
  MFMailComposeViewController* mailComposeViewController = [[MFMailComposeViewController alloc] init];
  mailComposeViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  mailComposeViewController.mailComposeDelegate = self;

  mailComposeViewController.toRecipients = [NSArray arrayWithObject:bugReportEmailRecipient];
  mailComposeViewController.subject = bugReportEmailSubject;
  NSString* bugReportMessageTemplateFilePath = [[ApplicationDelegate sharedDelegate].resourceBundle pathForResource:bugReportMessageTemplateResource ofType:nil];
  NSString* messageBody = [NSString stringWithContentsOfFile:bugReportMessageTemplateFilePath encoding:NSUTF8StringEncoding error:nil];
  [mailComposeViewController setMessageBody:messageBody isHTML:NO];
  NSData* data = [NSData dataWithContentsOfFile:self.diagnosticsInformationFilePath];
  NSString* mimeType = bugReportDiagnosticsInformationFileMimeType;
  [mailComposeViewController addAttachmentData:data mimeType:mimeType fileName:bugReportDiagnosticsInformationFileName];

  [self.modalViewControllerParent presentModalViewController:mailComposeViewController animated:YES];
  [mailComposeViewController release];
}

// -----------------------------------------------------------------------------
/// @brief MFMailComposeViewControllerDelegate method
// -----------------------------------------------------------------------------
- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
  [self.modalViewControllerParent dismissModalViewControllerAnimated:YES];
  switch (result)
  {
    case MFMailComposeResultSent:
    {
      DDLogInfo(@"SendBugReportController: Bug report sent");
      break;
    }
    case MFMailComposeResultCancelled:
    {
      DDLogInfo(@"SendBugReportController: Bug report cancelled");
      break;
    }
    case MFMailComposeResultSaved:
    {
      DDLogInfo(@"SendBugReportController: Bug report saved to draft folder");
      break;
    }
    case MFMailComposeResultFailed:
    {
      NSString* logMessage = [NSString stringWithFormat:@"SendBugReportController: Sending bug report failed. Error code = %d, error description = %@",
                              [error code],
                              [error localizedDescription]];
      DDLogError(logMessage);
      break;
    }
    default:
    {
      NSString* logMessage = [NSString stringWithFormat:@"SendBugReportController: Sending bug report finished with unknown result: %d",
                              result];
      DDLogInfo(logMessage);
      break;
    }
  }
}

@end
