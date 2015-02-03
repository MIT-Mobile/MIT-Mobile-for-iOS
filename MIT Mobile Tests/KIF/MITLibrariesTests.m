//
//  MITPracticeTest.m
//  MIT Mobile
//
//  Created by Logan Wright on 2/3/15.
//
//

#import "MITLibrariesTests.h"
#import "KIFUITestActor+Navigation.h"

@implementation MITLibrariesTests

- (void)beforeEach
{
    [tester navigateToModuleWithName:@"Libraries"];
}

- (void)testSearchAndCitations
{
    [tester enterText:@"banana" intoViewWithAccessibilityLabel:@"Libraries Home Search Bar"];
    [tester tapViewWithAccessibilityLabel:@"search"];
    [tester waitForViewWithAccessibilityLabel:@"Libraries Search Results Table View"];
    [tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Libraries Search Results Table View"];
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Libraries Search Results Table View"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Citations"];
    [tester tapViewWithAccessibilityLabel:@"Citations"];
}

@end
