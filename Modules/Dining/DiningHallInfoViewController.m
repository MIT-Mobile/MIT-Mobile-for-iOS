#import "DiningHallInfoViewController.h"
#import "DiningHallDetailHeaderView.h"
#import "VenueLocation.h"
#import "CoreDataManager.h"

#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "UIImageView+WebCache.h"
#import "DiningDay.h"
#import "DiningMeal.h"

@interface DiningHallInfoViewController ()

@property (nonatomic, strong) NSArray * scheduleInfo;

@property (nonatomic, assign) NSInteger locationSectionIndex;
@property (nonatomic, assign) NSInteger paymentSectionIndex;
@property (nonatomic, assign) NSInteger scheduleSectionIndex;

@end

@implementation DiningHallInfoViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self fetchScheduleInfo];
    
    self.title = [NSString stringWithFormat:@"%@ Info", self.venue.shortName];
    
    DiningHallDetailHeaderView *headerView = [[DiningHallDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 87)];
    headerView.titleLabel.text = self.venue.name;
    
    __weak DiningHallDetailHeaderView *weakHeaderView = headerView;
    [headerView.iconView setImageWithURL:[NSURL URLWithString:self.venue.iconURL]
                               completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        [weakHeaderView setNeedsLayout];
    }];
    
    NSDictionary *timeData = self.hallStatus;
    if ([timeData[@"isOpen"] boolValue]) {
        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#008800"];
    } else {
        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#bb0000"];
    }
    headerView.timeLabel.text = timeData[@"text"];
    self.tableView.tableHeaderView = headerView;
    
    _locationSectionIndex   = 0;
    _paymentSectionIndex    = 1;
    _scheduleSectionIndex   = 2;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Querying for Schedule Info

- (void) fetchScheduleInfo
{
    NSArray *daysInWeek = [DiningDay daysInWeekOfDate:[HouseVenue fakeDate] forVenue:self.venue]; 
    NSMutableArray *schedules = [NSMutableArray array];
    
    NSTimeInterval oneDay = 60*60*24;
    DiningDay *previousDay = nil;
    for (DiningDay *day in daysInWeek) {
        
        NSArray *daySchedule = [self scheduleInfoForDiningDay:day];
        if (!previousDay) {
            // first run through
            // set span start and end to the same thing, add daySchedule
            NSDictionary *scheduleDict = @{@"dayStart": day.date,
                                           @"dayEnd": day.date,
                                           @"meals":daySchedule};
            [schedules addObject:scheduleDict];
        } else {
            if ([previousDay.date timeIntervalSinceDate:day.date] <= oneDay) {
                // if day is adjacent need to compare schedules
                NSArray *previousSchedules = [schedules lastObject][@"meals"];  // lastObject will be previously added scheduleDict
                if ([previousSchedules isEqualToArray:daySchedule]) {
                    // comparison is equal, append day by bumping previous scheduleDict
                    NSMutableDictionary *previousScheduleDict = [[schedules lastObject] mutableCopy];
                    previousScheduleDict[@"dayEnd"] = day.date;
                    schedules[[schedules count]-1] = previousScheduleDict;
                } else {
                    // comparison is not equal add new day
                    NSDictionary *scheduleDict = @{@"dayStart": day.date,
                                                   @"dayEnd": day.date,
                                                   @"meals":daySchedule};
                    [schedules addObject:scheduleDict];
                }
            } else {
                // days are not adjacent, add new day
                NSDictionary *scheduleDict = @{@"dayStart": day.date,
                                               @"dayEnd": day.date,
                                               @"meals":daySchedule};
                [schedules addObject:scheduleDict];
            }
        }
        
        previousDay = day;  // update reference to look behind
    }
    
    self.scheduleInfo = schedules;
}

- (NSArray *) scheduleInfoForDiningDay:(DiningDay *)day
{
    
    NSSortDescriptor * sortByStartTime = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];       // TODO:: if meal does not have startTime will not be sorted correctly, spec has message as property of DiningDay, not DiningMeal
    NSArray *meals = [[day.meals array] sortedArrayUsingDescriptors:@[sortByStartTime]];
    
    NSMutableArray *mealSchedules = [NSMutableArray array];
    for (DiningMeal *meal in meals) {
        NSDictionary *mealSchedule = [self scheduleDictionaryForMeal:meal];
        [mealSchedules addObject:mealSchedule];
    }

    return mealSchedules;
}

- (NSDictionary *) scheduleDictionaryForMeal:(DiningMeal *) meal
{
    NSString *mealName = [meal.name capitalizedString];
    
    if (meal.message) {
        return @{@"mealName": mealName, @"mealSpan": meal.message};
    }
    
    NSString *startString = [self timeFormatForMealTime:meal.startTime];
    NSString *endString = [self timeFormatForMealTime:meal.endTime];
    
    NSString *mealSpan = [NSString stringWithFormat:@"%@ - %@", startString, endString];     // if meal has a message set use that instead
    return @{@"mealName": mealName, @"mealSpan": mealSpan};
}

- (NSString *) timeFormatForMealTime:(NSDate *) date
{
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:date];
    
    NSString *longFormat = @"h:mma";
    NSString *shortFormat = @"ha";
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setPMSymbol:@"pm"];
    [df setAMSymbol:@"am"];
    
    if (comps.minute == 0) {
        [df setDateFormat:shortFormat];
    } else {
        [df setDateFormat:longFormat];
    }
    return [df stringFromDate:date];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _scheduleSectionIndex) {
        return [self.scheduleInfo count];
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    cell.textLabel.textColor = [UIColor darkTextColor];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica" size:13];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == _locationSectionIndex) {
        cell.textLabel.text = @"location";
        cell.detailTextLabel.text = self.venue.location.displayDescription;
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    } else if (indexPath.section == _paymentSectionIndex) {
        cell.textLabel.text = @"payment";
        cell.detailTextLabel.text = [[self.venue.paymentMethods allObjects] componentsJoinedByString:@", "];
        
    } else {
        // schedule
        NSDictionary *rowSchedule = self.scheduleInfo[indexPath.row];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"EEE"];
        NSString *daySpan;
        if ([rowSchedule[@"dayStart"] isEqual:rowSchedule[@"dayEnd"]]) {
            daySpan = [[df stringFromDate:rowSchedule[@"dayStart"]] lowercaseString];
        } else {
            daySpan = [NSString stringWithFormat:@"%@ - %@", [[df stringFromDate:rowSchedule[@"dayStart"]] lowercaseString], [[df stringFromDate:rowSchedule[@"dayEnd"]] lowercaseString]];
        }
        cell.textLabel.text = daySpan;
        NSString *scheduleString = @"";
        for (NSDictionary *schedule in rowSchedule[@"meals"]) {
            scheduleString = [scheduleString stringByAppendingFormat:@"%@\t\t%@ \n", schedule[@"mealName"], schedule[@"mealSpan"]];
        }
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.text = scheduleString;
        
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == _locationSectionIndex) {
//        mitmobile://map/search?location
        NSString *urlString = [NSString stringWithFormat:@"mitmobile://map/search?%@", [self.venue.location.displayDescription stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSURL *url = [NSURL URLWithString:urlString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _scheduleSectionIndex) {
        return 80;  // TODO :: be a little smarter here
    }
    return 44;
}

@end
