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


// Project includes
#import "WebBrowserViewController.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for WebBrowserViewController.
// -----------------------------------------------------------------------------
@interface WebBrowserViewController()
@property(nonatomic, retain) WKWebView* webView;
@property(nonatomic, retain) UIBarButtonItem* backButton;
@property(nonatomic, retain) UIBarButtonItem* forwardButton;
@property(nonatomic, retain) UIBarButtonItem* homeButton;
@property(nonatomic, retain) NSString* titleString;
@property(nonatomic, retain) NSURL* homeUrl;
@end


@implementation WebBrowserViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a WebBrowserViewController instance
/// that displays @a title in its navigation item and navigates to the initial
/// URL @a homeUrl in its web view.
// -----------------------------------------------------------------------------
+ (WebBrowserViewController*) controllerWithTitle:(NSString*)title homeUrl:(NSURL*)homeUrl;
{
  WebBrowserViewController* controller = [[WebBrowserViewController alloc] initWithNibName:nil bundle:nil];
  if (controller)
  {
    [controller autorelease];
    controller.titleString = title;
    controller.homeUrl = homeUrl;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this WebBrowserViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.webView = nil;
  self.backButton = nil;
  self.forwardButton = nil;
  self.homeButton = nil;
  self.titleString = nil;
  self.homeUrl = nil;

  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.webView = [[[WKWebView alloc] initWithFrame:CGRectZero] autorelease];
  self.view = self.webView;

  self.backButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.backward"]
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(goBack:)] autorelease];
  self.forwardButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.forward"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(goForward:)] autorelease];
  self.homeButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"house"]
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(goHome:)] autorelease];
  self.navigationItem.leftBarButtonItems = @[self.backButton, self.forwardButton, self.homeButton];

  // KVO observing
  [self.webView addObserver:self forKeyPath:@"canGoBack" options:0 context:NULL];
  [self.webView addObserver:self forKeyPath:@"canGoForward" options:0 context:NULL];

  self.webView.navigationDelegate = self;
  self.webView.allowsBackForwardNavigationGestures = YES;

  self.backButton.enabled = self.webView.canGoBack;
  self.forwardButton.enabled = self.webView.canGoForward;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  if (self.homeUrl.isFileURL)
  {
    NSString* parentFolder = [self.homeUrl.absoluteString stringByDeletingLastPathComponent];
    NSURL* readAccessUrl = [NSURL fileURLWithPath:parentFolder];
    [self.webView loadFileURL:self.homeUrl allowingReadAccessToURL:readAccessUrl];
  }
  else
  {
    NSURLRequest* request = [NSURLRequest requestWithURL:self.homeUrl];
    [self.webView loadRequest:request];
  }
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];

  // In iOS 5, the system purges the view and self.isViewLoaded becomes false
  // before didReceiveMemoryWarning() is invoked. In iOS 6 the system does not
  // purge the view and self.isViewLoaded is still true when we get here. The
  // view's window property then becomes important: It is nil if the main tab
  // bar controller displays a different tab than the one where the view is
  // visible.
  if (self.isViewLoaded && ! self.view.window)
  {
    self.webView = nil;
    self.view = nil;
  }
}

#pragma mark - WKNavigationDelegate overrides

// -----------------------------------------------------------------------------
/// @brief WKNavigationDelegate method.
///
/// Makes sure that external links embedded in the HTML resource are opened in
/// Safari (or whatever browser is configured to handle such URL requests).
// -----------------------------------------------------------------------------
- (void) webView:(WKWebView*)webView decidePolicyForNavigationAction:(WKNavigationAction*)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
  if (navigationAction.navigationType == WKNavigationTypeLinkActivated)
  {
    [[UIApplication sharedApplication] openURL:[navigationAction.request URL]
                                       options:@{}
                             completionHandler:nil];
    decisionHandler(WKNavigationActionPolicyAllow);
  }
  else if (webView.isLoading)
  {
    decisionHandler(WKNavigationActionPolicyAllow);
  }
  else
  {
    // Allow JavaScript navigation to the home URL
    if ([navigationAction.request.URL isEqual:self.homeUrl])
      decisionHandler(WKNavigationActionPolicyAllow);
    else
      decisionHandler(WKNavigationActionPolicyCancel);
  }
}

#pragma mark - Web browser control interaction

// -----------------------------------------------------------------------------
/// @brief Reacts to the user tapping the "go back" button.
// -----------------------------------------------------------------------------
- (void) goBack:(id)sender
{
  [self.webView goBack];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user tapping the "go forward" button.
// -----------------------------------------------------------------------------
- (void) goForward:(id)sender
{
  [self.webView goForward];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user tapping the "home" button.
// -----------------------------------------------------------------------------
- (void) goHome:(id)sender
{
  // Can't use any of WKWebView's load... methods because these cause WKWebView
  // to forget about the browsing history. To support navigating via JavaScript
  // the navigation action needs to be allowed by the WKNavigationDelegate
  // handler.
  NSString* script = [NSString stringWithFormat:@"window.location.href = '%@';", [self.homeUrl absoluteString]];
  [self.webView evaluateJavaScript:script completionHandler:nil];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"canGoBack"])
  {
    UIBarButtonItem* button = self.navigationItem.leftBarButtonItems[0];
    button.enabled = self.webView.canGoBack;
  }
  else if ([keyPath isEqualToString:@"canGoForward"])
  {
    UIBarButtonItem* button = self.navigationItem.leftBarButtonItems[1];
    button.enabled = self.webView.canGoForward;
  }
}

@end
