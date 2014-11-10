#import "MITLibrariesTellUsFormSheetViewController.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesFormSheetElementCustomElementsHeader.h"
#import "MITLibrariesFormSheetGroupCustomGroupsHeader.h"

@implementation MITLibrariesTellUsFormSheetViewController

#pragma mark - Setup

- (void)setup
{
    [super setup];
    self.title = @"Tell Us";
    [self setupFormSheetGroups];
}

- (void)setupFormSheetGroups
{
    MITLibrariesFormSheetGroup *topGroup = [MITLibrariesFormSheetGroupTellUsTopGroup new];
    MITLibrariesFormSheetGroup *bottomGroup = [MITLibrariesFormSheetGroupTellUsBottomGroup new];
    self.formSheetGroups = @[topGroup, bottomGroup];
    [self reloadTableView];
}

#pragma mark - Form Submission

- (void)submitFormForParameters:(NSDictionary *)parameters
{
    [self showActivityIndicator];
    [MITLibrariesWebservices postTellUsFormForParameters:parameters withCompletion:^(id responseObject, NSError *error) {
        [self hideActivityIndicator];
        if (!error) {
            [self notifyFormSubmissionSuccessWithResponseObject:responseObject];
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self notifyFormSubmissionError];
        }
    }];
}

#pragma mark - Failure Alerts

- (void)notifyOfTopicsFetchFailure
{
    
}

@end
