#import "MITLibrariesConsultationFormSheetViewController.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesAskUsModel.h"
#import "MITLibrariesFormSheetElementCustomElementsHeader.h"
#import "MITLibrariesFormSheetGroupCustomGroupsHeader.h"

@implementation MITLibrariesConsultationFormSheetViewController

#pragma mark - Setup

- (void)setup
{
    [super setup];
    self.title = @"Consultation";
    [self setupFormSheetGroups];
}

- (void)setupFormSheetGroups
{
    [self showActivityIndicator];
    [MITLibrariesFormSheetGroupConsultationTopGroup loadConsultationTopGroupInBackgroundWithCompletion:^(MITLibrariesFormSheetGroupConsultationTopGroup *topGroup, NSError *error) {
        [self hideActivityIndicator];
        if (!error) {
            MITLibrariesFormSheetGroup *bottomGroup = [MITLibrariesFormSheetGroupConsultationBottomGroup new];
            self.formSheetGroups = @[topGroup, bottomGroup];
            [self reloadTableView];
        }
        else {
            NSLog(@"Error building top form sheet group: %@", error);
            [self notifyOfTopicsFetchFailure];
        }
    }];
}

#pragma mark - Form Submission

- (void)submitFormForParameters:(NSDictionary *)parameters
{
    NSMutableDictionary *paramsToSubmit = [parameters mutableCopy];
    paramsToSubmit[@"ask_type"] = @"consultation";
    [self showActivityIndicator];
    [MITLibrariesWebservices postAskUsFormForParameters:paramsToSubmit withCompletion:^(id responseObject, NSError *error) {
        [self hideActivityIndicator];
        if (!error) {
            [self notifyFormSubmissionSuccessWithResponseObject:responseObject];
            [self closeFormSheetViewController];
        } else {
            [self notifyFormSubmissionError];
        }
    }];
}

#pragma mark - Failure Alerts

- (void)notifyOfTopicsFetchFailure
{
    NSString *title = @"Unable To Fetch Options";
    NSString *message = @"We were unable to receive some of the options necessary for submiting a request.  Please check your internet connection and try again.";
    NSString *confirmation = @"Ok";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:confirmation, nil];
    [alert show];
}

@end
