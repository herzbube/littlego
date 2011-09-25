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


// Project includes
#import "GtpRawLogController.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GtpRawLogController.
// -----------------------------------------------------------------------------
@interface GtpRawLogController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UINibLoadingAdditions category
//@{
- (void) awakeFromNib;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
//@}
/// @name Notification responders
//@{
- (void) gtpCommandSubmitted:(NSNotification*)notification;
- (void) gtpResponseReceived:(NSNotification*)notification;
//@}
/// @name Updaters
//@{
- (void) updateView:(NSString*)newText;
//@}
@end


@implementation GtpRawLogController

@synthesize textView;
@synthesize textCache;

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpRawLogController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.textView = nil;
  self.textCache = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Is called after this GtpRawLogController object has been allocated
/// and initialized from DebugView.xib
///
/// @note This is a method from the UINibLoadingAdditions category (an addition
/// to NSObject, defined in UINibLoading.h). Although it has the same purpose,
/// the implementation via category is different from the NSNibAwaking informal
/// protocol on the Mac OS X platform.
// -----------------------------------------------------------------------------
- (void) awakeFromNib
{
  [super awakeFromNib];

  self.textCache = @"";

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gtpCommandSubmitted:)
                                               name:gtpCommandSubmittedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gtpResponseReceived:)
                                               name:gtpResponseReceivedNotification
                                             object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  UIFont* oldFont = self.textView.font;
  UIFont* newFont = [oldFont fontWithSize:oldFont.pointSize * 0.75];
  self.textView.text = nil;
  self.textView.font = newFont;
  [self updateView:self.textCache];
  self.textCache = nil;
}

// -----------------------------------------------------------------------------
/// @brief Called when the controller’s view is released from memory, e.g.
/// during low-memory conditions.
///
/// Releases additional objects (e.g. by resetting references to retained
/// objects) that can be easily recreated when viewDidLoad() is invoked again
/// later.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];

  self.textView = nil;
  self.textCache = nil;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #gtpCommandSubmitted notification.
// -----------------------------------------------------------------------------
- (void) gtpCommandSubmitted:(NSNotification*)notification
{
  // TODO remove if really not needed; see gtpRsponseReceived for details
//  GtpCommand* command = (GtpCommand*)[notification object];
//  self.textView.text = [self.textView.text stringByAppendingFormat:@"%@\n", command.command, nil];
//  NSRange endOfTextRange = NSMakeRange([self.textView.text length], 0);
//  [self.textView scrollRangeToVisible:endOfTextRange];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #gtpResponseReceived notification.
// -----------------------------------------------------------------------------
- (void) gtpResponseReceived:(NSNotification*)notification
{
  // TODO we have to wait for the response so that we can print out command and
  // response in sequence; if we print them separately, the sequence will be
  // broken like this:
  // - someone submits command
  // - gtpclient sends notification for submitted command
  // - debugview receives notification for submitted command & prints command
  // - gtpclient sends notification for received response
  // - someone else gets notification for received response ***BEFORE***
  //   debugview gets it; this other actor then submits another command
  // - gtpclient sends notification for submitted command
  // - debugview receives notification for submitted command & prints command
  // - debugview receives notification for received response & prints response
  // -----> debugview receives the response notification too late!!!!
  GtpResponse* response = (GtpResponse*)[notification object];
  GtpCommand* command = response.command;
  NSString* newText = [NSString stringWithFormat:@"%@\n%@\n\n", command.command, [response rawResponse]];
  if (self.textCache)
  {
    // Cache everything until debug view is activated and viewDidLoad() is
    // invoked; at this time the cached log will be transferred to the view
    // and elf.textCache will be nil'ed so that future updates are added
    // directly to the view
    self.textCache = [self.textCache stringByAppendingString:newText];
  }
  else
  {
    // TODO log should probably be truncated at some point, otherwise it will
    // grow to unlimited size; only let it grow to a certain number of lines
    // or commands; or clear the log when a new game is started; or something
    // similar
    [self updateView:newText];
  }
}

// -----------------------------------------------------------------------------
/// @brief Displays @a newText in the debug output text view.
// -----------------------------------------------------------------------------
- (void) updateView:(NSString*)newText
{
  self.textView.text = [self.textView.text stringByAppendingString:newText];
  // TODO do not scroll if view is not at the end, i.e. if user has scrolled;
  NSRange endOfTextRange = NSMakeRange([self.textView.text length], 0);
  [self.textView scrollRangeToVisible:endOfTextRange];
}

@end
