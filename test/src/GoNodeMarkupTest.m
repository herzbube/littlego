// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoNodeMarkupTest.h"

// Application includes
#import <go/GoNodeMarkup.h>


@implementation GoNodeMarkupTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of the GoNodeMarkup object after a new
/// instance has been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];

  XCTAssertNil(testee.symbols);
  XCTAssertNil(testee.connections);
  XCTAssertNil(testee.labels);
  XCTAssertNil(testee.dimmings);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the hasMarkup() method.
// -----------------------------------------------------------------------------
- (void) testHasMarkup
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];

  XCTAssertFalse(testee.hasMarkup);

  [testee setSymbol:GoMarkupSymbolCircle atVertex:@"A1"];
  XCTAssertTrue(testee.hasMarkup);
  [testee removeAllSymbols];
  XCTAssertFalse(testee.hasMarkup);

  [testee setConnection:GoMarkupConnectionArrow fromVertex:@"A1" toVertex:@"A2"];
  XCTAssertTrue(testee.hasMarkup);
  [testee removeAllConnections];
  XCTAssertFalse(testee.hasMarkup);

  [testee setLabel:GoMarkupLabelLabel labelText:@"foo" atVertex:@"A1"];
  XCTAssertTrue(testee.hasMarkup);
  [testee removeAllLabels];
  XCTAssertFalse(testee.hasMarkup);

  [testee setDimmingAtVertex:@"A1"];
  XCTAssertTrue(testee.hasMarkup);
  [testee removeAllDimmings];
  XCTAssertFalse(testee.hasMarkup);
  [testee undimEverything];
  XCTAssertTrue(testee.hasMarkup);
  [testee removeAllDimmings];
  XCTAssertFalse(testee.hasMarkup);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setSymbol:atVertex:() method.
// -----------------------------------------------------------------------------
- (void) testSetSymbolAtVertex
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.symbols);

  NSDictionary* expectedSymbols;

  [testee setSymbol:GoMarkupSymbolCircle atVertex:@"A1"];
  expectedSymbols = @{ @"A1": @((int)GoMarkupSymbolCircle)};
  XCTAssertEqualObjects(testee.symbols, expectedSymbols);

  [testee setSymbol:GoMarkupSymbolSquare atVertex:@"B1"];
  expectedSymbols = @{ @"A1": @((int)GoMarkupSymbolCircle), @"B1": @((int)GoMarkupSymbolSquare)};
  XCTAssertEqualObjects(testee.symbols, expectedSymbols);

  [testee setSymbol:GoMarkupSymbolX atVertex:@"A1"];
  expectedSymbols = @{ @"A1": @((int)GoMarkupSymbolX), @"B1": @((int)GoMarkupSymbolSquare)};
  XCTAssertEqualObjects(testee.symbols, expectedSymbols);

  XCTAssertThrowsSpecificNamed([testee setSymbol:GoMarkupSymbolX atVertex:nil],
                               NSException, NSInvalidArgumentException, @"setSymbol:atVertex: with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the removeSymbolAtVertex:() method.
// -----------------------------------------------------------------------------
- (void) testRemoveSymbolAtVertex
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.symbols);

  NSDictionary* expectedSymbols;

  [testee setSymbol:GoMarkupSymbolCircle atVertex:@"A1"];
  [testee setSymbol:GoMarkupSymbolSquare atVertex:@"B1"];
  expectedSymbols = @{ @"A1": @((int)GoMarkupSymbolCircle), @"B1": @((int)GoMarkupSymbolSquare)};
  XCTAssertEqualObjects(testee.symbols, expectedSymbols);

  [testee removeSymbolAtVertex:@"C1"];
  XCTAssertEqualObjects(testee.symbols, expectedSymbols);

  [testee removeSymbolAtVertex:@"A1"];
  expectedSymbols = @{ @"B1": @((int)GoMarkupSymbolSquare)};
  XCTAssertEqualObjects(testee.symbols, expectedSymbols);

  [testee removeSymbolAtVertex:@"B1"];
  XCTAssertNil(testee.symbols);

  [testee removeSymbolAtVertex:@"C1"];
  XCTAssertNil(testee.symbols);

  XCTAssertThrowsSpecificNamed([testee removeSymbolAtVertex:nil],
                               NSException, NSInvalidArgumentException, @"removeSymbolAtVertex with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the replaceSymbols:() method.
// -----------------------------------------------------------------------------
- (void) testReplaceSymbols
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.symbols);

  NSDictionary* newSymbols;

  newSymbols = @{ @"A1": @((int)GoMarkupSymbolCircle), @"B1": @((int)GoMarkupSymbolSquare)};
  [testee replaceSymbols:newSymbols];
  XCTAssertNotIdentical(testee.symbols, newSymbols);
  XCTAssertEqualObjects(testee.symbols, newSymbols);

  newSymbols = @{ @"A1": @((int)GoMarkupSymbolCircle), @"B1": @((int)GoMarkupSymbolSquare), @"C1": @((int)GoMarkupSymbolTriangle)};
  [testee replaceSymbols:newSymbols];
  XCTAssertNotIdentical(testee.symbols, newSymbols);
  XCTAssertEqualObjects(testee.symbols, newSymbols);

  [testee replaceSymbols:newSymbols];
  XCTAssertNotIdentical(testee.symbols, newSymbols);
  XCTAssertEqualObjects(testee.symbols, newSymbols);

  [testee replaceSymbols:nil];
  XCTAssertNil(testee.symbols);

  [testee replaceSymbols:nil];
  XCTAssertNil(testee.symbols);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the removeAllSymbols() method.
