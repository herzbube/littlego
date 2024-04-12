// -----------------------------------------------------------------------------
// Copyright 2024 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The WebBrowserViewController class is responsible for displaying a
/// web view (a WKWebView object) together with a few web browser controls, thus
/// providing a minimal web browser user interface.
///
/// WebBrowserViewController displays the web browser controls in its navigation
/// item. If the controls should be visible WebBrowserViewController therefore
/// needs to be displayed in the stack of a UINavigationController.
///
/// If this is not possible, then whoever integrates WebBrowserViewController
/// into the UI is responsible for making the controls visible. For that
/// purpose, WebBrowserViewController exposes the controls as UIBarButtonItem
/// properties.
///
/// WebBrowserViewController provides the following web browser controls:
/// - A "go back" button.
/// - A "go forward" button.
/// - A "home" button. This button navigates to the "home" URL that was
///   specified when WebBrowserViewController was initialized.
///
/// WebBrowserViewController is initialized with a "home" URL, pointing to the
/// entry point that WebBrowserViewController should initially navigate to.
///
/// If the "home" URL is a file URL WebBrowserViewController allows the web
/// view to access all resources located in the parent folder that contains the
/// filesystem item referenced by the "home" URL. Examples:
///
/// - The "home" URL refers to /foo/bar/baz.html: The web view is allowed to
///   access everything under /foo/bar.
/// - The "home" URL refers to /foo/bar: The web view is allowed to access
///   everything under /foo.
///
/// If an attempt is made to navigate to a file URL that refers to a folder,
/// then WebBrowserViewController redirects the request to instead navigate to
/// the "index.html" file located in that folder. The purpose is to simulate
/// the behaviour of web servers during serverless browsing of file resources.
// -----------------------------------------------------------------------------
@interface WebBrowserViewController : UIViewController<WKNavigationDelegate>
{
}

- (id) initWithHomeUrl:(NSURL*)homeUrl;

@property(nonatomic, retain) NSURL* homeUrl;
@property(nonatomic, retain) UIBarButtonItem* backButton;
@property(nonatomic, retain) UIBarButtonItem* forwardButton;
@property(nonatomic, retain) UIBarButtonItem* homeButton;

@end
