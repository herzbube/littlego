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
#import "../gtp/GtpClient.h"
#import "../ApplicationDelegate.h"


/// @brief This category declares private methods for the DebugViewController
/// class. 
@interface DebugViewController(Private)
- (void) nextCommand:(id)anObject;
- (void) setResponse:(NSString*)nsResponse;
- (void) exitClient;
- (void) exitEngine;
@end


@implementation DebugViewController

@synthesize textView;


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
  [textView setFont:[UIFont fontWithName:@"CourierNewPSMT" size:10]];
  [textView setText:@"Press the button to send commands..."];

  m_iNextCommand = 0;
  m_commandSequence = [NSArray arrayWithObjects:@"protocol_version",
                       @"name", @"version", @"boardsize 9", @"clear_board",
                       @"showboard", @"quit", nil];
  [m_commandSequence retain];
}

- (void) setResponse:(NSString*)nsResponse
{
  [textView setText:nsResponse];
}

- (void) nextCommand:(id)anObject
{
  NSString* nsCommand;
  if (m_iNextCommand >= [m_commandSequence count])
  {
    [self setResponse:@"No more commands"];
    return;
  }
  else
    nsCommand = (NSString*)[m_commandSequence objectAtIndex:m_iNextCommand];
  m_iNextCommand++;
  [[[ApplicationDelegate sharedDelegate] gtpClient] setGtpCommand:nsCommand];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
