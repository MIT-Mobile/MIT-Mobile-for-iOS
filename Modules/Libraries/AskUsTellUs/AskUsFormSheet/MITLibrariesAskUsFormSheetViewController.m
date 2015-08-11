#import "MITLibrariesAskUsFormSheetViewController.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesAskUsModel.h"
#import "MITLibrariesFormSheetElementCustomElementsHeader.h"
#import "MITLibrariesFormSheetGroupCustomGroupsHeader.h"

@implementation MITLibrariesAskUsFormSheetViewController

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateFormSheetGroupsForTechnicalHelpAndReloadData];
}

#pragma mark - Setup

- (void)setup
{
    [super setup];
    self.title = @"Ask Us";
    [self fetchFormSheetGroups];
}

- (void)fetchFormSheetGroups
{
    [self showActivityIndicator];
    [MITLibrariesFormSheetGroupAskUsTopGroup loadAskUsTopGroupInBackgroundWithCompletion:^(MITLibrariesFormSheetGroupAskUsTopGroup *askUsTopGroup, NSError *error) {
        [self hideActivityIndicator];
        if (!error) {
            MITLibrariesFormSheetGroupAskUsBottomGroup *bottomGroup = [MITLibrariesFormSheetGroupAskUsBottomGroup new];
            self.formSheetGroups = @[askUsTopGroup, bottomGroup];
            [self updateFormSheetGroupsForTechnicalHelpAndReloadData];
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
    paramsToSubmit[@"ask_type"] = @"ask_us";
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

#pragma mark - TechnicalHelp Modifications

- (void)updateFormSheetGroupsForTechnicalHelpAndReloadData
{
    for (MITLibrariesFormSheetGroup *group in self.formSheetGroups) {
        BOOL shouldBreak = NO;
        for (MITLibrariesFormSheetElement *element in group.elements) {
            if ([element.title isEqualToString:@"Topic"]) {
                if ([element.value isEqualToString:@"Technical Help"]) {
                    [self showTechnicalFormGroup];
                } else {
                    [self hideTechnicalFormGroup];
                }
                
                shouldBreak = YES;
                break;
            }
        }
        if (shouldBreak) {
            break;
        }
    }
    
    [self reloadTableView];
}

- (void)showTechnicalFormGroup
{
    MITLibrariesFormSheetGroup *technicalHelpGroup = [self activeTechnicalHelpGroup];
    if (!technicalHelpGroup) {
        NSMutableArray *formSheetGroups = [self.formSheetGroups mutableCopy];
        if (1 < formSheetGroups.count) {
            [formSheetGroups insertObject:[MITLibrariesFormSheetGroupTechnicalHelp new] atIndex:1];
        } else {
            [formSheetGroups addObject:[MITLibrariesFormSheetGroupTechnicalHelp new]];
        }
        self.formSheetGroups = formSheetGroups;
    }
}

- (void)hideTechnicalFormGroup
{
    MITLibrariesFormSheetGroup *technicalHelpGroup = [self activeTechnicalHelpGroup];
    if (technicalHelpGroup) {
        NSMutableArray *formSheetGroups = [self.formSheetGroups mutableCopy];
        [formSheetGroups removeObject:technicalHelpGroup];
        self.formSheetGroups = formSheetGroups;
    }
}

- (MITLibrariesFormSheetGroup *)activeTechnicalHelpGroup
{
    MITLibrariesFormSheetGroup *technicalHelpGroup;
    for (MITLibrariesFormSheetGroup *group in self.formSheetGroups) {
        if ([group.headerTitle.lowercaseString isEqualToString:@"technical help"]) {
            technicalHelpGroup = group;
            break;
        }
    }
    return technicalHelpGroup;
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
