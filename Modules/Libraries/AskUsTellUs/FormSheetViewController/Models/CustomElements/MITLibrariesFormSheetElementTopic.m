#import "MITLibrariesFormSheetElementTopic.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesAskUsModel.h"

@implementation MITLibrariesFormSheetElementTopic

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Topic";
        self.htmlParameterKey = @"topic";
        self.type = MITLibrariesFormSheetElementTypeOptions;
    }
    return self;
}

+ (void)getAskUsTopicFormSheetElementInBackgroundWithCompletion:(void(^)(MITLibrariesFormSheetElementTopic *topicElement, NSError *error))completion
{
    [MITLibrariesWebservices getAskUsTopicsWithCompletion:^(MITLibrariesAskUsModel *askUs, NSError *error) {
        if (!error) {
            MITLibrariesFormSheetElementTopic *topicElement = [MITLibrariesFormSheetElementTopic new];
            topicElement.availableOptions = askUs.topics;
            completion(topicElement, nil);
        } else {
            completion(nil, error);
        }
    }];
}
+ (void)getConsultationAppointmentTopicFormSheetElementInBackgroundWithCompletion:(void (^)(MITLibrariesFormSheetElementTopic *, NSError *))completion
{
    [MITLibrariesWebservices getAskUsTopicsWithCompletion:^(MITLibrariesAskUsModel *askUs, NSError *error) {
        if (!error) {
            MITLibrariesFormSheetElementTopic *topicElement = [MITLibrariesFormSheetElementTopic new];
            topicElement.availableOptions = askUs.consultationLists;
            completion(topicElement, nil);
        } else {
            completion(nil, error);
        }
    }];
}
@end
