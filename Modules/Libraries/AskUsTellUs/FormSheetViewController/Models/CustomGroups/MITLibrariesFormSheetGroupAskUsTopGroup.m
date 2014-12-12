#import "MITLibrariesFormSheetGroupAskUsTopGroup.h"
#import "MITLibrariesFormSheetElementCustomElementsHeader.h"

@implementation MITLibrariesFormSheetGroupAskUsTopGroup

+ (void)loadAskUsTopGroupInBackgroundWithCompletion:(void(^)(MITLibrariesFormSheetGroupAskUsTopGroup *askUsTopGroup, NSError *error))completion
{
    [MITLibrariesFormSheetElementTopic getAskUsTopicFormSheetElementInBackgroundWithCompletion:^(MITLibrariesFormSheetElementTopic *topicElement, NSError *error) {
        if (!error) {
            MITLibrariesFormSheetElement *subject = [MITLibrariesFormSheetElementSubject new];
            MITLibrariesFormSheetElement *detailedQuestion = [MITLibrariesFormSheetElementDetailedQuestion new];
            
            MITLibrariesFormSheetGroupAskUsTopGroup *topGroup = [MITLibrariesFormSheetGroupAskUsTopGroup new];
            topGroup.headerTitle = nil;
            topGroup.footerTitle = nil;
            topGroup.elements = @[topicElement, subject, detailedQuestion];
            
            completion(topGroup, nil);
        }
        else {
            completion(nil, error);
        }
    }];
}

@end
