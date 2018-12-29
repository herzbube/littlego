// -----------------------------------------------------------------------------
// Copyright 2016 Patrick Näf (herzbube@herzbube.ch)
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
#import "CrashReportingHandler.h"
#import "CrashReportingModel.h"
#import "../main/ApplicationDelegate.h"

// Typedef to improve code readability
typedef void (^CrashlyticsCompletionHandler) (BOOL);

/// @brief Enumerates the types of buttons used in alerts presented by this
/// command.
enum AlertButtonType
{
  AlertButtonTypeCrashReportSend,
  AlertButtonTypeCrashReportAlwaysSend,
  AlertButtonTypeCrashReportDontSend
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for CrashReportingHandler.
// -----------------------------------------------------------------------------
@interface CrashReportingHandler()
@property(nonatomic, assign) CrashReportingModel* crashReportingModel;
@property(nonatomic, copy) CrashlyticsCompletionHandler crashlyticsCompletionHandler;
@end


@implementation CrashReportingHandler

// -----------------------------------------------------------------------------
/// @brief Initializes a CrashReportingHandler object that uses data from the
/// specified model object @a crashReportingModel.
///
/// @note This is the designated initializer of CrashReportingHandler.
// -----------------------------------------------------------------------------
- (id) initWithModel:(CrashReportingModel*)crashReportingModel;
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.crashReportingModel = crashReportingModel;
  self.crashlyticsCompletionHandler = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CrashReportingHandler object.
///
/// Actually this is never called because Crashlytics retains its delegate,
/// which is this CrashReportingHandler object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.crashReportingModel = nil;
  self.crashlyticsCompletionHandler = nil;
  [super dealloc];
}

#pragma mark - CrashlyticsDelegate overrides

// -----------------------------------------------------------------------------
/// @brief CrashlyticsDelegate protocol method.
///
/// This method is invoked only if a crash report is pending submission. If it
/// is invoked, this method is invoked synchronously right away when Crashlytics
/// is configured with this delegate. Because this happens during application
/// launch, this method MUST return control as soon as possible.
// -----------------------------------------------------------------------------
- (void) crashlyticsDidDetectReportForLastExecution:(CLSReport*)report completionHandler:(void (^) (BOOL))completionHandler
{
  DDLogInfo(@"%@: Crash report detected, automaticReport = %d", self, self.crashReportingModel.automaticReport);

  if (self.crashReportingModel.allowContact)
  {
    // Verified that this works! Setting the email address on the shared
    // Crashlytics object does not seem to work (tested with Crashlytics 3.7.3).
    report.userEmail = self.crashReportingModel.contactEmail;
  }

  if (self.crashReportingModel.automaticReport)
  {
    [self runCrashlyticsCompletionHandler:completionHandler
                         withSubmitReport:YES];
  }
  else
  {
    self.crashlyticsCompletionHandler = completionHandler;

    NSString* alertTitle = @"Little Go Unexpectedly Quit";
    NSString* alertMessage = @"Would you like to send a report so we can fix the problem?";

    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                             message:alertMessage
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    void (^sendReportBlock) (UIAlertAction*) = ^(UIAlertAction* action)
    {
      [self didDismissAlertWithButton:AlertButtonTypeCrashReportSend];
    };
    UIAlertAction* sendReport = [UIAlertAction actionWithTitle:@"Send report"
                                                       style:UIAlertActionStyleCancel
                                                     handler:sendReportBlock];
    [alertController addAction:sendReport];

    void (^alwaysSendBlock) (UIAlertAction*) = ^(UIAlertAction* action)
    {
      [self didDismissAlertWithButton:AlertButtonTypeCrashReportAlwaysSend];
    };
    UIAlertAction* alwaysSend = [UIAlertAction actionWithTitle:@"Always send"
                                                        style:UIAlertActionStyleDefault
                                                      handler:alwaysSendBlock];
    [alertController addAction:alwaysSend];

    void (^dontSendBlock) (UIAlertAction*) = ^(UIAlertAction* action)
    {
      [self didDismissAlertWithButton:AlertButtonTypeCrashReportDontSend];
    };
    UIAlertAction* dontSend = [UIAlertAction actionWithTitle:@"Don't send"
                                                         style:UIAlertActionStyleDefault
                                                       handler:dontSendBlock];
    [alertController addAction:dontSend];

    [[ApplicationDelegate sharedDelegate].window.rootViewController presentViewController:alertController animated:YES completion:nil];

    // This handler object must remain alive until the alert has been handled
    [self retain];
  }
}

#pragma mark - Alert handler

// -----------------------------------------------------------------------------
/// @brief Alert handler method.
// -----------------------------------------------------------------------------
- (void) didDismissAlertWithButton:(enum AlertButtonType)alertButtonType
{
  DDLogInfo(@"%@: User selected alertButtonType = %u", self, alertButtonType);

  BOOL submitReport;
  switch (alertButtonType)
  {
    case AlertButtonTypeCrashReportSend:
    {
      submitReport = YES;
      break;
    }
    case AlertButtonTypeCrashReportAlwaysSend:
    {
      submitReport = YES;
      self.crashReportingModel.automaticReport = true;
      break;
    }
    case AlertButtonTypeCrashReportDontSend:
    {
      submitReport = NO;
      break;
    }
    default:
    {
      submitReport = NO;
      assert(false);
      DDLogError(@"Unknown alert button %ld", (long)alertButtonType);
      break;
    }
  }

  // Run the completion handler in all cases. Even if the user does not want the
  // report to be submitted, running the completion handler is necessary to
  // clear the report from the queue.
  [self runCrashlyticsCompletionHandler:self.crashlyticsCompletionHandler
                       withSubmitReport:submitReport];

  // Alert has been handled, so this handler object can now die
  [self autorelease];
}

#pragma mark - Private helpers

- (void) runCrashlyticsCompletionHandler:(CrashlyticsCompletionHandler)completionHandler
                        withSubmitReport:(BOOL)submitReport
{
  DDLogInfo(@"%@: Running Crashlytics completion handler, submitReport = %d", self, submitReport);

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    completionHandler(submitReport);
  }];
}

@end
