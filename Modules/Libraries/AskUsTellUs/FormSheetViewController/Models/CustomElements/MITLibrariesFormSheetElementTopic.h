#import "MITLibrariesFormSheetElement.h"

@interface MITLibrariesFormSheetElementTopic : MITLibrariesFormSheetElement
+ (void)getAskUsTopicFormSheetElementInBackgroundWithCompletion:(void(^)(MITLibrariesFormSheetElementTopic *topicElement, NSError *error))completion;
+ (void)getConsultationAppointmentTopicFormSheetElementInBackgroundWithCompletion:(void(^)(MITLibrariesFormSheetElementTopic *topicElement, NSError *error))completion;
@end
