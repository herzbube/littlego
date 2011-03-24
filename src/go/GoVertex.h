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


// Helper to bind numeric compounds together
struct GoVertexNumeric
{
  int x;
  int y;
};

// immutable object
//
// vertexes are given as strings such as "C13"; "A1" is in the lower-left
// corner; the letter axis is horizontal, the number axis is vertical; the
// letter "I" is not used; a numeric vertex is a conversion of the compounds
// of a string vertex into numeric values, the number axis conversion is 1:1,
// letters are converted so that A=1, B=2, etc. The gap caused by the unused
// letter "I" is closed, i.e. H=8, J=9
@interface GoVertex : NSObject
{
}

+ (GoVertex*) vertexFromNumeric:(struct GoVertexNumeric)numericValue;
+ (GoVertex*) vertexFromString:(NSString*)stringValue;
- (bool) isEqualToVertex:(GoVertex*)vertex;

@property(readonly, retain) NSString* string;
@property(readonly) struct GoVertexNumeric numeric;

@end
