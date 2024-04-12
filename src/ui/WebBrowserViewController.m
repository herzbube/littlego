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
@property(nonatomic, retain) NSMutableArray* goToUrls;
@end


@implementation WebBrowserViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an WebBrowserViewController object that navigates to the
/// initial URL @a homeUrl in its web view.
///
/// @note This is the designated initializer of WebBrowserViewController.
// -----------------------------------------------------------------------------
- (id) initWithHomeUrl:(NSURL*)homeUrl
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.homeUrl = homeUrl;
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
  self.webView = nil;
  self.goToUrls = [NSMutableArray array];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this WebBrowserViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.homeUrl = nil;
  self.backButton = nil;
  self.forwardButton = nil;
  self.homeButton = nil;
  self.webView = nil;
  self.goToUrls = nil;

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

  self.navigationItem.rightBarButtonItems = @[self.homeButton, self.forwardButton, self.backButton];

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
// -----------------------------------------------------------------------------
- (void) webView:(WKWebView*)webView decidePolicyForNavigationAction:(WKNavigationAction*)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
  if (navigationAction.navigationType == WKNavigationTypeLinkActivated)
  {
    NSURL* requestUrl = navigationAction.request.URL;
    if (requestUrl.isFileURL)
    {
      if (requestUrl.hasDirectoryPath)
      {
        // When a directory URL is requested from a web server it usually
        // does *NOT* respond with the listing of the directory content, but
        // instead delivers the content of index.html or some similar file.
        // When accessing file URLs there is no web server involved, therefore
        // we simulate here the behaviour of a web server.
        decisionHandler(WKNavigationActionPolicyCancel);
        NSURL* redirectRequestUrl = [requestUrl URLByAppendingPathComponent:@"index.html"];
        [self goTo:redirectRequestUrl];
      }
      else
      {
        decisionHandler(WKNavigationActionPolicyAllow);
      }
    }
    else
    {
      if (self.homeUrl.isFileURL)
      {
        // If we are browsing a serverless site (which is the case if the home
        // URL is a file URL) then we assume that non-file URLs point to
        // external resources that should be opened in Safari (or whatever
        // browser is configured to handle such URL requests).
        decisionHandler(WKNavigationActionPolicyCancel);
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL
                                           options:@{}
                                 completionHandler:nil];
      }
      else
      {
        decisionHandler(WKNavigationActionPolicyAllow);
      }
    }
  }
  else if (webView.isLoading)
  {
    decisionHandler(WKNavigationActionPolicyAllow);
  }
  else
  {
    // If the URL is in the whitelist then we allow it, assuming that the
    // request was caused by the goTo:() method's JavaScript navigation.
    if ([self.goToUrls containsObject:navigationAction.request.URL])
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
  [self goTo:self.homeUrl];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"canGoBack"])
  {
    self.backButton.enabled = self.webView.canGoBack;
  }
  else if ([keyPath isEqualToString:@"canGoForward"])
  {
    self.forwardButton.enabled = self.webView.canGoForward;
  }
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Navigates the web view to the address encapsulated by @a url.
///
/// The implementation of this method uses JavaScript navigation. It can't use
/// any of WKWebView's load... methods because these cause WKWebView to forget
/// about the browsing history.
// -----------------------------------------------------------------------------
- (void) goTo:(NSURL*)url
{
  // To support navigating via JavaScript the navigation action needs to be
  // allowed by the WKNavigationDelegate handler. Because of this we need to
  // add the URL to a whitelist.
  if (! [self.goToUrls containsObject:url])
  {
    [self.goToUrls addObject:url];
  }

  NSString* script = [NSString stringWithFormat:@"window.location.href = '%@';", [url absoluteString]];
  [self.webView evaluateJavaScript:script completionHandler:nil];
}

@end
