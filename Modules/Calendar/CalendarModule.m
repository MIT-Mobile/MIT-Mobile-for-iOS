#import "CalendarModule.h"
#import "CalendarEventsViewController.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "MITModuleURL.h"
#import "CalendarEventMapAnnotation.h"
#import "MITEventList.h"

#import "MITEventsHomeViewController.h"


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

- (UIViewController*)createHomeViewControllerForPhoneIdiom
{
    return [[MITEventsHomeViewController alloc] initWithNibName:nil bundle:nil];
}

- (UIViewController*)homeViewControllerForUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return [[MITEventsHomeViewController alloc] initWithNibName:nil bundle:nil];
}


@end