// -----------------------------------------------------------------------------
- (void) testRemoveAllSymbols
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.symbols);

  NSDictionary* newSymbols;

  newSymbols = @{ @"A1": @((int)GoMarkupSymbolCircle), @"B1": @((int)GoMarkupSymbolSquare)};
  [testee replaceSymbols:newSymbols];
  XCTAssertNotIdentical(testee.symbols, newSymbols);
  XCTAssertEqualObjects(testee.symbols, newSymbols);

  [testee removeAllSymbols];
  XCTAssertNil(testee.symbols);

  [testee removeAllSymbols];
  XCTAssertNil(testee.symbols);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setConnection:fromVertex:toVertex:() method.
// -----------------------------------------------------------------------------
- (void) testSetConnectionFromVertexToVertex
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.connections);

  NSDictionary* expectedConnections;

  [testee setConnection:GoMarkupConnectionArrow fromVertex:@"A1" toVertex:@"B1"];
  expectedConnections = @{ @[@"A1", @"B1"]: @((int)GoMarkupConnectionArrow)};
  XCTAssertEqualObjects(testee.connections, expectedConnections);

  [testee setConnection:GoMarkupConnectionLine fromVertex:@"A1" toVertex:@"C1"];
  expectedConnections = @{ @[@"A1", @"B1"]: @((int)GoMarkupConnectionArrow), @[@"A1", @"C1"]: @((int)GoMarkupConnectionLine)};
  XCTAssertEqualObjects(testee.connections, expectedConnections);

  // This tests non-standard behaviour of GoNodeMarkup: According to the SGF
  // standard both a line and an arrow can be drawn between the same set of
  // intersections. GoNodeMarkup supports only one connection type, though.
  // Cf. documentation of the "connections" property in GoNodeMarkup.
  [testee setConnection:GoMarkupConnectionLine fromVertex:@"A1" toVertex:@"B1"];
  expectedConnections = @{ @[@"A1", @"B1"]: @((int)GoMarkupConnectionLine), @[@"A1", @"C1"]: @((int)GoMarkupConnectionLine)};
  XCTAssertEqualObjects(testee.connections, expectedConnections);

  // If the direction of the vertices is different then there can be two
  // connections, even of the same type, between the same set of intersections.
  // It doesn't make much sense, but it's allowd by the SGF standard and also
  // supported by GoNodeMarkup.
  [testee setConnection:GoMarkupConnectionLine fromVertex:@"B1" toVertex:@"A1"];
  expectedConnections = @{ @[@"A1", @"B1"]: @((int)GoMarkupConnectionLine), @[@"A1", @"C1"]: @((int)GoMarkupConnectionLine), @[@"B1", @"A1"]: @((int)GoMarkupConnectionLine)};
  XCTAssertEqualObjects(testee.connections, expectedConnections);

  XCTAssertThrowsSpecificNamed([testee setConnection:GoMarkupConnectionArrow fromVertex:nil toVertex:@"B1"],
                               NSException, NSInvalidArgumentException, @"setConnection:fromVertex:toVertex: with nil object for fromVertex");
  XCTAssertThrowsSpecificNamed([testee setConnection:GoMarkupConnectionArrow fromVertex:@"A1" toVertex:nil],
                               NSException, NSInvalidArgumentException, @"setConnection:fromVertex:toVertex: with nil object for toVertex");
  // The SGF standard does not allow arrows or lines that have the same start
  // and end point.
  XCTAssertThrowsSpecificNamed([testee setConnection:GoMarkupConnectionArrow fromVertex:@"A1" toVertex:@"A1"],
                               NSException, NSInvalidArgumentException, @"setConnection:fromVertex:toVertex: with same vertex for both endpoints of the connection");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the removeConnectionFromVertex:toVertex:() method.
