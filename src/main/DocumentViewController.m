// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "DocumentViewController.h"
#import "ApplicationDelegate.h"
#import "MainTabBarController.h"
#import "../utility/VersionInfoUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for DocumentViewController.
// -----------------------------------------------------------------------------
@interface DocumentViewController()
@property(nonatomic, retain) UIWebView* webView;
@property(nonatomic, retain) NSString* titleString;
@property(nonatomic, retain) NSString* htmlString;
@property(nonatomic, retain) NSString* resourceName;
@end


@implementation DocumentViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a DocumentViewController instance
/// that displays @a title in its navigation item and @a htmlString in its web
/// view.
// -----------------------------------------------------------------------------
+ (DocumentViewController*) controllerWithTitle:(NSString*)title htmlString:(NSString*)htmlString
{
  DocumentViewController* controller = [[DocumentViewController alloc] initWithNibName:@"DocumentView" bundle:nil];
  if (controller)
  {
    [controller autorelease];
    controller.titleString = title;
    controller.htmlString = htmlString;
    controller.resourceName = nil;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a DocumentViewController instance
/// that displays @a title in its navigation item and the content of the
/// resource named @a resourceName in its web view.
// -----------------------------------------------------------------------------
+ (DocumentViewController*) controllerWithTitle:(NSString*)title resourceName:(NSString*)resourceName
{
  DocumentViewController* controller = [[DocumentViewController alloc] initWithNibName:@"DocumentView" bundle:nil];
  if (controller)
  {
    [controller autorelease];
    controller.titleString = title;
    controller.htmlString = nil;
    controller.resourceName = resourceName;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DocumentViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.webView = nil;
  self.titleString = nil;
  self.htmlString = nil;
  self.resourceName = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.webView = [[[UIWebView alloc] init] autorelease];
  self.view = self.webView;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.webView.delegate = self;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (self.titleString)
  {
    self.title = self.titleString;
    if (self.htmlString)
      [self.webView loadHTMLString:self.htmlString baseURL:nil];
    else
    {
      NSString* resourceContent = [appDelegate contentOfTextResource:self.resourceName];
      [self.webView loadHTMLString:resourceContent baseURL:nil];
    }
  }
  else
  {
    // Cast is required because NSInteger and int (the underlying type for
    // enums) differ in size in 64-bit. Cast is safe because the tab bar items
    // are designed to match the enumeration.
    enum TabType tabType = (enum TabType)self.contextTabBarItem.tag;
    NSString* resourceNameForTabType = [appDelegate.tabBarController resourceNameForTabType:tabType];
    NSString* resourceContent = [appDelegate contentOfTextResource:resourceNameForTabType];
    switch (tabType)
    {
      case TabTypeAbout:
        [self showAboutDocument:resourceContent];
        break;
      default:
        [self.webView loadHTMLString:resourceContent baseURL:nil];
        break;
    }
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

#pragma mark - UIWebViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UIWebViewDelegate method.
///
/// Makes sure that external links embedded in the HTML resource are opened in
/// Safari (or whatever browser is configured to handle such URL requests).
// -----------------------------------------------------------------------------
- (BOOL) webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
  if (navigationType == UIWebViewNavigationTypeLinkClicked)
  {
    [[UIApplication sharedApplication] openURL:[request URL]];
    return NO;
  }
  return YES;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Replaces a number of tokens known to be present in @a documentContent
/// before actually displaying the content in the associated UIWebView.
// -----------------------------------------------------------------------------
- (void) showAboutDocument:(NSString*)documentContent
{
  documentContent = [documentContent stringByReplacingOccurrencesOfString:@"%applicationName%"
                                                               withString:[VersionInfoUtilities applicationName]];
  documentContent = [documentContent stringByReplacingOccurrencesOfString:@"%applicationVersion%"
                                                               withString:[VersionInfoUtilities applicationVersion]];
  documentContent = [documentContent stringByReplacingOccurrencesOfString:@"%applicationCopyright%"
                                                               withString:[VersionInfoUtilities applicationCopyright]];
  documentContent = [documentContent stringByReplacingOccurrencesOfString:@"%buildDate%"
                                                               withString:[VersionInfoUtilities buildDateTimeString]];
  [self.webView loadHTMLString:documentContent baseURL:nil];
}

@end
