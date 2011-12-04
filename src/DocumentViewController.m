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
#import "DocumentViewController.h"
#import "ApplicationDelegate.h"
#import "utility/DocumentGenerator.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for DocumentViewController.
// -----------------------------------------------------------------------------
@interface DocumentViewController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
//@}
/// @name UIWebViewDelegate protocol
//@{
- (BOOL) webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType;
//@}
/// @name Private helper methods
//@{
- (void) showAboutDocument:(NSString*)documentContent;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) NSString* titleString;
@property(nonatomic, retain) NSString* htmlString;
@property(nonatomic, retain) NSString* resourceName;
//@}
@end


@implementation DocumentViewController

@synthesize webView;
@synthesize titleString;
@synthesize htmlString;
@synthesize resourceName;


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

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
///
/// This implementation triggers loading of the HTML content into the UIWebView
/// associated with this controller.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.webView.delegate = self;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (self.titleString)
  {
    self.title = titleString;
    if (self.htmlString)
      [self.webView loadHTMLString:htmlString baseURL:nil];
    else
    {
      NSString* resourceContent = [appDelegate contentOfTextResource:self.resourceName];
      [self.webView loadHTMLString:resourceContent baseURL:nil];
    }
  }
  else
  {
    NSInteger tabType = self.tabBarItem.tag;
    NSString* resourceNameForTabType = [appDelegate resourceNameForTabType:tabType];
    NSString* resourceContent = [appDelegate contentOfTextResource:resourceNameForTabType];
    switch (tabType)
    {
      case AboutTab:
        [self showAboutDocument:resourceContent];
        break;
      default:
        [self.webView loadHTMLString:resourceContent baseURL:nil];
        break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Called when the controller’s view is released from memory, e.g.
/// during low-memory conditions.
///
/// Releases additional objects (e.g. by resetting references to retained
/// objects) that can be easily recreated when viewDidLoad() is invoked again
/// later.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];
  self.webView = nil;
}

// -----------------------------------------------------------------------------
/// @brief UIWebViewDelegate method. Makes sure that external links embedded
/// in the HTML resource are opened in Safari (or whatever browser is configured
/// to handle such URL requests).
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

// -----------------------------------------------------------------------------
/// @brief Replaces a number of tokens known to be present in @a documentContent
/// before actually displaying the content in the associated UIWebView.
// -----------------------------------------------------------------------------
- (void) showAboutDocument:(NSString*)documentContent
{
  NSString* bundleName = [[ApplicationDelegate sharedDelegate].resourceBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
  NSString* bundleVersion = [[ApplicationDelegate sharedDelegate].resourceBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  NSString* copyright = [[ApplicationDelegate sharedDelegate].resourceBundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"];
  documentContent = [documentContent stringByReplacingOccurrencesOfString:@"%bundleName%"
                                                               withString:bundleName];
  documentContent = [documentContent stringByReplacingOccurrencesOfString:@"%bundleVersion%"
                                                               withString:bundleVersion];
  documentContent = [documentContent stringByReplacingOccurrencesOfString:@"%copyright%"
                                                               withString:copyright];
  [self.webView loadHTMLString:documentContent baseURL:nil];
}

@end
