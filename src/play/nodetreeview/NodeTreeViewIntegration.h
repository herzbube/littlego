// -----------------------------------------------------------------------------
// Copyright 2023 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../ui/ResizableStackViewController.h"

// Forward declarations
@class NodeTreeViewModel;
@class UiSettingsModel;


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewIntegration class is responsible for handling the
/// integration of the node tree view into the view hierarchy of #UIAreaPlay.
/// NodeTreeViewIntegration performs similar functions as a view controller, but
/// is not derived from UIViewController.
///
/// The view hierarchy of #UIAreaPlay is laid out differently depending on
/// the UI type as well as the user interface orientation that is effective at
/// runtime. However, the integration of the node tree view always works the
/// same, so different controllers can delegate the integration work to
/// NodeTreeViewIntegration.
///
/// NodeTreeViewIntegration assumes that it should integrate the node tree view
/// by adding it as a resizable pane to a ResizableStackViewController that
/// otherwise shows only one resizable pane. The owner of
/// NodeTreeViewIntegration must specify the ResizableStackViewController object
/// during initialization.
///
/// NodeTreeViewIntegration also manages the size distribution of resizable
/// panes in the ResizableStackViewController that was specified during
/// initialization. When it integrates the node tree view,
/// NodeTreeViewIntegration reads the size distribution from the UiSettingsModel
/// object that was specified during initialization and applies that size
/// distribution to the ResizableStackViewController. While the node tree view
/// is integrated, NodeTreeViewIntegration reacts to interactive changes of the
/// size distribution and updates the size distribution value in
/// UiSettingsModel.
///
/// NodeTreeViewIntegration decides whether or not to integrate the node tree
/// view based on the user preference "display node tree view".
/// NodeTreeViewIntegration reads the user preference value from the
/// NodeTreeViewModel object that was specified during initialization. The owner
/// of NodeTreeViewIntegration must trigger the initial integration at the
/// appropriate time (e.g. in the UIViewController method loadView()) by
/// invoking performIntegration(). Later on NodeTreeViewIntegration reacts on
/// its own to changes of the user preference via KVO observing.
// -----------------------------------------------------------------------------
@interface NodeTreeViewIntegration : NSObject <ResizableStackViewControllerDelegate>
{
}

- (id) initWithResizableStackViewController:(ResizableStackViewController*)resizableStackViewController
                          nodeTreeViewModel:(NodeTreeViewModel*)nodeTreeViewModel
                            uiSettingsModel:(UiSettingsModel*)uiSettingsModel;

- (void) performIntegration;
- (void) updateColors;

@end
