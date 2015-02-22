// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The WindowRootViewController class is the application window's root
/// view controller. It is responsible for selecting one of several alternative
/// main application view controllers and displaying it.
/// WindowRootViewController has no visible screen elements of its own.
///
/// The application supports different UI layouts on different devices and in
/// different interface orientations. WindowRootViewController decides which
/// layout is appropriate for the current device and interface orientation,
/// then selects one from the several available main application view
/// controllers and installs its view as the main view of the application.
/// It then becomes the main application view controller's responsibility to let
/// the user navigate to the different main areas of the application.
///
/// WindowRootViewController is also responsible for defining which interface
/// orientations are supported on the device, and for handling changes to the
/// interface orientation. If such a change occurs, WindowRootViewController may
/// react by installing a different main application view controller.
// -----------------------------------------------------------------------------
@interface WindowRootViewController : UIViewController
{
}

@end
