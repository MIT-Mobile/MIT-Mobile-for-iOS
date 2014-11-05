
#import "MITLibrariesAskUsFormSheetViewController.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesAskUsModel.h"

@interface MITLibrariesAskUsFormSheetViewController ()
@end

@implementation MITLibrariesAskUsFormSheetViewController

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
    NSMutableArray *formSheetGroups = [NSMutableArray array];
    [formSheetGroups addObject:[self topFormSheetGroup]];
    [formSheetGroups addObject:[self bottomFormSheetGroup]];
    self.formSheetGroups = formSheetGroups;
    [self reloadTableView];
}

- (MITLibrariesFormSheetGroup *)topFormSheetGroup
{
    MITLibrariesFormSheetElement *topic = [MITLibrariesFormSheetElement new];
    topic.type = MITLibrariesFormSheetElementTypeOptions;
    topic.title = @"Topic";
    topic.value = @"General";
    
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
    
    return topGroup;
}

- (MITLibrariesFormSheetGroup *)bottomFormSheetGroup
{
    MITLibrariesFormSheetElement *status = [MITLibrariesFormSheetElement new];
    status.type = MITLibrariesFormSheetElementTypeOptions;
    status.title = @"Status";
    status.value = @"MIT Undergrad Student";
    
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
    
    MITLibrariesFormSheetElement *location = [MITLibrariesFormSheetElement new];
    location.type = MITLibrariesFormSheetElementTypeOptions;
    location.title = @"Location";
    
    MITLibrariesFormSheetGroup *technicalHelpGroup = [MITLibrariesFormSheetGroup new];
    technicalHelpGroup.headerTitle = @"TECHNICAL HELP";
    technicalHelpGroup.elements = @[usingVPN, location];
    
    return technicalHelpGroup;
}

@end
