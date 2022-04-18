// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The AnnotationViewController class manages the annotation view, i.e.
/// the view that displays node and move annotations associated with the current
/// board position.
///
/// The view hierarchy of the annotation view is laid out differently depending
/// on the UI type that is effective at runtime. Use the class method
/// annotationViewController() to obtain a UI type-dependent controller object
/// that knows how to set up the correct view hierarchy for the current UI type.
///
/// @see LayoutManager
// -----------------------------------------------------------------------------
@interface AnnotationViewController : UIViewController
{
}

+ (AnnotationViewController*) annotationViewController;

@end
