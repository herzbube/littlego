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


#import "DebugViewController.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"


// Class extension
@interface DebugViewController()
- (void) updateView:(NSString*)newText;
// Notification responders
- (void) gtpCommandSubmitted:(NSNotification*)notification;
- (void) gtpResponseReceived:(NSNotification*)notification;
@end


@implementation DebugViewController

@synthesize textView;
@synthesize textCache;

- (void) dealloc
{
  self.textView = nil;
  self.textCache = nil;
  [super dealloc];
}

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

- (void) viewDidLoad
{
  [super viewDidLoad];

  UIFont* oldFont = self.textView.font;
  UIFont* newFont = [oldFont fontWithSize:oldFont.pointSize * 0.75];
  self.textView.font = newFont;
  [self updateView:self.textCache];
  self.textCache = nil;
}

- (void) viewDidUnload
{
  [super viewDidUnload];

  self.textView = nil;
  self.textCache = nil;
}

- (void) gtpCommandSubmitted:(NSNotification*)notification
{
  // TODO remove if really not needed; see gtpRsponseReceived for details
//  GtpCommand* command = (GtpCommand*)[notification object];
//  self.textView.text = [self.textView.text stringByAppendingFormat:@"%@\n", command.command, nil];
//  NSRange endOfTextRange = NSMakeRange([self.textView.text length], 0);
//  [self.textView scrollRangeToVisible:endOfTextRange];
}

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
  NSString* newText = [NSString stringWithFormat:@"%@\n%@\n\n", command.command, [response rawResponse], nil];
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

- (void) updateView:(NSString*)newText
{
  self.textView.text = [self.textView.text stringByAppendingString:newText];
  // TODO do not scroll if view is not at the end, i.e. if user has scrolled;
  NSRange endOfTextRange = NSMakeRange([self.textView.text length], 0);
  [self.textView scrollRangeToVisible:endOfTextRange];
}

@end
