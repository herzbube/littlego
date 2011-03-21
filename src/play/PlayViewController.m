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
- (void) playForMe:(id)sender;
- (void) undo:(id)sender;
- (void) new:(id)sender;
//@}
@end


@implementation PlayViewController

@synthesize playView;

- (void) dealloc
{
  self.playView = nil;
  [super dealloc];
}

- (void) viewDidUnload
{
  self.playView = nil;
}

- (void) play:(id)sender
{
  // todo before actual playing, ask GoGame whether the move would be legal
  // -> GoGame queries Fuego with the "is_legal" GTP command
}

- (void) pass:(id)sender
{
  [[GoGame sharedGame] pass];
}

- (void) resign:(id)sender
{
  // TODO ask user for confirmation because this action cannot be undone
  [[GoGame sharedGame] resign];
}

- (void) playForMe:(id)sender
{
  [[GoGame sharedGame] playForMe];
}

- (void) undo:(id)sender
{
  [[GoGame sharedGame] undo];
}

- (void) new:(id)sender
{
  // TODO implement this
}

@end
