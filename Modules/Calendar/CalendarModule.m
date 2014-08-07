#import "CalendarModule.h"
#import "CalendarEventsViewController.h"
#import "CalendarDetailViewController.h"
#import "MITCalendarDataManager.h"
#import "MITModuleURL.h"
#import "CalendarEventMapAnnotation.h"
#import "MITEventList.h"

#import "MITEventsHomeViewController.h"
#import "MITEventsHomeViewControllerPad.h"

@implementation CalendarModule
@dynamic calendarVC;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = CalendarTag;
        self.shortName = @"Events";
        self.longName = @"Events Calendar";
        self.iconName = @"calendar";
        
        [[MITCalendarDataManager sharedManager] requestEventLists];
    }
    return self;
}

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return YES;
}

- (UIViewController*)createHomeViewControllerForPhoneIdiom
{
    return [[MITEventsHomeViewController alloc] initWithNibName:nil bundle:nil];
}

- (UIViewController*)createHomeViewControllerForPadIdiom
{
    return [[MITEventsHomeViewControllerPad alloc] initWithNibName:nil bundle:nil];
}

@end
