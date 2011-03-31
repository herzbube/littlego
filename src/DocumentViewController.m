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


#import "DocumentViewController.h"


// Class extension
@interface DocumentViewController()
- (void) showAboutDocument:(NSString*)documentContent;
- (NSString*) getResourceContent:(NSString*)resourceName;
- (NSString*) resourceNameForTabType:(int)tabType;
@end

@implementation DocumentViewController

@synthesize webView;

- (void) dealloc
{
  self.webView = nil;
  [super dealloc];
}

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

- (void) viewDidUnload
{
  [super viewDidUnload];

  self.webView = nil;
}

- (BOOL) webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
  if (navigationType == UIWebViewNavigationTypeLinkClicked)
  {
    [[UIApplication sharedApplication] openURL:[request URL]];
    return NO;
  }
  return YES;
}

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

- (NSString*) resourceNameForTabType:(int)tabType
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
