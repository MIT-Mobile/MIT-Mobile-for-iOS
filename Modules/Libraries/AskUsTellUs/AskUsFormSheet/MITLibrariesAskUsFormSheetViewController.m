
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

- (MITLibrariesFormSheetGroup *)technicalHelpFormSheetGroup
{
    MITLibrariesFormSheetElement *usingVPN = [MITLibrariesFormSheetElement new];
    usingVPN.type = MITLibrariesFormSheetElementTypeOptions;
    usingVPN.title = @"Using VPN";
    MITLibrariesFormSheetElementAvailableOption *vpnOptionOnCampus = [MITLibrariesFormSheetElementAvailableOption new];
    vpnOptionOnCampus.value = @"On Campus";
    // TODO: Find actual html value
    vpnOptionOnCampus.htmlValue = @"on_campus";
    MITLibrariesFormSheetElementAvailableOption *vpnOptionOffCampus = [MITLibrariesFormSheetElementAvailableOption new];
    vpnOptionOffCampus.value = @"Off Campus";
    // TODO: Find actual html value
    vpnOptionOffCampus.htmlValue = @"off_campus";
    usingVPN.availableOptions = @[vpnOptionOnCampus, vpnOptionOffCampus];
    
    MITLibrariesFormSheetElement *location = [MITLibrariesFormSheetElement new];
    location.type = MITLibrariesFormSheetElementTypeOptions;
    location.title = @"Location";
    
    MITLibrariesFormSheetGroup *technicalHelpGroup = [MITLibrariesFormSheetGroup new];
    technicalHelpGroup.headerTitle = @"TECHNICAL HELP";
    technicalHelpGroup.elements = @[usingVPN, location];
    
    return technicalHelpGroup;
}

#pragma mark - Failure Alerts

- (void)notifyOfTopicsFetchFailure
{
    
}

@end
