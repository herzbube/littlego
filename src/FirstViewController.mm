//
//  FirstViewController.m
//  Little Go
//
//  Created by Patrick Näf Moser on 29.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FirstViewController.h"

#include <string>
#include <vector>
#include <sstream>   // stringstream
#include <fstream>   // ifstream and ofstream
#include <iostream>  // for cout
#include <sys/stat.h>  // for mkfifo
#include <fuego/FuegoMainUtil.h>


/// @brief This category declares private methods for the FirstViewController
/// class. 
@interface FirstViewController(Private)
- (void) fuegoClientThread:(id)anObject;
- (void) fuegoEngineThread:(id)anObject;
- (void) setResponse:(NSString*)nsResponse;
- (void) setCommand:(NSString*)nsCommand;
- (void) nextCommand:(id)anObject;
- (void) exitClient;
- (void) exitEngine;
- (bool) shouldExitClient;
- (bool) shouldExitEngine;
- (void) setFuegoState:(NSString*)stateText;
@end


@implementation FirstViewController

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
  [textView setText:@"Setting up Fuego..."];

  mode_t pipeMode = S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH;
  NSString* tempDir = NSTemporaryDirectory();
  m_inputPipePath = [tempDir cStringUsingEncoding:[NSString defaultCStringEncoding]];
  m_inputPipePath += "/inputPipe";
  m_outputPipePath = [tempDir cStringUsingEncoding:[NSString defaultCStringEncoding]];
  m_outputPipePath += "/outputPipe";
  std::vector<std::string> pipeList;
  pipeList.push_back(m_inputPipePath);
  pipeList.push_back(m_outputPipePath);
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
  
  m_clientThread = nil;
  m_engineThread = nil;
 
  m_clientThread = [[NSThread alloc] initWithTarget:self selector:@selector(fuegoClientThread:) object:nil];
  [m_clientThread start];
  
  m_engineThread = [[NSThread alloc] initWithTarget:self selector:@selector(fuegoEngineThread:) object:nil];
  [m_engineThread start];
}

- (void) setFuegoState:(NSString*)stateText
{
  [textView setText:stateText];
}

- (void) setResponse:(NSString*)nsResponse
{
  [textView setText:nsResponse];
}

- (void) setCommand:(NSString*)nsCommand
{
  m_nextCommand = [nsCommand cStringUsingEncoding:[NSString defaultCStringEncoding]];
}

- (void) fuegoClientThread:(id)portArray
{
  // Create an autorelease pool as the very first thing in this thread
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  
  m_shouldExitClient = false;
  
  // Stream to write commands for the GTP engine
  std::ofstream commandStream(m_inputPipePath.c_str());
  // Stream to read responses from the GTP engine
  std::ifstream responseStream(m_outputPipePath.c_str());
  
  std::string singleLineResponse;
  std::string fullResponse;

  // The timer is required because otherwise the run loop has no input source.
  // In dgsmonX the input source probably was the NSConnection or one of the
  // ports...
  NSDate* distantFuture = [NSDate distantFuture]; 
  NSTimer* distantFutureTimer = [[NSTimer alloc] initWithFireDate:distantFuture
                                                        interval:1.0
                                                          target:self
                                                        selector:@selector(setClientThread:)   // pseudo selector
                                                        userInfo:nil
                                                          repeats:NO];
  [[NSRunLoop currentRunLoop] addTimer:distantFutureTimer forMode:NSDefaultRunLoopMode];

  [self performSelectorOnMainThread:@selector(setFuegoState:) withObject:@"Fuego engine running,\nwaiting for the first command..." waitUntilDone:NO];

  while (true)
  {
    bool hasInputSources = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                                    beforeDate:distantFuture];
    // hasInputSources should always be true, because the run loop should
    // always have input sources (the NSPort objects in portArray).
    if (! hasInputSources)
      break;
    if ([self shouldExitClient])
      break;

    if (m_nextCommand.empty())
    {
      @synchronized(self)
      {
        std::cout << "Got empty command, do nothing" << std::endl;
      }
      continue;
    }

    // Wake up the engine
    commandStream << m_nextCommand << std::endl;

    // Read the engine's response (blocking if necessary)
    fullResponse = "";
    while (true)
    {
      getline(responseStream, singleLineResponse);
      if (singleLineResponse.empty())
        break;
      if (! fullResponse.empty())
        fullResponse += "\n";
      fullResponse += singleLineResponse;
    }

    // Notify the main thread of the response
    NSString* nsResponse = [NSString stringWithCString:fullResponse.c_str() 
                                              encoding:[NSString defaultCStringEncoding]];
    [self performSelectorOnMainThread:@selector(setResponse:) withObject:nsResponse waitUntilDone:NO];

    if (m_nextCommand == "quit")
      break;
    m_nextCommand = "";
  }
  @synchronized(self)
  {
    std::cout << "Fuego client stopped" << std::endl;
  }

  // Deallocate the autorelease pool as the very last thing in this thread
  [pool release];
}

