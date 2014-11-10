#import "MITLibrariesTellUsFormSheetViewController.h"
#import "MITLibrariesFormSheetElementStatus.h"
#import "MITLibrariesWebservices.h"

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
    NSMutableArray *formSheetGroups = [NSMutableArray array];
    [formSheetGroups addObject:[self topFormSheetGroup]];
    [formSheetGroups addObject:[self bottomFormSheetGroup]];
    self.formSheetGroups = formSheetGroups;
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

#pragma mark - Data Assembly

- (MITLibrariesFormSheetGroup *)topFormSheetGroup
{
    MITLibrariesFormSheetElementStatus *status = [MITLibrariesFormSheetElementStatus new];

    MITLibrariesFormSheetElement *feedback = [MITLibrariesFormSheetElement new];
    feedback.type = MITLibrariesFormSheetElementTypeMultiLineTextEntry;
    feedback.title = @"Feedback";
    feedback.htmlParameterKey = @"feedback";
    
    MITLibrariesFormSheetGroup *topGroup = [MITLibrariesFormSheetGroup new];
    topGroup.headerTitle = nil;
    topGroup.footerTitle = @"Please let us know your thoughts for improving our services.  We'd also appreciate hearing what you like about our current services.";
    topGroup.elements = @[status, feedback];
    return topGroup;
}

- (MITLibrariesFormSheetGroup *)bottomFormSheetGroup
{
    MITLibrariesFormSheetElement *suggestedPurchaseForm = [MITLibrariesFormSheetElement new];
    suggestedPurchaseForm.type = MITLibrariesFormSheetElementTypeWebLink;
    suggestedPurchaseForm.title = @"Suggested Purchase Form";
    suggestedPurchaseForm.value = @"http://libraries.mit.edu/suggest-purchase";
    
    MITLibrariesFormSheetGroup *bottomGroup = [MITLibrariesFormSheetGroup new];
    bottomGroup.headerTitle = nil;
    bottomGroup.footerTitle = @"If you would like to suggest a purchase for our collections, please see the Suggested Purchase form.";
    bottomGroup.elements = @[suggestedPurchaseForm];
    
    return bottomGroup;
}

#pragma mark - Failure Alerts

- (void)notifyOfTopicsFetchFailure
{
    
}

@end
