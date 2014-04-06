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


// -----------------------------------------------------------------------------
/// @brief The DocumentViewController class is responsible for loading an HTML
/// resource file and displaying its content in the associated UIWebview object.
/// Alternatively, a client may provide the HTML document content as a string to
/// DocumentViewController upon creation.
///
/// The GUI has a number of web views that display different documents such as
/// the "About" information document. If DocumentViewController is instantiated
/// from a .nib file, it recognizes which document it is supposed to load by
/// examining the tag property of its associated view.
///
/// If DocumentViewController is instantiated via one of its convenience
/// constructors, it either just displays the provided HTML document, or loads
/// and displays the resource named in the constructor.
///
/// @todo Research how much memory this controller and its associated view are
/// using. If possible, try to reduce the memory requirements (e.g. only create
/// one instance of the controller/view pair instead of one instance per
/// document).
// -----------------------------------------------------------------------------
@interface DocumentViewController : UIViewController<UIWebViewDelegate>
{
}

+ (DocumentViewController*) controllerWithTitle:(NSString*)title htmlString:(NSString*)htmlString;
+ (DocumentViewController*) controllerWithTitle:(NSString*)title resourceName:(NSString*)resourceName;

/// @brief The view that this DocumentViewController is responsible for.
@property(nonatomic, retain) UIWebView* webView;
/// @brief The tag of this tab bar item provides this controller with the
/// context what it is supposed to display.
@property(nonatomic, assign) UITabBarItem* contextTabBarItem;

@end