// -----------------------------------------------------------------------------
- (void) testRemoveConnectionFromVertexToVertex
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.connections);

  NSDictionary* expectedConnections;

  [testee setConnection:GoMarkupConnectionArrow fromVertex:@"A1" toVertex:@"B1"];
  [testee setConnection:GoMarkupConnectionLine fromVertex:@"A1" toVertex:@"C1"];
  expectedConnections = @{ @[@"A1", @"B1"]: @((int)GoMarkupConnectionArrow), @[@"A1", @"C1"]: @((int)GoMarkupConnectionLine)};
  XCTAssertEqualObjects(testee.connections, expectedConnections);

  [testee removeConnectionFromVertex:@"A1" toVertex:@"D1"];
  XCTAssertEqualObjects(testee.connections, expectedConnections);

  // Unlike setConnection:fromVertex:toVertex:() there is no check for
  // same-vertex - such a connection simply cannot exist, and removing it has
  // no effect.
  [testee removeConnectionFromVertex:@"A1" toVertex:@"A1"];
  XCTAssertEqualObjects(testee.connections, expectedConnections);

  [testee removeConnectionFromVertex:@"A1" toVertex:@"B1"];
  expectedConnections = @{ @[@"A1", @"C1"]: @((int)GoMarkupConnectionLine)};
  XCTAssertEqualObjects(testee.connections, expectedConnections);

  [testee removeConnectionFromVertex:@"A1" toVertex:@"C1"];
  XCTAssertNil(testee.connections);

  [testee removeConnectionFromVertex:@"A1" toVertex:@"C1"];
  XCTAssertNil(testee.connections);

  XCTAssertThrowsSpecificNamed([testee removeConnectionFromVertex:nil toVertex:@"B1"],
                               NSException, NSInvalidArgumentException, @"removeConnectionFromVertex:toVertex: with nil object for fromVertex");
  XCTAssertThrowsSpecificNamed([testee removeConnectionFromVertex:@"A1" toVertex:nil],
                               NSException, NSInvalidArgumentException, @"removeConnectionFromVertex:toVertex: with nil object for toVertex");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the replaceConnections:() method.
