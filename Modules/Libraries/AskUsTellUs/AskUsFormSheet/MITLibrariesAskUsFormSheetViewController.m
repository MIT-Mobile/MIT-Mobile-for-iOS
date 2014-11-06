
#import "MITLibrariesAskUsFormSheetViewController.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesAskUsModel.h"
#import "MITLibrariesFormSheetElementStatus.h"

@interface MITLibrariesAskUsFormSheetViewController ()
@end

@implementation MITLibrariesAskUsFormSheetViewController

#pragma mark - Setup

- (void)setup
{
    [super setup];
    [self setupFormSheetGroups];
}

- (void)setupFormSheetGroups
{
    [self showActivityIndicator];
    [self buildTopFormSheetGroupInBackgroundWithCompletion:^(MITLibrariesFormSheetGroup *formSheetGroup, NSError *error) {
        [self hideActivityIndicator];
        if (!error) {
            [self hideActivityIndicator];
            NSMutableArray *formSheetGroups = [NSMutableArray array];
            [formSheetGroups addObject:formSheetGroup];
            [formSheetGroups addObject:[self bottomFormSheetGroup]];
            self.formSheetGroups = formSheetGroups;
            [self reloadTableView];
        } else {
            NSLog(@"Error building top form sheet group: %@", error);
            [self notifyOfTopicsFetchFailure];
        }
    }];
}

#pragma mark - Data Assembly

// Backgrounded for topics fetch
- (void)buildTopFormSheetGroupInBackgroundWithCompletion:(void(^)(MITLibrariesFormSheetGroup *formSheetGroup, NSError *error))completion
{
    [MITLibrariesWebservices getAskUsTopicsWithCompletion:^(MITLibrariesAskUsModel *askUs, NSError *error) {
        if (!error) {
            MITLibrariesFormSheetElement *topic = [MITLibrariesFormSheetElement new];
            topic.type = MITLibrariesFormSheetElementTypeOptions;
            topic.title = @"Topic";
            topic.availableOptions = askUs.topics;
            
            MITLibrariesFormSheetElement *subject = [MITLibrariesFormSheetElement new];
            subject.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
            subject.title = @"Subject";
            
            MITLibrariesFormSheetElement *detailedQuestion = [MITLibrariesFormSheetElement new];
            detailedQuestion.type = MITLibrariesFormSheetElementTypeMultiLineTextEntry;
            detailedQuestion.title = @"Detailed question";
            
            MITLibrariesFormSheetGroup *topGroup = [MITLibrariesFormSheetGroup new];
            topGroup.headerTitle = nil;
            topGroup.footerTitle = nil;
            topGroup.elements = @[topic, subject, detailedQuestion];
            
            completion(topGroup, nil);
        } else {
            completion(nil, error);
        }
    }];
    
    
}

- (MITLibrariesFormSheetGroup *)bottomFormSheetGroup
{
    MITLibrariesFormSheetElementStatus *status = [MITLibrariesFormSheetElementStatus new];
    
    MITLibrariesFormSheetElement *department = [MITLibrariesFormSheetElement new];
    department.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
    department.title = @"Department, Lab, or Center";
    
    MITLibrariesFormSheetElement *phoneNumber = [MITLibrariesFormSheetElement new];
    phoneNumber.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
    phoneNumber.title = @"Phone";
    phoneNumber.optional = YES;
    
    MITLibrariesFormSheetGroup *bottomGroup = [MITLibrariesFormSheetGroup new];
    bottomGroup.headerTitle = @"PERSONAL INFO";
    bottomGroup.footerTitle = nil;
    bottomGroup.elements = @[status, department, phoneNumber];
    
    return bottomGroup;
}

- (MITLibrariesFormSheetGroup *)getNewTechnicalHelpFormSheetGroup
{
    MITLibrariesFormSheetElement *usingVPN = [MITLibrariesFormSheetElement new];
    usingVPN.type = MITLibrariesFormSheetElementTypeOptions;
    usingVPN.title = @"Using VPN";
    usingVPN.availableOptions = @[@"No", @"Yes"];
    
    MITLibrariesFormSheetElement *location = [MITLibrariesFormSheetElement new];
    location.type = MITLibrariesFormSheetElementTypeOptions;
    location.title = @"Location";
    location.availableOptions = @[@"On Campus", @"Off Campus"];
    
    MITLibrariesFormSheetGroup *technicalHelpGroup = [MITLibrariesFormSheetGroup new];
    technicalHelpGroup.headerTitle = @"TECHNICAL HELP";
    technicalHelpGroup.elements = @[usingVPN, location];
    
    return technicalHelpGroup;
}

#pragma mark - MITLibrariesFormSheetOptionsSelectionViewControllerDelegate

- (void)formSheetOptionsSelectionViewController:(MITLibrariesFormSheetOptionsSelectionViewController *)optionsSelectionViewController didFinishUpdatingElement:(MITLibrariesFormSheetElement *)element
{
    [super formSheetOptionsSelectionViewController:optionsSelectionViewController didFinishUpdatingElement:element];
    if ([element.title isEqualToString:@"Topic"]) {
        if ([element.value isEqualToString:@"Technical Help"]) {
            [self showTechnicalFormGroup];
        } else {
            [self hideTechnicalFormGroup];
        }
    }
}

- (void)showTechnicalFormGroup
{
    MITLibrariesFormSheetGroup *technicalHelpGroup = [self activeTechnicalHelpGroup];
    if (!technicalHelpGroup) {
        NSMutableArray *formSheetGroups = [self.formSheetGroups mutableCopy];
        if (1 < formSheetGroups.count) {
            [formSheetGroups insertObject:[self getNewTechnicalHelpFormSheetGroup] atIndex:1];
        } else {
            [formSheetGroups addObject:[self getNewTechnicalHelpFormSheetGroup]];
        }
        self.formSheetGroups = formSheetGroups;
        [self reloadTableView];
    }
}

- (void)hideTechnicalFormGroup
{
    MITLibrariesFormSheetGroup *technicalHelpGroup = [self activeTechnicalHelpGroup];
    if (technicalHelpGroup) {
        NSMutableArray *formSheetGroups = [self.formSheetGroups mutableCopy];
        [formSheetGroups removeObject:technicalHelpGroup];
        self.formSheetGroups = formSheetGroups;
        [self reloadTableView];
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
    
}

@end
