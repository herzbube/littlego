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

// Typedef to improve code readability
typedef void (^CrashlyticsCompletionHandler) (BOOL);


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
  if (self.crashReportingModel.allowContact)
  {
    // Verified that this works! Setting the email address on the shared
    // Crashlytics object does not seem to work (tested with Crashlytics 3.7.3).
    report.userEmail = self.crashReportingModel.contactEmail;
  }

  if (self.crashReportingModel.automaticReport)
  {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        completionHandler(YES);
      }];
  }
  else
  {
    self.crashlyticsCompletionHandler = completionHandler;

    NSString* alertTitle = @"Little Go Unexpectedly Quit";
    NSString* alertMessage = @"Would you like to send a report so we can fix the problem?";

    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                    message:alertMessage
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Send report", @"Always send", @"Don't send", nil];
    alert.tag = AlertViewTypeSubmitCrashReport;
    [alert show];
    [alert release];

    // This handler object must remain alive until the alert view has been
    // handled
    [self retain];
  }
}

#pragma mark - UIAlertViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UIAlertViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  BOOL submitReport;
  switch (buttonIndex)
  {
    case AlertViewButtonTypeCrashReportSend:
    {
      submitReport = YES;
      break;
    }
    case AlertViewButtonTypeCrashReportAlwaysSend:
    {
      submitReport = YES;
      self.crashReportingModel.automaticReport = true;
      break;
    }
    case AlertViewButtonTypeCrashReportDontSend:
    {
      submitReport = NO;
      break;
    }
    default:
    {
      submitReport = NO;
      assert(false);
      DDLogError(@"Unknown alert button %ld", (long)buttonIndex);
      break;
    }
  }

  // Run the completion handler in all cases. Even if the user does not want the
  // report to be submitted, running the completion handler is necessary to
  // clear the report from the queue.
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    self.crashlyticsCompletionHandler(submitReport);
  }];

  // Alert view has been handled, so this handler object can now die
  [self autorelease];
}

@end
