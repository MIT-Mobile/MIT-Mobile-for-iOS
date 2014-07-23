#import "EventListTableView.h"
#import "MITCalendarEvent.h"
#import "CalendarDetailViewController.h"
#import "MITUIConstants.h"
#import "MITMultiLineTableViewCell.h"
#import "UITableView+DynamicSizing.h"
#import "MITEventListTableViewCell.h"

@interface EventListTableView () <UITableViewDataSourceDynamicSizing>

@end

@implementation EventListTableView
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self registerNib:[UINib nibWithNibName:@"MITEventListTableViewCell" bundle:nil] forDynamicCellReuseIdentifier:@"Cell"];
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self registerNib:[UINib nibWithNibName:@"MITEventListTableViewCell" bundle:nil] forDynamicCellReuseIdentifier:@"Cell"];
    }

    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.events count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *titleString = nil;
    
	if (self.searchResults) {
		NSUInteger numResults = [self.events count];
		switch (numResults) {
			case 0:
                titleString = @"Nothing found";
				break;
			case 1:
                titleString = @"1 found";
				break;
			default:
                titleString = [NSString stringWithFormat:@"%d found", numResults];
				break;
		}
        
        if (self.searchSpan) {
            titleString = [NSString stringWithFormat:@"%@ in the next %@", titleString, self.searchSpan];
        }
    }
    return titleString;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView minimumHeightForCellWithReuseIdentifier:@"Cell" atIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    MITMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    [self tableView:self configureCell:cell forRowAtIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITEventListTableViewCell *multilineCell = (MITEventListTableViewCell*)cell;

    MITCalendarEvent *event = self.events[indexPath.row];
    multilineCell.headlineLabel.text = event.title;

	// show time only if date is shown; date plus time otherwise
    NSTimeInterval eventInterval = [MITCalendarDataManager intervalForEventType:self.parentViewController.activeEventList
                                                                    fromDate:self.parentViewController.startDate
                                                                     forward:YES];

    NSMutableString *bodyText = [[NSMutableString alloc] init];
    if (!self.searchResults && (eventInterval == 86400.0)) {
        [bodyText appendString:[event dateStringWithDateStyle:NSDateFormatterNoStyle
                                                    timeStyle:NSDateFormatterShortStyle
                                                    separator:@" "]];
    } else {
        [bodyText appendString:[event dateStringWithDateStyle:NSDateFormatterShortStyle
                                                    timeStyle:NSDateFormatterShortStyle
                                                    separator:@" "]];
    }

    multilineCell.bodyLabel.text = bodyText;
    multilineCell.rightBodyLabel.text = event.shortloc;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	MITCalendarEvent *event = self.events[indexPath.row];
		
	CalendarDetailViewController *detailVC = [[CalendarDetailViewController alloc] initWithNibName:nil bundle:nil];
	detailVC.event = event;
	detailVC.events = self.events;

	[self.parentViewController.navigationController pushViewController:detailVC animated:YES];
}

@end
