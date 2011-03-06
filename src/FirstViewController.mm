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

#import "FirstViewController.h"
#import "gtp/GtpClient.h"
#import "gtp/GtpEngine.h"

#include <string>
#include <vector>
#include <iostream>  // for cout
#include <sys/stat.h>  // for mkfifo


/// @brief This category declares private methods for the FirstViewController
/// class. 
@interface FirstViewController(Private)
//- (void) fuegoClientThread:(id)anObject;
//- (void) fuegoEngineThread:(id)anObject;
- (void) setResponse:(NSString*)nsResponse;
- (void) setCommand:(NSString*)nsCommand;
- (void) nextCommand:(id)anObject;
- (void) exitClient;
- (void) exitEngine;
@end


@implementation FirstViewController

@synthesize textView;
@synthesize client;
@synthesize engine;


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

  mode_t pipeMode = S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH;
  NSString* tempDir = NSTemporaryDirectory();
  NSString* inputPipePath = [NSString pathWithComponents:[NSArray arrayWithObjects:tempDir, @"inputPipe", nil]];
  NSString* outputPipePath = [NSString pathWithComponents:[NSArray arrayWithObjects:tempDir, @"outputPipe", nil]];
  std::vector<std::string> pipeList;
  pipeList.push_back([inputPipePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
  pipeList.push_back([outputPipePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
  std::vector<std::string>::const_iterator it = pipeList.begin();
  for (; it != pipeList.end(); ++it)
  {
    std::string pipePath = *it;
    std::cout << "Creating input pipe " << pipePath << std::endl;
    int status = mkfifo(pipePath.c_str(), pipeMode);
    if (status == 0)
      std::cout << "Success!" << std::endl;
    else
    {
      std::cout << "Failure! Reason = ";
      switch (errno)
      {
        case EACCES:
          std::cout << "EACCES" << std::endl;
          break;
        case EEXIST:
          std::cout << "EEXIST" << std::endl;
          break;
        case ELOOP:
          std::cout << "ELOOP" << std::endl;
          break;
        case ENOENT:
          std::cout << "ENOENT" << std::endl;
          break;
        case EROFS:
          std::cout << "EROFS" << std::endl;
          break;
        default:
          std::cout << "Some other result: " << status << std::endl;
          break;
      }
    }
  }

  m_iNextCommand = 0;
  m_commandSequence = [NSArray arrayWithObjects:@"protocol_version",
                       @"name", @"version", @"boardsize 9", @"clear_board",
                       @"showboard", @"quit", nil];
  [m_commandSequence retain];
  

  self.client = [GtpClient clientWithInputPipe:inputPipePath outputPipe:outputPipePath responseReceiver:self];
  self.engine = [GtpEngine engineWithInputPipe:inputPipePath outputPipe:outputPipePath];
}

- (void) setResponse:(NSString*)nsResponse
{
  [textView setText:nsResponse];
}

- (void) nextCommand:(id)anObject
{
  NSString* nsCommand;
  if (m_iNextCommand > [m_commandSequence count])
    nsCommand = @"quit";
  else
    nsCommand = (NSString*)[m_commandSequence objectAtIndex:m_iNextCommand];
  m_iNextCommand++;
  [self.client setCommand:nsCommand];
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
