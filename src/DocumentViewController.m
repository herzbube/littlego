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
- (NSString*) getResourceContent:(NSString*)resourceName;
- (NSString*) resourceNameForTabType:(enum TabType)tabType;
//@}
@end


@implementation DocumentViewController

@synthesize webView;

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DocumentViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.webView = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
///
/// This implementation triggers loading of the content of the HTML resource
/// file into the UIWebView associatd with this controller.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.webView.delegate = self;

  NSInteger tabType = self.tabBarItem.tag;
  NSString* resourceName = [self resourceNameForTabType:tabType];
  NSString* resourceContent = [self getResourceContent:resourceName];
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
  NSString* bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
  NSString* bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
  NSString* copyright = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSHumanReadableCopyright"];
  documentContent = [documentContent stringByReplacingOccurrencesOfString:@"%bundleName%"
                                                               withString:bundleName];
  documentContent = [documentContent stringByReplacingOccurrencesOfString:@"%bundleVersion%"
                                                               withString:bundleVersion];
  documentContent = [documentContent stringByReplacingOccurrencesOfString:@"%copyright%"
                                                               withString:copyright];
  [self.webView loadHTMLString:documentContent baseURL:nil];
}

// -----------------------------------------------------------------------------
/// @brief Loads the content of the resource named @a resourceName.
// -----------------------------------------------------------------------------
- (NSString*) getResourceContent:(NSString*)resourceName
{
  if (! resourceName)
    return @"";
  NSURL* resourceURL = [[NSBundle mainBundle] URLForResource:resourceName
                                               withExtension:nil];
  NSStringEncoding usedEncoding;
  NSError* error;
  return [NSString stringWithContentsOfURL:resourceURL
                              usedEncoding:&usedEncoding
                                     error:&error];
}

// -----------------------------------------------------------------------------
/// @brief Maps TabType values to resource file names. The name that is returned
/// can be used with NSBundle to load the resource file's content.
// -----------------------------------------------------------------------------
- (NSString*) resourceNameForTabType:(enum TabType)tabType
{
  NSString* resourceName = nil;
  switch (tabType)
  {
    case AboutTab:
      resourceName = aboutDocumentResource;
      break;
    case SourceCodeTab:
      resourceName = sourceCodeDocumentResource;
      break;
    case ApacheLicenseTab:
      resourceName = apacheLicenseDocumentResource;
      break;
    case GPLTab:
      resourceName = GPLDocumentResource;
      break;
    case LGPLTab:
      resourceName = LGPLDocumentResource;
      break;
    case BoostLicenseTab:
      resourceName = boostLicenseDocumentResource;
      break;
    default:
      break;
  }
  return resourceName;
}
  
@end
