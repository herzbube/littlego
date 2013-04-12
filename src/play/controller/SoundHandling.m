// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "SoundHandling.h"
#import "../model/PlayViewModel.h"
#import "../../main/ApplicationDelegate.h"
#import "../../go/GoGame.h"

// System includes
#include <AudioToolbox/AudioServices.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SoundHandling.
// -----------------------------------------------------------------------------
@interface SoundHandling()
@property(nonatomic, assign) PlayViewModel* model;
@property(nonatomic, assign) SystemSoundID playStoneSystemSound;
@end


@implementation SoundHandling

// -----------------------------------------------------------------------------
/// @brief Initializes a SoundHandling object with user defaults data.
///
/// @note This is the designated initializer of SoundHandling.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.disabled = false;
  // NSString and CFStringRef are toll-free bridged types, which allows to
  // simply cast NSString* into a CFStringRef.
  // TODO: We should use ApplicationDelegate.resourceBundle here, but how can
  // we get from NSBundle to CFBundle? These are not toll-free bridged types...
  CFURLRef playStoneURLRef = CFBundleCopyResourceURL(CFBundleGetMainBundle(), (CFStringRef)playStoneSoundFileResource, NULL, NULL);
  AudioServicesCreateSystemSoundID(playStoneURLRef, &_playStoneSystemSound);
  CFRelease(playStoneURLRef);

  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  self.model = [delegate playViewModel];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(computerPlayerThinkingStops:) name:computerPlayerThinkingStops object:nil];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SoundHandling object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  AudioServicesDisposeSystemSoundID(self.playStoneSystemSound);
  self.model = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStops notification.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingStops:(NSNotification*)notification
{
  if (self.disabled)
    return;

  GoGame* game = [GoGame sharedGame];
  if (GoGameStateGameHasEnded == game.state)
    ;  // do not abort, this is the case where the computer has finished
       // calculating the score
  else if ([game isComputerPlayersTurn])
    return;

  if (self.model.vibrate)
  {
    // There is a similar function AudioServicesPlayAlertSound(). According to
    // the following blog article, the difference is that on iOS devices that
    // do not support vibration, AudioServicesPlayAlertSound() plays a beep
    // sound, whereas AudioServicesPlaySystemSound() does nothing.
    // http://blog.mugunthkumar.com/coding/iphone-tutorial-better-way-to-check-capabilities-of-ios-devices/
    //
    // On developer.apple.com there are two articles that refer to vibration:
    // - Multimedia Programming Guide: This one says to use
    //   AudioServicesPlaySystemSound(). It does not mention the beep sound,
    //   but it says that this does nothing on an iPod touch
    // - System Sound Services Reference: Seems to confirm the information from
    //   the Multimedia Programming Guide, although confusingly mentions
    //   AudioServicesPlayAlertSound() in describing the kSystemSoundID_Vibrate
    //   constant. This is probably an error.
    //
    // Since I don't have an iPod touch I cannot verify which information is
    // true. The only thing I know is that the simulator does not vibrate :-)
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
  }

  if (self.model.playSound)
  {
    AudioServicesPlaySystemSound(self.playStoneSystemSound);
  }
}

@end
