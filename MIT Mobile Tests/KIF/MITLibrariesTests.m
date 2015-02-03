#import "MITLibrariesTests.h"

@implementation MITLibrariesTests

- (void)beforeEach
{
    [tester navigateToModuleWithName:@"Libraries"];
}

- (void)testSearchAndCitations
{
    [tester enterText:@"banana" intoViewWithAccessibilityLabel:MITAccessibilityLibrariesHomeSearchBarLabel];
    [tester pressReturnKeyOnCurrentFirstResponder];
    [tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:MITAccessibilityLibrariesSearchResultsTableViewIdentifier];
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:MITAccessibilityLibrariesSearchResultsTableViewIdentifier];
    [tester waitForTappableViewWithAccessibilityLabel:MITAccessibilityLibrariesSearchResultDetailCellLabelCitations];
    [tester tapViewWithAccessibilityLabel:MITAccessibilityLibrariesSearchResultDetailCellLabelCitations];
}

- (void)testMyAccount
{
    [tester tapViewWithAccessibilityLabel:MITAccessibilityLibrariesHomeCellYourAccount];
    NSString *user = nil; // Not committing account info, fill in before test.
    NSString *pswd = nil;
    if (!user || !pswd) {
        NSLog(@"\n\n***This test requires a valid username and password!***\n\n");
    }
    [tester enterText:user intoViewWithAccessibilityLabel:MITAccessibilityTouchstoneLoginFieldUsernameEmail];
    [tester enterText:pswd intoViewWithAccessibilityLabel:MITAccessibilityTouchstoneLoginFieldPassword];
    [tester tapViewWithAccessibilityLabel:MITAccessibilityTouchstoneLoginButtonLabel];
    NSIndexPath *firstPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [tester waitForCellAtIndexPath:firstPath inTableViewWithAccessibilityIdentifier:MITAccessibilityLibrariesMyAccountLoansTableViewIdentifier];
    [tester tapRowAtIndexPath:firstPath inTableViewWithAccessibilityIdentifier:MITAccessibilityLibrariesMyAccountLoansTableViewIdentifier];
    [tester tapViewWithAccessibilityLabel:MITAccessibilityLibrariesBackButtonLabelLoans];
    [tester tapViewWithAccessibilityLabel:MITAccessibilityLibrariesBackButtonLabelLibraries];
}

@end
