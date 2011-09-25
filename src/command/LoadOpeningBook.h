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
#import "CommandBase.h"


// -----------------------------------------------------------------------------
/// @brief The LoadOpeningBook class is responsible for submitting a "book_load"
/// command to the GTP engine.
///
/// The opening book file used as the command argument is a project resource
/// with hard-coded name, i.e. there is no support for variable opening books.
///
/// @note If variable opening books are implemented, make sure to thoroughly
/// test file names that are not "book.dat", and files that do not contain
/// opening book data. Preliminary tests suggest that esp. the latter case may
/// not be handled properly by Fuego.
// -----------------------------------------------------------------------------
@interface LoadOpeningBook : CommandBase
{
}

@end
