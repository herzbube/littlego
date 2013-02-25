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
/// @name UIAlertViewDelegate protocol
//@{
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
//@}
/// @name Private helpers
//@{
- (bool) canSendMail;
- (bool) generateDiagnosticsInformationFileInternal;
- (void) presentMailComposeController;
- (NSString*) mailMessageBody;
- (void) notifyDelegate;
//@}
/// @name Private properties
//@{
@property(nonatomic, assign) bool sendBugReportMode;
@property(nonatomic, retain) UIViewController* modalViewControllerParent;
@property(nonatomic, retain) NSString* diagnosticsInformationFilePath;
//@}
@end


@implementation SendBugReportController

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

  self.delegate = nil;
  self.bugReportDescription = @"_____";
  self.bugReportStepsToReproduce = [NSArray arrayWithObjects:@"_____", @"_____", @"_____", nil];
  self.sendBugReportMode = false;
  self.modalViewControllerParent = nil;
  self.diagnosticsInformationFilePath = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SendBugReportController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.bugReportDescription = nil;
  self.bugReportStepsToReproduce = nil;
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
  self.sendBugReportMode = true;
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
  self.sendBugReportMode = false;
  if (! [self generateDiagnosticsInformationFileInternal])
    return;
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Information generated"
                                                  message:[NSString stringWithFormat:@"Diagnostics information has been generated and is ready for transfer to your computer via iTunes file sharing. In iTunes look for the file named '%@'.", bugReportDiagnosticsInformationFileName]
                                                 delegate:self
                                        cancelButtonTitle:nil
                                        otherButtonTitles:@"Ok", nil];
  alert.tag = AlertViewTypeDiagnosticsInformationFileGenerated;
  [alert show];
  [alert release];
  [self retain];  // must survive until the delegate method is invoked
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
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    alert.tag = AlertViewTypeCannotSendBugReport;
    [alert show];
    [alert release];
    [self retain];  // must survive until the delegate method is invoked
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
  GenerateDiagnosticsInformationFileCommand* command = [[[GenerateDiagnosticsInformationFileCommand alloc] init] autorelease];
  bool success = [command submit];
  self.diagnosticsInformationFilePath = command.diagnosticsInformationFilePath;
  if (! success)
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Operation failed"
                                                    message:@"An error occurred while generating diagnostics information."
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Very funny!", nil];
    alert.tag = AlertViewTypeDiagnosticsInformationFileNotGenerated;
    [alert show];
    [alert release];
    [self retain];  // must survive until the delegate method is invoked
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
  NSString* messageBody = [self mailMessageBody];
  [mailComposeViewController setMessageBody:messageBody isHTML:NO];
  NSData* data = [NSData dataWithContentsOfFile:self.diagnosticsInformationFilePath];
  NSString* mimeType = bugReportDiagnosticsInformationFileMimeType;
  [mailComposeViewController addAttachmentData:data mimeType:mimeType fileName:bugReportDiagnosticsInformationFileName];

  [self.modalViewControllerParent presentViewController:mailComposeViewController animated:YES completion:nil];
  [mailComposeViewController release];
  [self retain];  // must survive until the delegate method is invoked
}

// -----------------------------------------------------------------------------
/// @brief Returns the message body for the bug report email.
// -----------------------------------------------------------------------------
- (NSString*) mailMessageBody
{
  NSString* bugReportStepLines = @"";
  int bugReportStepNumber = 1;
  for (NSString* bugReportStepString in self.bugReportStepsToReproduce)
  {
    NSString* bugReportStepLine = [NSString stringWithFormat:@"%d. %@", bugReportStepNumber, bugReportStepString];
    if (bugReportStepNumber > 1)
      bugReportStepLines = [bugReportStepLines stringByAppendingString:@"\n"];
    bugReportStepLines = [bugReportStepLines stringByAppendingString:bugReportStepLine];
    ++bugReportStepNumber;
  }

  NSString* bugReportMessageTemplateFilePath = [[ApplicationDelegate sharedDelegate].resourceBundle pathForResource:bugReportMessageTemplateResource ofType:nil];
  NSString* bugReportMessageTemplateString = [NSString stringWithContentsOfFile:bugReportMessageTemplateFilePath encoding:NSUTF8StringEncoding error:nil];
  return [NSString stringWithFormat:bugReportMessageTemplateString, self.bugReportDescription, bugReportStepLines];
}

// -----------------------------------------------------------------------------
/// @brief MFMailComposeViewControllerDelegate method
// -----------------------------------------------------------------------------
- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
  [self.modalViewControllerParent dismissViewControllerAnimated:YES completion:nil];
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
      DDLogError(@"%@", logMessage);
      break;
    }
    default:
    {
      NSString* logMessage = [NSString stringWithFormat:@"SendBugReportController: Sending bug report finished with unknown result: %d",
                              result];
      DDLogInfo(@"%@", logMessage);
      break;
    }
  }
  [self autorelease];  // balance retain that is sent before the mail view is shown
  [self notifyDelegate];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user dismissing an alert view for which this controller
/// is the delegate.
// -----------------------------------------------------------------------------
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  [self autorelease];  // balance retain that is sent before an alert is shown
  [self notifyDelegate];
}

// -----------------------------------------------------------------------------
/// @brief Notifies the delegate that the process managed by this controller
/// has ended.
// -----------------------------------------------------------------------------
- (void) notifyDelegate
{
  if (self.delegate)
  {
    if (self.sendBugReportMode)
      [self.delegate sendBugReportDidFinish:self];
    else
      [self.delegate generateDiagnosticsInformationFileDidFinish:self];
  }
}

@end
