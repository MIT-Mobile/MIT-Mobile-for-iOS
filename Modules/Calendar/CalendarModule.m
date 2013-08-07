#import "CalendarModule.h"
#import "CalendarEventsViewController.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "MITModuleURL.h"
#import "CalendarEventMapAnnotation.h"
#import "MITEventList.h"
#import "MITModule+Protected.h"

@implementation CalendarModule
@dynamic calendarVC;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = CalendarTag;
        self.shortName = @"Events";
        self.longName = @"Events Calendar";
        self.iconName = @"calendar";
        
        [[CalendarDataManager sharedManager] requestEventLists];
    }
    return self;
}

- (void)loadModuleHomeController
{
    CalendarEventsViewController *controller = [[CalendarEventsViewController alloc] init];
    controller.showList = YES;
    controller.showScroller = YES;
    
    self.moduleHomeController = controller;
}


- (CalendarEventsViewController*)calendarVC;
{
    if ([self.moduleHomeController isKindOfClass:[CalendarEventsViewController class]]) {
        return (CalendarEventsViewController*) self.moduleHomeController;
    } else {
        return nil;
    }
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query
{
	return NO;
}

@end
