
#import "MITLibrariesConsultationFormSheetViewController.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesAskUsModel.h"
#import "MITLibrariesFormSheetElementStatus.h"

@interface MITLibrariesConsultationFormSheetViewController ()

@end

@implementation MITLibrariesConsultationFormSheetViewController

#pragma mark - Initialization

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"MITLibrariesFormSheetViewController" bundle:nil];
    return self;
}

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
            topic.availableOptions = askUs.consultationLists;
            
            MITLibrariesFormSheetElement *timeframe = [MITLibrariesFormSheetElement new];
            timeframe.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
            timeframe.title = @"Timeframe";
            
            MITLibrariesFormSheetElement *howCanWeHelp = [MITLibrariesFormSheetElement new];
            howCanWeHelp.type = MITLibrariesFormSheetElementTypeMultiLineTextEntry;
            howCanWeHelp.title = @"How can we help you?";
            
            MITLibrariesFormSheetElement *purpose = [MITLibrariesFormSheetElement new];
            purpose.type = MITLibrariesFormSheetElementTypeOptions;
            purpose.title = @"Purpose";
            purpose.optional = YES;
            purpose.availableOptions = @[@"Course", @"Thesis", @"Research"];
            
            MITLibrariesFormSheetElement *course = [MITLibrariesFormSheetElement new];
            course.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
            course.title = @"Course";
            course.optional = YES;
            
            MITLibrariesFormSheetElement *subject = [MITLibrariesFormSheetElement new];
            subject.type = MITLibrariesFormSheetElementTypeOptions;
            subject.title = @"Subject";
            subject.availableOptions = @[@"General", @"Art & Architecture", @"Engineering & Computer Science", @"GIS", @"Humanities", @"Management & Business", @"Science", @"Social Sciences", @"Urban Planning"];
            
            
            MITLibrariesFormSheetGroup *topGroup = [MITLibrariesFormSheetGroup new];
            topGroup.headerTitle = @"RESEARCH INFO";
            topGroup.footerTitle = @"Your request will be sent to the appropriate person, based on your choice of subject.";
            topGroup.elements = @[topic, timeframe, howCanWeHelp, purpose, course, subject];
            
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
