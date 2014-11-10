#import "MITLibrariesFormSheetGroupConsultationTopGroup.h"
#import "MITLibrariesFormSheetElementCustomElementsHeader.h"

@implementation MITLibrariesFormSheetGroupConsultationTopGroup
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.headerTitle = @"RESEARCH INFO";
        self.footerTitle = @"Your request will be sent to the appropriate person, based on your choice of subject.";
    }
    return self;
}
+ (void)loadConsultationTopGroupInBackgroundWithCompletion:(void(^)(MITLibrariesFormSheetGroupConsultationTopGroup *topGroup, NSError *error))completion
{
    [MITLibrariesFormSheetElementTopic getConsultationAppointmentTopicFormSheetElementInBackgroundWithCompletion:^(MITLibrariesFormSheetElementTopic *topicElement, NSError *error) {
        if (!error) {
            
            MITLibrariesFormSheetElement *timeframe = [MITLibrariesFormSheetElementTimeframe new];
            MITLibrariesFormSheetElement *howCanWeHelp = [MITLibrariesFormSheetElementHowCanWeHelp new];
            MITLibrariesFormSheetElement *purpose = [MITLibrariesFormSheetElementPurpose new];
            MITLibrariesFormSheetElement *course = [MITLibrariesFormSheetElementCourse new];
            MITLibrariesFormSheetElement *subject = [MITLibrariesFormSheetElementConsultationSubject new];
            
            MITLibrariesFormSheetGroupConsultationTopGroup *topGroup = [MITLibrariesFormSheetGroupConsultationTopGroup new];
            topGroup.elements = @[topicElement, timeframe, howCanWeHelp, purpose, course, subject];
            
            completion(topGroup, nil);
        } else {
            completion(nil, error);
        }
    }];
}
@end
