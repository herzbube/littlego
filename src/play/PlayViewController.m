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
#import "PlayViewController.h"
#import "../go/GoGame.h"


/// @brief This category declares private methods for the DebugViewController
/// class. 
@interface PlayViewController(Private)
/// @name Action methods for toolbar items
//@{
- (void) play:(id)sender;
- (void) pass:(id)sender;
- (void) resign:(id)sender;
- (void) undo:(id)sender;
- (void) new:(id)sender;
//@}
@end


@implementation PlayViewController

@synthesize playView;
@synthesize activityIndicator;


static PlayViewController* sharedController = nil;
+ (PlayViewController*) sharedController
{
  @synchronized(self)
  {
    assert(sharedController != nil);
    return sharedController;
  }
}

- (void) dealloc
{
  self.playView = nil;
  self.activityIndicator = nil;
  [super dealloc];
}

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
- (void)viewDidLoad
{
  sharedController = self;
  [super viewDidLoad];
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

- (void) play:(id)sender
{
  // TODO should initiate this sequence
  // - determine the GoPoint that the player selected
  // - create a GoMove object using the GoPoint
  // - submit the GoMove to GoPlayer, or let GoMove submit itself
  // - GoPlayer does some stuff, then updates the GoGame
  // Not yet clear:
  // - what about GoBoard? does this have any state relating to the game?
  //   probably not
  // - who generates and submits the GtpCommand? it is desirable that there be
  //   a single interface to the GtpClient
  [self startActivityIndicator];
  [[GoGame sharedGame] playForMe];
  [self stopActivityIndicator];
}

- (void) pass:(id)sender
{
}

- (void) resign:(id)sender
{
}

- (void) undo:(id)sender
{
}

- (void) new:(id)sender
{
}

- (void) startActivityIndicator
{
  [self.activityIndicator startAnimating];
}

- (void) stopActivityIndicator
{
  [self.activityIndicator stopAnimating];
}

@end
