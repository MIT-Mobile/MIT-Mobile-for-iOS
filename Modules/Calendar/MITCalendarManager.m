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

- (void)getEventsForCalendar:(MITCalendarsCalendar *)calendar
                    category:(MITCalendarsCalendar *)category
                        date:(NSDate *)date
                  completion:(MITCachedEventsCompletionBlock)completion
{
    // Empty Cache if we're switching to a different calendar
    if ((category && ![category isEqualToCalendar:self.currentCategory]) || ![calendar isEqualToCalendar:self.currentCalendar]) {
        [self.calendarCache removeAllObjects];
        self.currentCategory = category;
        self.currentCalendar = calendar;
    }
    
    NSLog(@"Date: %@", date);
    
    NSArray *cachedEvents = [self.calendarCache objectForKey:date];
    
    
    if (cachedEvents) {
        completion(cachedEvents, nil);
    }
    else {
        [self loadEventsForCalendar:calendar category:category date:date completion:completion];
        
        if (![self.calendarCache objectForKey:[[date dayBefore] description]]) {
            [self loadEventsForCalendar:calendar category:category date:[date dayBefore]  completion:NULL];
        }
        if (![self.calendarCache objectForKey:[[date dayAfter] description]]) {
            [self loadEventsForCalendar:calendar category:category date:[date dayAfter]  completion:NULL];
        }
    }
}

- (void)loadEventsForCalendar:(MITCalendarsCalendar *)calendar
                     category:(MITCalendarsCalendar *)category
                         date:(NSDate *)date
                   completion:(MITCachedEventsCompletionBlock)completion
{
    [MITCalendarWebservices getEventsForCalendar:calendar category:category date:date completion:^(NSArray *events, NSError *error) {
        if (events) {
            if ([self.currentCalendar isEqualToCalendar:category]) { // Check to make sure we're writing into the right cache
                [self.calendarCache setObject:events forKey:[date description]];
            }
            if (completion) {
                completion(events, nil);
            }
        }
        else {
            if (completion) {
                completion(nil, error);
            }
        }
    }];
}

@end
