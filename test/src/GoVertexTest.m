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


// Test includes
#import "GoVertexTest.h"

// Application includes
#import <go/GoVertex.h>


@implementation GoVertexTest

// -----------------------------------------------------------------------------
/// @brief Exercises the vertexFromNumeric:() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testVertexFromNumeric
{
  struct GoVertexNumeric inputVertex;
  inputVertex.x = 3;
  inputVertex.y = 17;
  NSString* expectedLetterResult = @"C";
  NSString* expectedNumberResult = @"17";
  NSString* expectedStringResult = [expectedLetterResult stringByAppendingString:expectedNumberResult];
  struct GoVertexNumeric expectedNumericResult = inputVertex;

  GoVertex* vertex = [GoVertex vertexFromNumeric:inputVertex];
  STAssertNotNil(vertex, nil);
  STAssertTrue([vertex.string isEqualToString:expectedStringResult], nil);
  STAssertTrue([vertex.letterAxisCompound isEqualToString:expectedLetterResult], nil);
  STAssertTrue([vertex.numberAxisCompound isEqualToString:expectedNumberResult], nil);
  STAssertEquals(vertex.numeric, expectedNumericResult, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the vertexFromString:() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testVertexFromString
{
  NSString* inputLetterAxisCompound = @"F";
  NSString* inputNumberAxisCompound = @"12";
  NSString* inputVertex = [inputLetterAxisCompound stringByAppendingString:inputNumberAxisCompound];
  NSString* expectedLetterResult = [inputLetterAxisCompound copy];
  NSString* expectedNumberResult = [inputNumberAxisCompound copy];
  NSString* expectedStringResult = [inputVertex copy];
  struct GoVertexNumeric expectedNumericResult;
  expectedNumericResult.x = 6;
  expectedNumericResult.y = 12;

  GoVertex* vertex = [GoVertex vertexFromString:inputVertex];
  STAssertNotNil(vertex, nil);
  STAssertTrue([vertex.string isEqualToString:expectedStringResult], nil);
  STAssertTrue([vertex.letterAxisCompound isEqualToString:expectedLetterResult], nil);
  STAssertTrue([vertex.numberAxisCompound isEqualToString:expectedNumberResult], nil);
  STAssertEquals(vertex.numeric, expectedNumericResult, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isEqualToVertex:() method.
// -----------------------------------------------------------------------------
- (void) testIsEqualToVertex
{
  NSString* inputStringVertex = @"H7";
  struct GoVertexNumeric inputNumericVertex;
  inputNumericVertex.x = 8;
  inputNumericVertex.y = 7;

  GoVertex* vertex1 = [GoVertex vertexFromString:inputStringVertex];
  GoVertex* vertex2 = [GoVertex vertexFromNumeric:inputNumericVertex];
  STAssertNotNil(vertex1, nil);
  STAssertNotNil(vertex2, nil);
  STAssertTrue([vertex1 isEqualToVertex:vertex2], @"test 1");
  STAssertTrue([vertex2 isEqualToVertex:vertex1], @"test 2");
  STAssertTrue([vertex1 isEqualToVertex:vertex1], @"test 3");
  STAssertTrue([vertex2 isEqualToVertex:vertex2], @"test 4");
}

// -----------------------------------------------------------------------------
/// @brief Tests behaviour related to the unused letter "I".
// -----------------------------------------------------------------------------
- (void) testUnusedLetterI
{
  struct GoVertexNumeric inputNumericVertex1;
  inputNumericVertex1.x = 8;
  inputNumericVertex1.y = 8;
  NSString* inputStringVertex1 = @"H8";
  struct GoVertexNumeric inputNumericVertex2;
  inputNumericVertex2.x = 9;
  inputNumericVertex2.y = 9;
  NSString* inputStringVertex2 = @"J9";
  NSString* expectedStringResult1 = [inputStringVertex1 copy];
  struct GoVertexNumeric expectedNumericResult1 = inputNumericVertex1;
  NSString* expectedStringResult2 = [inputStringVertex2 copy];
  struct GoVertexNumeric expectedNumericResult2 = inputNumericVertex2;

  GoVertex* vertexFromNumeric1 = [GoVertex vertexFromNumeric:inputNumericVertex1];
  GoVertex* vertexFromString1 = [GoVertex vertexFromString:inputStringVertex1];
  GoVertex* vertexFromNumeric2 = [GoVertex vertexFromNumeric:inputNumericVertex2];
  GoVertex* vertexFromString2 = [GoVertex vertexFromString:inputStringVertex2];
  STAssertNotNil(vertexFromNumeric1, nil);
  STAssertNotNil(vertexFromString1, nil);
  STAssertNotNil(vertexFromNumeric2, nil);
  STAssertNotNil(vertexFromString2, nil);
  STAssertTrue([vertexFromNumeric1.string isEqualToString:expectedStringResult1], @"test 1");
  STAssertEquals(vertexFromNumeric1.numeric, expectedNumericResult1, @"test 2");
  STAssertTrue([vertexFromString1.string isEqualToString:expectedStringResult1], @"test 3");
  STAssertEquals(vertexFromString1.numeric, expectedNumericResult1, @"test 4");
  STAssertTrue([vertexFromNumeric2.string isEqualToString:expectedStringResult2], @"test 5");
  STAssertEquals(vertexFromNumeric2.numeric, expectedNumericResult2, @"test 6");
  STAssertTrue([vertexFromString2.string isEqualToString:expectedStringResult2], @"test 7");
  STAssertEquals(vertexFromString2.numeric, expectedNumericResult2, @"test 8");
  STAssertTrue([vertexFromNumeric1 isEqualToVertex:vertexFromString1], @"test 9");
  STAssertTrue([vertexFromNumeric2 isEqualToVertex:vertexFromString2], @"test 10");
}

// -----------------------------------------------------------------------------
/// @brief Tests behaviour when a lower-case letter is passed to
/// vertexFromString:()
// -----------------------------------------------------------------------------
- (void) testLowerCaseString
{
  NSString* inputVertex = @"q5";
  NSString* expectedStringResult = [inputVertex uppercaseString];
  struct GoVertexNumeric expectedNumericResult;
  expectedNumericResult.x = 16;
  expectedNumericResult.y = 5;

  GoVertex* vertex = [GoVertex vertexFromString:inputVertex];
  STAssertNotNil(vertex, nil);
  STAssertTrue([vertex.string isEqualToString:expectedStringResult], nil);
  STAssertEquals(vertex.numeric, expectedNumericResult, nil);
}

// -----------------------------------------------------------------------------
/// @brief Tests border cases for convenience constructors' input values.
// -----------------------------------------------------------------------------
- (void) testBorderCases
{
  struct GoVertexNumeric inputVertex1;
  inputVertex1.x = 1;
  inputVertex1.y = 1;
  struct GoVertexNumeric inputVertex2;
  inputVertex2.x = 19;
  inputVertex2.y = 19;
  NSString* expectedStringResult1 = @"A1";
  NSString* expectedStringResult2 = @"T19";

  GoVertex* vertex1 = [GoVertex vertexFromNumeric:inputVertex1];
  GoVertex* vertex2 = [GoVertex vertexFromNumeric:inputVertex2];
  STAssertNotNil(vertex1, nil);
  STAssertNotNil(vertex2, nil);
  STAssertTrue([vertex1.string isEqualToString:expectedStringResult1], @"test 1");
  STAssertTrue([vertex2.string isEqualToString:expectedStringResult2], @"test 2");
}

// -----------------------------------------------------------------------------
/// @brief Tests behaviour when illegal input values are specified to
/// convenience constructors.
// -----------------------------------------------------------------------------
- (void) testIllegalInputValues
{
  struct GoVertexNumeric inputVertex1;
  inputVertex1.x = -1;
  inputVertex1.y = 1;
  struct GoVertexNumeric inputVertex2;
  inputVertex2.x = 0;
  inputVertex2.y = 1;
  struct GoVertexNumeric inputVertex3;
  inputVertex3.x = 1;
  inputVertex3.y = -1;
  struct GoVertexNumeric inputVertex4;
  inputVertex4.x = 1;
  inputVertex4.y = 0;
  struct GoVertexNumeric inputVertex5;
  inputVertex5.x = 20;
  inputVertex5.y = 1;
  struct GoVertexNumeric inputVertex6;
  inputVertex6.x = 1;
  inputVertex6.y = 20;
  NSString* inputVertex7 = @"A-1";
  NSString* inputVertex8 = @"A0";
  NSString* inputVertex9 = @"A20";
  NSString* inputVertex10 = @"AB";
  NSString* inputVertex11 = @"AΩ";  // something weird that is not ASCII
  NSString* inputVertex12 = @"1A";
  NSString* inputVertex13 = @"ΩA";  // something weird that is not ASCII
  NSString* inputVertex14 = @"I1";  // use letter "I"
  NSString* inputVertex15 = @"";
  NSString* inputVertex16 = nil;
  NSString* inputVertex17 = @"foobar";

  STAssertThrowsSpecificNamed([GoVertex vertexFromNumeric:inputVertex1],
                              NSException, NSRangeException, @"test 1");
  STAssertThrowsSpecificNamed([GoVertex vertexFromNumeric:inputVertex2],
                              NSException, NSRangeException, @"test 2");
  STAssertThrowsSpecificNamed([GoVertex vertexFromNumeric:inputVertex3],
                              NSException, NSRangeException, @"test 3");
  STAssertThrowsSpecificNamed([GoVertex vertexFromNumeric:inputVertex4],
                              NSException, NSRangeException, @"test 4");
  STAssertThrowsSpecificNamed([GoVertex vertexFromNumeric:inputVertex5],
                              NSException, NSRangeException, @"test 5");
  STAssertThrowsSpecificNamed([GoVertex vertexFromNumeric:inputVertex6],
                              NSException, NSRangeException, @"test 6");
  STAssertThrowsSpecificNamed([GoVertex vertexFromString:inputVertex7],
                              NSException, NSRangeException, @"test 7");
  STAssertThrowsSpecificNamed([GoVertex vertexFromString:inputVertex8],
                              NSException, NSRangeException, @"test 8");
  STAssertThrowsSpecificNamed([GoVertex vertexFromString:inputVertex9],
                              NSException, NSRangeException, @"test 9");
  STAssertThrowsSpecificNamed([GoVertex vertexFromString:inputVertex10],
                              NSException, NSRangeException, @"test 10");
  STAssertThrowsSpecificNamed([GoVertex vertexFromString:inputVertex11],
                              NSException, NSRangeException, @"test 11");
  STAssertThrowsSpecificNamed([GoVertex vertexFromString:inputVertex12],
                              NSException, NSRangeException, @"test 12");
  STAssertThrowsSpecificNamed([GoVertex vertexFromString:inputVertex13],
                              NSException, NSRangeException, @"test 13");
  STAssertThrowsSpecificNamed([GoVertex vertexFromString:inputVertex14],
                              NSException, NSRangeException, @"test 14");
  STAssertThrowsSpecificNamed([GoVertex vertexFromString:inputVertex15],
                              NSException, NSInvalidArgumentException, @"test 15");
  STAssertThrowsSpecificNamed([GoVertex vertexFromString:inputVertex16],
                              NSException, NSInvalidArgumentException, @"test 16");
  STAssertThrowsSpecificNamed([GoVertex vertexFromString:inputVertex17],
                              NSException, NSInvalidArgumentException, @"test 17");
}

@end