// -----------------------------------------------------------------------------
- (void) testReplaceConnections
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.connections);

  NSDictionary* newConnections;

  newConnections = @{ @[@"A1", @"B1"]: @((int)GoMarkupConnectionArrow), @[@"A1", @"C1"]: @((int)GoMarkupConnectionLine)};
  [testee replaceConnections:newConnections];
  XCTAssertNotIdentical(testee.connections, newConnections);
  XCTAssertEqualObjects(testee.connections, newConnections);

  newConnections = @{ @[@"A1", @"B1"]: @((int)GoMarkupConnectionLine), @[@"A1", @"C1"]: @((int)GoMarkupConnectionLine), @[@"B1", @"A1"]: @((int)GoMarkupConnectionLine)};
  [testee replaceConnections:newConnections];
  XCTAssertNotIdentical(testee.connections, newConnections);
  XCTAssertEqualObjects(testee.connections, newConnections);

  [testee replaceConnections:newConnections];
  XCTAssertNotIdentical(testee.connections, newConnections);
  XCTAssertEqualObjects(testee.connections, newConnections);

  [testee replaceConnections:nil];
  XCTAssertNil(testee.connections);

  [testee replaceConnections:nil];
  XCTAssertNil(testee.connections);

  // The SGF standard does not allow arrows or lines that have the same start
  // and end point.
  newConnections = @{ @[@"A1", @"A1"]: @((int)GoMarkupConnectionLine)};
  XCTAssertThrowsSpecificNamed([testee replaceConnections:newConnections],
                               NSException, NSInvalidArgumentException, @"replaceConnections: with dictionary that contains entry with same vertex for both endpoints of the connection");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the removeAllConnections() method.
// -----------------------------------------------------------------------------
- (void) testRemoveAllConnections
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.connections);

  NSDictionary* newConnections;

  newConnections = @{ @[@"A1", @"B1"]: @((int)GoMarkupConnectionArrow), @[@"A1", @"C1"]: @((int)GoMarkupConnectionLine)};
  [testee replaceConnections:newConnections];
  XCTAssertNotIdentical(testee.connections, newConnections);
  XCTAssertEqualObjects(testee.connections, newConnections);

  [testee removeAllConnections];
  XCTAssertNil(testee.connections);

  [testee removeAllConnections];
  XCTAssertNil(testee.connections);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setLabel:labelText:atVertex:() method.
// -----------------------------------------------------------------------------
- (void) testSetLabelLabelTextAtVertex
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.labels);

  NSDictionary* expectedLabels;
  NSNumber* labelTypeAsNumber = [NSNumber numberWithInt:GoMarkupLabelLabel];

  [testee setLabel:GoMarkupLabelLabel labelText:@"foo" atVertex:@"A1"];
  expectedLabels = @{ @"A1": @[labelTypeAsNumber, @"foo"]};
  XCTAssertEqualObjects(testee.labels, expectedLabels);

  [testee setLabel:GoMarkupLabelLabel labelText:@"bar" atVertex:@"B1"];
  expectedLabels = @{ @"A1": @[labelTypeAsNumber, @"foo"], @"B1": @[labelTypeAsNumber, @"bar"]};
  XCTAssertEqualObjects(testee.labels, expectedLabels);

  [testee setLabel:GoMarkupLabelLabel labelText:@"baz" atVertex:@"A1"];
  expectedLabels = @{ @"A1": @[labelTypeAsNumber, @"baz"], @"B1": @[labelTypeAsNumber, @"bar"]};
  XCTAssertEqualObjects(testee.labels, expectedLabels);

  [testee setLabel:GoMarkupLabelLabel labelText:@"foo\nbar" atVertex:@"C1"];
  expectedLabels = @{ @"A1": @[labelTypeAsNumber, @"baz"], @"B1": @[labelTypeAsNumber, @"bar"], @"C1": @[labelTypeAsNumber, @"foo bar"]};
  XCTAssertEqualObjects(testee.labels, expectedLabels);

  [testee setLabel:GoMarkupLabelLabel labelText:@"\t\r\n foo bar \t\r\n" atVertex:@"D1"];
  expectedLabels = @{ @"A1": @[labelTypeAsNumber, @"baz"], @"B1": @[labelTypeAsNumber, @"bar"], @"C1": @[labelTypeAsNumber, @"foo bar"], @"D1": @[labelTypeAsNumber, @"foo bar"]};
  XCTAssertEqualObjects(testee.labels, expectedLabels);

  XCTAssertThrowsSpecificNamed([testee setLabel:GoMarkupLabelLabel labelText:nil atVertex:@"A1"],
                               NSException, NSInvalidArgumentException, @"setLabel:labelText:atVertex: with nil object for label");
  XCTAssertThrowsSpecificNamed([testee setLabel:GoMarkupLabelLabel labelText:@"foo" atVertex:nil],
                               NSException, NSInvalidArgumentException, @"setLabel:labelText:atVertex: with nil object for vertex");
  XCTAssertThrowsSpecificNamed([testee setLabel:GoMarkupLabelLabel labelText:@"A" atVertex:@"A1"],
                               NSException, NSInvalidArgumentException, @"setLabel:labelText:atVertex: with non-matching label type");
  // This tests non-standard behaviour of GoNodeMarkup: The SGF standard does
  // not declare empty label texts as illegal. GoNodeMarkup does not support
  // empty label texts, though. Cf. documentation of the "labels" property in
  // GoNodeMarkup.
  XCTAssertThrowsSpecificNamed([testee setLabel:GoMarkupLabelLabel labelText:@"" atVertex:@"A1"],
                               NSException, NSInvalidArgumentException, @"setLabel:labelText:atVertex: with zero length string object for label");
  // Same as above, only the zero length check kicks in after whitespace
  // trimming
  XCTAssertThrowsSpecificNamed([testee setLabel:GoMarkupLabelLabel labelText:@" \t\r\n" atVertex:@"A1"],
                               NSException, NSInvalidArgumentException, @"setLabel:labelText:atVertex: with string object for label that consists only of whitespace");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the removeLabelAtVertex:() method.
