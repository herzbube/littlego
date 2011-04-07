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


// System includes
#import <UIKit/UIKit.h>


// -----------------------------------------------------------------------------
/// @brief The DebugViewController class is responsible for managing the debug
/// output view.
///
/// DebugViewController currently does nothing except logging all GTP commands
/// and GTP responses to a UITextView.
///
/// If the debug output view has not yet been created (because the user has
/// never switched to its tab), DebugViewController captures debug output in
/// a text "cache". When the debug output view is created, it is immediately
/// filled with the content of the cache.
///
/// @todo Research how much memory this controller and its associated view are
/// using. If possible, try to reduce the memory requirements. If necessary,
/// remove this feature altogether (only from the iPhone build?) and only log
/// to disk.
// -----------------------------------------------------------------------------
@interface DebugViewController : UIViewController
{
}

/// @brief The text view that displays the debug output.
@property(nonatomic, retain) IBOutlet UITextView* textView;
/// @brief A cache that captures all debug output until the debug output view
/// is actually created.
@property(retain) NSString* textCache;

@end