- (void) fuegoEngineThread:(id)portArray
{
  // Create an autorelease pool as the very first thing in this thread
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  [self performSelectorOnMainThread:@selector(setFuegoState:) withObject:@"Fuego engine starting up..." waitUntilDone:NO];
  @synchronized(self)
  {
    std::cout << "Fuego engine is starting up..." << std::endl;
  }
  
  m_shouldExitEngine = false;

  NSArray* nsArgv = [[NSProcessInfo processInfo] arguments];
  NSString* nsProgramName = [nsArgv objectAtIndex:0];

  char programName[255];
  char inputPipeParameterName[255];
  char inputPipeParameterValue[255];
  char outputPipeParameterName[255];
  char outputPipeParameterValue[255];
  char noBookParameterName[255];
  sprintf(programName, "%s", [nsProgramName cStringUsingEncoding:[NSString defaultCStringEncoding]]);  //"/path/to/fuego");
  sprintf(inputPipeParameterName, "%s", "--input-pipe");
  sprintf(inputPipeParameterValue, "%s", m_inputPipePath.c_str());
  sprintf(outputPipeParameterName, "%s", "--output-pipe");
  sprintf(outputPipeParameterValue, "%s", m_outputPipePath.c_str());
  sprintf(noBookParameterName, "%s", "--nobook");
  int argc = 6;
  char* argv[argc];
  argv[0] = programName;
  argv[1] = inputPipeParameterName;
  argv[2] = inputPipeParameterValue;
  argv[3] = outputPipeParameterName;
  argv[4] = outputPipeParameterValue;
  argv[5] = noBookParameterName;
  @synchronized(self)
  {
    std::cout << "Program name is " << programName << std::endl;
  }
  try
  {
    int exitCode = FuegoMainUtil::FuegoMain(argc, argv);
    @synchronized(self)
    {
      std::cout << "FuegoMain() returned with exit code " << exitCode << std::endl;
    }
  }
  catch(std::exception& e)
  {
    @synchronized(self)
    {
      std::cout << "Exception caught" << std::endl;
      std::cout << "Reason: " << e.what() << std::endl;
    }
  }
  catch(...)
  {
    @synchronized(self)
    {
      std::cout << "Unknown exception caught" << std::endl;
    }
  }
  @synchronized(self)
  {
    std::cout << "Fuego engine stopped" << std::endl;
  }

  [self performSelectorOnMainThread:@selector(setFuegoState:) withObject:@"Fuego engine stopped." waitUntilDone:NO];

  // Deallocate the autorelease pool as the very last thing in this thread
  [pool release];
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

  // Make sure that the thread terminates. This must happen before any
  // DGSMonXServer objects that it still accesses are deallocated
  // -> After invoking this method, the object referenced by m_monitoringThread
  //    is soon going to be deallocated (as soon as the other thread has had
  //    time to do so)
  // -> Do ***NOT*** access m_monitoringThread after this !!!
  [self performSelector:@selector(exitClient) onThread:m_clientThread withObject:nil waitUntilDone:YES];
  [self performSelector:@selector(exitEngine) onThread:m_engineThread withObject:nil waitUntilDone:YES];
  m_clientThread = nil;   // make sure that we don't do anything stupid :-)
  m_engineThread = nil;   // make sure that we don't do anything stupid :-)
}


- (void)dealloc {
    [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if this thread should terminate.
// -----------------------------------------------------------------------------
- (bool) shouldExitClient;
{
  return m_shouldExitClient;
}
// -----------------------------------------------------------------------------
/// @brief Returns true if this thread should terminate.
// -----------------------------------------------------------------------------
- (bool) shouldExitEngine;
{
  return m_shouldExitEngine;
}

// -----------------------------------------------------------------------------
/// @brief Sets the termination flag of this thread to true (i.e. shouldExit()
/// will return true after this method has been invoked).
// -----------------------------------------------------------------------------
- (void) exitClient
{
  m_shouldExitClient = true;
}
// -----------------------------------------------------------------------------
/// @brief Sets the termination flag of this thread to true (i.e. shouldExit()
/// will return true after this method has been invoked).
// -----------------------------------------------------------------------------
- (void) exitEngine
{
  m_shouldExitEngine = true;
}

- (void) nextCommand:(id)anObject
{
  NSString* nsCommand;
  if (m_iNextCommand > [m_commandSequence count])
    nsCommand = @"quit";
  else
    nsCommand = (NSString*)[m_commandSequence objectAtIndex:m_iNextCommand];
  m_iNextCommand++;
  [self performSelector:@selector(setCommand:) onThread:m_clientThread withObject:nsCommand waitUntilDone:NO];
}

@end