// -----------------------------------------------------------------------------
- (void) testRemoveLabelAtVertex
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.labels);

  NSDictionary* expectedLabels;
  NSNumber* labelTypeAsNumber = [NSNumber numberWithInt:GoMarkupLabelLabel];

  [testee setLabel:GoMarkupLabelLabel labelText:@"foo" atVertex:@"A1"];
  [testee setLabel:GoMarkupLabelLabel labelText:@"bar" atVertex:@"B1"];
  expectedLabels = @{ @"A1": @[labelTypeAsNumber, @"foo"], @"B1": @[labelTypeAsNumber, @"bar"]};
  XCTAssertEqualObjects(testee.labels, expectedLabels);

  [testee removeLabelAtVertex:@"C1"];
  XCTAssertEqualObjects(testee.labels, expectedLabels);

  [testee removeLabelAtVertex:@"A1"];
  expectedLabels = @{ @"B1": @[labelTypeAsNumber, @"bar"]};
  XCTAssertEqualObjects(testee.labels, expectedLabels);

  [testee removeLabelAtVertex:@"B1"];
  XCTAssertNil(testee.labels);

  [testee removeLabelAtVertex:@"C1"];
  XCTAssertNil(testee.labels);

  XCTAssertThrowsSpecificNamed([testee removeLabelAtVertex:nil],
                               NSException, NSInvalidArgumentException, @"removeLabelAtVertex with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the replaceLabels:() method.
// -----------------------------------------------------------------------------
- (void) testReplaceLabels
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.labels);

  NSDictionary* newLabels;
  NSNumber* labelTypeAsNumber = [NSNumber numberWithInt:GoMarkupLabelLabel];

  newLabels = @{ @"A1": @[labelTypeAsNumber, @"foo"], @"B1": @[labelTypeAsNumber, @"bar"]};
  [testee replaceLabels:newLabels];
  XCTAssertNotIdentical(testee.labels, newLabels);
  XCTAssertEqualObjects(testee.labels, newLabels);

  newLabels = @{ @"A1": @[labelTypeAsNumber, @"foo"], @"B1": @[labelTypeAsNumber, @"bar"], @"C1": @[labelTypeAsNumber, @"foobar"]};
  [testee replaceLabels:newLabels];
  XCTAssertNotIdentical(testee.labels, newLabels);
  XCTAssertEqualObjects(testee.labels, newLabels);

  [testee replaceLabels:newLabels];
  XCTAssertNotIdentical(testee.labels, newLabels);
  XCTAssertEqualObjects(testee.labels, newLabels);

  newLabels = @{ @"A1": @[labelTypeAsNumber, @"\t\r\n foo bar \t\r\n"]};
  [testee replaceLabels:newLabels];
  XCTAssertNotIdentical(testee.labels, newLabels);
  newLabels = @{ @"A1": @[labelTypeAsNumber, @"foo bar"]};
  XCTAssertEqualObjects(testee.labels, newLabels);

  newLabels = @{ @"A1": @[[NSNumber numberWithInt:GoMarkupLabelMarkerNumber], @"A"]};
  [testee replaceLabels:newLabels];
  XCTAssertNotIdentical(testee.labels, newLabels);
  newLabels = @{ @"A1": @[[NSNumber numberWithInt:GoMarkupLabelMarkerLetter], @"A"]};
  XCTAssertEqualObjects(testee.labels, newLabels);

  [testee replaceLabels:nil];
  XCTAssertNil(testee.labels);

  [testee replaceLabels:nil];
  XCTAssertNil(testee.labels);

  // This tests non-standard behaviour of GoNodeMarkup: The SGF standard does
  // not declare empty label texts as illegal. GoNodeMarkup does not support
  // empty label texts, though. Cf. documentation of the "labels" property in
  // GoNodeMarkup.
  newLabels = @{ @"A1": @[labelTypeAsNumber, @""]};
  XCTAssertThrowsSpecificNamed([testee replaceLabels:newLabels],
                               NSException, NSInvalidArgumentException, @"replaceLabels: with dictionary that contains entry with zero length string for label");
  // Same as above, only the zero length check kicks in after whitespace
  // trimming
  newLabels = @{ @"A1": @[labelTypeAsNumber, @" \t\r\n"]};
  XCTAssertThrowsSpecificNamed([testee replaceLabels:newLabels],
                               NSException, NSInvalidArgumentException, @"replaceLabels: with dictionary that contains entry with string object for label that consists only of whitespace");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the removeAllLabels() method.
