#import "MITCalendarManager.h"
#import "MITCalendarWebservices.h"
#import "Foundation+MITAdditions.h"

#import "MITCalendarsCalendar.h"

@interface MITCalendarManager  ()

@property (atomic) BOOL calendarsLoaded;
@property (atomic) BOOL isLoading;
@property (atomic, strong) NSMutableArray *completionBlocks;

@property (nonatomic, strong) MITCalendarsCalendar *currentCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *currentCategory;
@property (nonatomic, strong) NSCache *calendarCache;


@end

@implementation MITCalendarManager

+ (instancetype)sharedManager
{
    static MITCalendarManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MITCalendarManager alloc] init];
        [manager setup];
    });
    return manager;
}

- (void)setup
{
    self.isLoading = NO;
    self.calendarsLoaded = NO;
    self.completionBlocks = [[NSMutableArray alloc] init];
    self.calendarCache = [[NSCache alloc] init];
}

- (void)getCalendarsCompletion:(MITMasterCalendarCompletionBlock)completion
{
    [self.completionBlocks addObject:completion];

    if (self.calendarsLoaded) {
        [self executeCompletionBlocksWithError:nil];
    }
    else if (!self.isLoading) {
        self.isLoading = YES;
        [MITCalendarWebservices getCalendarsWithCompletion:^(NSArray *calendars, NSError *error) {
            if (calendars) {
                self.masterCalendar = [[MITMasterCalendar alloc] initWithCalendarsArray:calendars];
                self.calendarsLoaded = YES;
            }
            else {
                NSLog(@"Error Fetching Calendars: %@", error);
                self.masterCalendar = nil;
                self.calendarsLoaded = NO;
            }
            self.isLoading = NO;
            [self executeCompletionBlocksWithError:error];
        }];
    }
}

- (void)executeCompletionBlocksWithError:(NSError *)error
{
    for (MITMasterCalendarCompletionBlock completionBlock in self.completionBlocks) {
        completionBlock(self.masterCalendar, error);
    }
    [self.completionBlocks removeAllObjects];
}

@end
