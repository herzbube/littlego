//
//  FirstViewController.h
//  Little Go
//
//  Created by Patrick Näf Moser on 29.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#include <string>

@interface FirstViewController : UIViewController {
  UITextView* textView;
  std::string m_inputPipePath;
  std::string m_outputPipePath;
  bool m_shouldExitClient;
  bool m_shouldExitEngine;
  NSThread* m_clientThread;
  NSThread* m_engineThread;
  std::string m_nextCommand;
  NSArray* m_commandSequence;
  int m_iNextCommand;
}

@property (nonatomic, retain) IBOutlet UITextView* textView;

@end