// -----------------------------------------------------------------------------
- (void) testRemoveAllLabels
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.labels);

  NSDictionary* newLabels;
  NSNumber* labelTypeAsNumber = [NSNumber numberWithInt:GoMarkupLabelLabel];

  newLabels = @{ @"A1": @[labelTypeAsNumber, @"foo"], @"B1": @[labelTypeAsNumber, @"bar"]};
  [testee replaceLabels:newLabels];
  XCTAssertNotIdentical(testee.labels, newLabels);
  XCTAssertEqualObjects(testee.labels, newLabels);

  [testee removeAllLabels];
  XCTAssertNil(testee.labels);

  [testee removeAllLabels];
  XCTAssertNil(testee.labels);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the removeNewlinesAndTrimLabel:() method.
// -----------------------------------------------------------------------------
- (void) testRemoveNewlinesAndTrimLabel
{
  NSString* labelText;

  labelText = [GoNodeMarkup removeNewlinesAndTrimLabel:@"foo"];
  XCTAssertEqualObjects(labelText, @"foo");
  labelText = [GoNodeMarkup removeNewlinesAndTrimLabel:@" \t\r\nfoo\nbar\t\r\n"];
  XCTAssertEqualObjects(labelText, @"foo bar");
  labelText = [GoNodeMarkup removeNewlinesAndTrimLabel:@" \t\r\n"];
  XCTAssertEqualObjects(labelText, @"");
  labelText = [GoNodeMarkup removeNewlinesAndTrimLabel:@""];
  XCTAssertEqualObjects(labelText, @"");

  XCTAssertThrowsSpecificNamed([GoNodeMarkup removeNewlinesAndTrimLabel:nil],
                               NSException, NSInvalidArgumentException, @"removeNewlinesAndTrimLabel with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the labelTypeOfLabel:() method.
// -----------------------------------------------------------------------------
- (void) testLabelTypeOfLabel
{
  enum GoMarkupLabel labelType;

  labelType = [GoNodeMarkup labelTypeOfLabel:@"foo"];
  XCTAssertEqual(labelType, GoMarkupLabelLabel);

  labelType = [GoNodeMarkup labelTypeOfLabel:@"Q"];
  XCTAssertEqual(labelType, GoMarkupLabelMarkerLetter);

  labelType = [GoNodeMarkup labelTypeOfLabel:@"QQ"];
  XCTAssertEqual(labelType, GoMarkupLabelLabel);

  labelType = [GoNodeMarkup labelTypeOfLabel:@"ä"];
  XCTAssertEqual(labelType, GoMarkupLabelLabel);

  labelType = [GoNodeMarkup labelTypeOfLabel:@"5"];
  XCTAssertEqual(labelType, GoMarkupLabelMarkerNumber);

  labelType = [GoNodeMarkup labelTypeOfLabel:@"0"];
  XCTAssertEqual(labelType, GoMarkupLabelLabel);

  labelType = [GoNodeMarkup labelTypeOfLabel:@"55"];
  XCTAssertEqual(labelType, GoMarkupLabelLabel);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the labelTypeOfLabel:letterMarkerValue:numberMarkerValue:()
/// method.
// -----------------------------------------------------------------------------
- (void) testLabelTypeOfLabelLetterMarkerValueNumberMarkerValue
{
  enum GoMarkupLabel labelType;
  char letterMarkerValue;
  int numberMarkerValue;

  labelType = [GoNodeMarkup labelTypeOfLabel:@"foo" letterMarkerValue:&letterMarkerValue numberMarkerValue:&numberMarkerValue];
  XCTAssertEqual(labelType, GoMarkupLabelLabel);

  labelType = [GoNodeMarkup labelTypeOfLabel:@"Q" letterMarkerValue:&letterMarkerValue numberMarkerValue:&numberMarkerValue];
  XCTAssertEqual(labelType, GoMarkupLabelMarkerLetter);
  XCTAssertEqual(letterMarkerValue, 'Q');

  labelType = [GoNodeMarkup labelTypeOfLabel:@"QQ" letterMarkerValue:&letterMarkerValue numberMarkerValue:&numberMarkerValue];
  XCTAssertEqual(labelType, GoMarkupLabelLabel);

  labelType = [GoNodeMarkup labelTypeOfLabel:@"ä" letterMarkerValue:&letterMarkerValue numberMarkerValue:&numberMarkerValue];
  XCTAssertEqual(labelType, GoMarkupLabelLabel);

  labelType = [GoNodeMarkup labelTypeOfLabel:@"5" letterMarkerValue:&letterMarkerValue numberMarkerValue:&numberMarkerValue];
  XCTAssertEqual(labelType, GoMarkupLabelMarkerNumber);
  XCTAssertEqual(numberMarkerValue, 5);

  labelType = [GoNodeMarkup labelTypeOfLabel:@"0" letterMarkerValue:&letterMarkerValue numberMarkerValue:&numberMarkerValue];
  XCTAssertEqual(labelType, GoMarkupLabelLabel);

  labelType = [GoNodeMarkup labelTypeOfLabel:@"55" letterMarkerValue:&letterMarkerValue numberMarkerValue:&numberMarkerValue];
  XCTAssertEqual(labelType, GoMarkupLabelLabel);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the setDimmingAtVertex:() method.
// -----------------------------------------------------------------------------
- (void) testSetDimmingAtVertex
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.dimmings);

  NSArray* expectedDimmings;

  [testee setDimmingAtVertex:@"A1"];
  expectedDimmings = @[@"A1"];
  XCTAssertEqualObjects(testee.dimmings, expectedDimmings);

  [testee setDimmingAtVertex:@"B1"];
  expectedDimmings = @[@"A1", @"B1"];
  XCTAssertEqualObjects(testee.dimmings, expectedDimmings);

  [testee setDimmingAtVertex:@"A1"];
  expectedDimmings = @[@"A1", @"B1"];
  XCTAssertEqualObjects(testee.dimmings, expectedDimmings);

  XCTAssertThrowsSpecificNamed([testee setDimmingAtVertex:nil],
                               NSException, NSInvalidArgumentException, @"setDimmingAtVertex: with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the removeDimmingAtVertex:() method.
// -----------------------------------------------------------------------------
- (void) testRemoveDimmingAtVertex
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.dimmings);

  NSArray* expectedDimmings;

  [testee setDimmingAtVertex:@"A1"];
  [testee setDimmingAtVertex:@"B1"];
  expectedDimmings = @[@"A1", @"B1"];
  XCTAssertEqualObjects(testee.dimmings, expectedDimmings);

  [testee removeDimmingAtVertex:@"C1"];
  XCTAssertEqualObjects(testee.dimmings, expectedDimmings);

  [testee removeDimmingAtVertex:@"A1"];
  expectedDimmings = @[@"B1"];
  XCTAssertEqualObjects(testee.dimmings, expectedDimmings);

  [testee removeDimmingAtVertex:@"B1"];
  XCTAssertNil(testee.dimmings);

  [testee removeDimmingAtVertex:@"C1"];
  XCTAssertNil(testee.dimmings);

  XCTAssertThrowsSpecificNamed([testee removeDimmingAtVertex:nil],
                               NSException, NSInvalidArgumentException, @"removeDimmingAtVertex with nil object");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the replaceDimmings:() method.
// -----------------------------------------------------------------------------
- (void) testReplaceDimmings
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.dimmings);

  NSArray* newDimmings;

  newDimmings = @[@"A1", @"B1"];
  [testee replaceDimmings:newDimmings];
  XCTAssertNotIdentical(testee.dimmings, newDimmings);
  XCTAssertEqualObjects(testee.dimmings, newDimmings);

  newDimmings = @[@"A1", @"B1", @"C1"];
  [testee replaceDimmings:newDimmings];
  XCTAssertNotIdentical(testee.dimmings, newDimmings);
  XCTAssertEqualObjects(testee.dimmings, newDimmings);

  [testee replaceDimmings:newDimmings];
  XCTAssertNotIdentical(testee.dimmings, newDimmings);
  XCTAssertEqualObjects(testee.dimmings, newDimmings);

  [testee replaceDimmings:nil];
  XCTAssertNil(testee.symbols);

  [testee replaceDimmings:nil];
  XCTAssertNil(testee.symbols);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the undimEverything() method.
// -----------------------------------------------------------------------------
- (void) testUndimEverything
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.dimmings);

  NSArray* newDimmings;

  [testee undimEverything];
  newDimmings = @[];
  XCTAssertNotIdentical(testee.dimmings, newDimmings);
  XCTAssertEqualObjects(testee.dimmings, newDimmings);

  newDimmings = @[@"A1", @"B1"];
  [testee replaceDimmings:newDimmings];
  XCTAssertNotIdentical(testee.dimmings, newDimmings);
  XCTAssertEqualObjects(testee.dimmings, newDimmings);

  newDimmings = @[];
  [testee undimEverything];
  XCTAssertNotIdentical(testee.dimmings, newDimmings);
  XCTAssertEqualObjects(testee.dimmings, newDimmings);

  [testee undimEverything];
  XCTAssertNotIdentical(testee.dimmings, newDimmings);
  XCTAssertEqualObjects(testee.dimmings, newDimmings);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the removeAllDimmings() method.
// -----------------------------------------------------------------------------
- (void) testRemoveAllDimmings
{
  GoNodeMarkup* testee = [[[GoNodeMarkup alloc] init] autorelease];
  XCTAssertNil(testee.dimmings);

  NSArray* newDimmings;

  newDimmings = @[@"A1", @"B1"];
  [testee replaceDimmings:newDimmings];
  XCTAssertNotIdentical(testee.dimmings, newDimmings);
  XCTAssertEqualObjects(testee.dimmings, newDimmings);

  [testee removeAllDimmings];
  XCTAssertNil(testee.dimmings);

  [testee removeAllDimmings];
  XCTAssertNil(testee.dimmings);
}

@end
