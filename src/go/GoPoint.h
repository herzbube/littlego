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


// Forward declarations
@class GoMove;


@interface GoPoint : NSObject
{
}

+ (GoPoint*) pointFromVertex:(NSString*)vertex;

@property int numVertexX;
@property int numVertexY;
@property(retain) NSString* vertexX;
@property(retain) NSString* vertexY;
@property(readonly) NSString* vertex;
// TODO: Check if this back-reference is really necessary or could be solved
// differently.
@property(assign) GoMove* move;  // do not retain, otherwise there would be a retain cycle

@end
