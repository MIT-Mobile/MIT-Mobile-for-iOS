#import "MITLibrariesConsultationFormSheetViewController.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesAskUsModel.h"
#import "MITLibrariesFormSheetElementStatus.h"

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
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self notifyFormSubmissionError];
        }
    }];
}

#pragma mark - Data Assembly

- (void)buildTopFormSheetGroupInBackgroundWithCompletion:(void(^)(MITLibrariesFormSheetGroup *formSheetGroup, NSError *error))completion
{
    [MITLibrariesWebservices getAskUsTopicsWithCompletion:^(MITLibrariesAskUsModel *askUs, NSError *error) {
        if (!error) {
            MITLibrariesFormSheetElement *topic = [MITLibrariesFormSheetElement new];
            topic.type = MITLibrariesFormSheetElementTypeOptions;
            topic.title = @"Topic";
            topic.htmlParameterKey = @"topic";
            topic.availableOptions = askUs.consultationLists;
            
            MITLibrariesFormSheetElement *timeframe = [MITLibrariesFormSheetElement new];
            timeframe.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
            timeframe.title = @"Timeframe";
            timeframe.htmlParameterKey = @"timeframe";
            
            MITLibrariesFormSheetElement *howCanWeHelp = [MITLibrariesFormSheetElement new];
            howCanWeHelp.type = MITLibrariesFormSheetElementTypeMultiLineTextEntry;
            howCanWeHelp.title = @"How can we help you?";
            howCanWeHelp.htmlParameterKey = @"description";
            
            MITLibrariesFormSheetElement *purpose = [MITLibrariesFormSheetElement new];
            purpose.type = MITLibrariesFormSheetElementTypeOptions;
            purpose.title = @"Purpose";
            purpose.htmlParameterKey = @"purpose";
            purpose.availableOptions = @[@"Course", @"Thesis", @"Research"];
            
            MITLibrariesFormSheetElement *course = [MITLibrariesFormSheetElement new];
            course.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
            course.title = @"Course";
            course.htmlParameterKey = @"course";
            course.optional = YES;
            
            MITLibrariesFormSheetElement *subject = [MITLibrariesFormSheetElement new];
            subject.type = MITLibrariesFormSheetElementTypeOptions;
            subject.title = @"Subject";
            subject.htmlParameterKey = @"subject";
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
    department.htmlParameterKey = @"department";
    
    MITLibrariesFormSheetElement *phoneNumber = [MITLibrariesFormSheetElement new];
    phoneNumber.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
    phoneNumber.title = @"Phone";
    phoneNumber.htmlParameterKey = @"phone";
    phoneNumber.optional = YES;
    
    MITLibrariesFormSheetGroup *bottomGroup = [MITLibrariesFormSheetGroup new];
    bottomGroup.headerTitle = @"PERSONAL INFO";
    bottomGroup.footerTitle = nil;
    bottomGroup.elements = @[status, department, phoneNumber];
    
    return bottomGroup;
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
