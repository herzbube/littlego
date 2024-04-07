// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The DocumentViewController class is responsible for displaying an
/// HTML document in its view (a WKWebView object).
///
/// The GUI has a number of web views that display different documents such as
/// the "About" information document. If DocumentViewController is not
/// instantiated via one of its convenience constructors, it recognizes which
/// document it is supposed to load by examining the @e uiArea property that
/// is expected to exist via category addition.
///
/// If DocumentViewController is instantiated via one of its convenience
/// constructors, it obtains the HTML content to display from the source
/// specified to the convenience constructor.
///
/// @todo Research how much memory this controller and its associated view are
/// using. If possible, try to reduce the memory requirements (e.g. only create
/// one instance of the controller/view pair instead of one instance per
/// document).
// -----------------------------------------------------------------------------
@interface DocumentViewController : UIViewController<WKNavigationDelegate>
{
}

+ (DocumentViewController*) controllerWithTitle:(NSString*)title htmlString:(NSString*)htmlString;
+ (DocumentViewController*) controllerWithTitle:(NSString*)title resourceName:(NSString*)resourceName;

@end
