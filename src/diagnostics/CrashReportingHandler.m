// -----------------------------------------------------------------------------
// Copyright 2016-2021 Patrick Näf (herzbube@herzbube.ch)
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

/// @brief Enumerates the types of buttons used in alerts presented by this
/// command.
enum AlertButtonTypeCrashReport
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
  [super dealloc];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Checks if there are any unset crash reports. If no then this method
/// does nothing. If yes then this method initiates the asynchronous handling
/// of the unsent crash reports. This method then immediately returns control to
/// the caller. Because this method is invoked during application launch, it
/// MUST return control as soon as possible.
///
/// Handling of unset crash reports is performed asynchronously. The process is
/// governed by the user preferences in the CrashReportingModel object that was
/// supplied to the initializer.
// -----------------------------------------------------------------------------
- (void) handleUnsentCrashReportsOrDoNothing
{
  FIRCrashlytics* crashlytics = [FIRCrashlytics crashlytics];

  // Must be set to NO, otherwise checkForUnsentReportsWithCompletion:()
  // does not work
  [crashlytics setCrashlyticsCollectionEnabled:NO];

  // The completion handler is invoked asynchronously
  [crashlytics checkForUnsentReportsWithCompletion:^(BOOL hasUnsentReports)
  {
    if (hasUnsentReports)
      [self handleUnsentCrashReports];
  }];
}

#pragma mark - Private helpers

- (void) handleUnsentCrashReports
{
  DDLogInfo(@"%@: Crash report detected, automaticReport = %d", self, self.crashReportingModel.automaticReport);

  if (self.crashReportingModel.automaticReport)
  {
    [self submitUnsentReports];
  }
  else
  {
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

- (void) submitUnsentReports
{
  DDLogInfo(@"%@: Submitting unset crash reports", self);

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    FIRCrashlytics* crashlytics = [FIRCrashlytics crashlytics];

    if (self.crashReportingModel.allowContact)
      [crashlytics setUserID:self.crashReportingModel.contactEmail];

    [crashlytics sendUnsentReports];
  }];
}

#pragma mark - Alert handler

// -----------------------------------------------------------------------------
/// @brief Alert handler method.
// -----------------------------------------------------------------------------
- (void) didDismissAlertWithButton:(enum AlertButtonTypeCrashReport)alertButtonType
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

  if (submitReport)
    [self submitUnsentReports];
  else
    [[FIRCrashlytics crashlytics] deleteUnsentReports];

  // Alert has been handled, so this handler object can now die
  [self autorelease];
}

@end
