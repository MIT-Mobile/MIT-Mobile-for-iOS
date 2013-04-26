//
//  DiningRetailInfoViewController.m
//  MIT Mobile
//
//  Created by Austin Emmons on 4/25/13.
//
//

#import "DiningRetailInfoViewController.h"
#import "DiningHallDetailHeaderView.h"
#import "UIKit+MITAdditions.h"

@interface DiningRetailInfoViewController ()

@property (nonatomic, strong) DiningHallDetailHeaderView * headerView;
@end

@implementation DiningRetailInfoViewController

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
    if (!self.venueData) {
        return;
    }
    
    self.title = self.venueData[@"name"];
    
    self.headerView = [[DiningHallDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 87)];
    self.headerView.titleLabel.text = self.venueData[@"name"];
    [self.headerView.accessoryButton setImage:[UIImage imageNamed:@"global/bookmark_off"] forState:UIControlStateNormal];
    [self.headerView.accessoryButton setImage:[UIImage imageNamed:@"global/bookmark_on"] forState:UIControlStateSelected];
    [self.headerView.accessoryButton addTarget:self action:@selector(bookmarkPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    NSDictionary *scheduleDict = [self dayScheduleFromHours:self.venueData[@"hours"]];
    if ([scheduleDict[@"isOpen"] boolValue]) {
        self.headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#008800"];
    } else {
        self.headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#bb0000"];
    }
    
    NSString * scheduleString = scheduleDict[@"text"];
    self.headerView.timeLabel.text = scheduleString;
    
    self.tableView.tableHeaderView = self.headerView;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) bookmarkPressed:(UIButton *)button
{
    button.selected = !button.selected;
    
}

- (NSDictionary *) dayScheduleFromHours:(NSArray *) hours
{
    NSDate *rightNow = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"EEEE"];
    NSString *dateString = [dateFormat stringFromDate:rightNow];
    
    NSString * dateKey = [dateString lowercaseString];
    
    NSDictionary *todaysHours;
    for (NSDictionary *day in hours) {
        if ([day[@"day"] isEqualToString:dateKey]) {
            todaysHours = day;
        }
    }
    
    if (!todaysHours) {
        // closed with no hours today
        return @{@"isOpen": @NO,
                 @"text" : @"Closed for the day"};
    }
    
    if (todaysHours[@"message"]) {
        return @{@"isOpen": @YES,
          @"text" : todaysHours[@"message"]};
    }
    
    if (todaysHours[@"start_time"] && todaysHours[@"end_time"]) {
        // need to calculate if the current time is before opening, before closing, or after closing
        [dateFormat setDateFormat:@"HH:mm"];
        NSString * openString   = todaysHours[@"start_time"];
        NSString * closeString    = todaysHours[@"end_time"];
        
        NSDate *openDate = [self dateForTodayFromTimeString:openString];
        NSDate *closeDate = [self dateForTodayFromTimeString:closeString];
        
        NSLog(@"%@", openDate);
        NSLog(@"%@", closeDate);
        NSLog(@"%@", rightNow);
        
        BOOL willOpen       = ([openDate compare:rightNow] == NSOrderedDescending); // openDate > rightNow , before the open hours for the day
        BOOL currentlyOpen  = ([openDate compare:rightNow] == NSOrderedAscending && [rightNow compare:closeDate] == NSOrderedAscending);  // openDate < rightNow < closeDate , within the open hours
        BOOL hasClosed      = ([rightNow compare:closeDate] == NSOrderedDescending); // rightNow > closeDate , after the closing time for the day
        
        [dateFormat setDateFormat:@"h:mm a"];  // adjust format for pretty printing
        
        if (willOpen) {
            NSString *closedStringFormatted = [dateFormat stringFromDate:openDate];
            return @{@"isOpen": @NO,
                     @"text" : [NSString stringWithFormat:@"Opens at %@", closedStringFormatted]};

        } else if (currentlyOpen) {
            NSString *openStringFormatted = [dateFormat stringFromDate:closeDate];
            return @{@"isOpen": @YES,
                     @"text" : [NSString stringWithFormat:@"Open until %@", openStringFormatted]};
        } else if (hasClosed) {
            return @{@"isOpen": @NO,
                     @"text" : @"Closed for the day"};
        }   
    }
    
    // the just in case
    return @{@"isOpen": @NO,
             @"text" : @"Closed for the day"};
}

- (NSDate *) dateForTodayFromTimeString:(NSString *)time
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSTimeZoneCalendarUnit fromDate:[NSDate date]];
    
    NSArray *timeComponents = [time componentsSeparatedByString:@":"];
    comp.hour = [[timeComponents objectAtIndex:0] integerValue];
    comp.minute = [[timeComponents objectAtIndex:1] integerValue];
    
    return [cal dateFromComponents:comp];
}

- (NSDate *) convertDateFromGMT:(NSDate *)gmtDate
{
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:gmtDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:gmtDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    
    return [[NSDate alloc] initWithTimeInterval:interval sinceDate:gmtDate];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
