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


// -----------------------------------------------------------------------------
/// @brief Helper struct to bind the numeric compounds of a GoVertex together.
///
/// @ingroup go
// -----------------------------------------------------------------------------
struct GoVertexNumeric
{
  int x;   ///< @brief Horizontal axis compound of the vertex.
  int y;   ///< @brief Vertical axis compound of the vertex.
};

// Helper functions
extern bool GoVertexNumericEqualToVertex(struct GoVertexNumeric vertex1, struct GoVertexNumeric vertex2);
