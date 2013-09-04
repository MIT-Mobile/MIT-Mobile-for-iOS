#import "EventListTableView.h"
#import "MITCalendarEvent.h"
#import "CalendarDetailViewController.h"
#import "MITUIConstants.h"
#import "MITMultiLineTableViewCell.h"

static NSInteger MITEventListCellLocationLabelTag = 0xBAFF;

@implementation EventListTableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.events count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *titleView = nil;
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
        
        titleView = [UITableView ungroupedSectionHeaderWithTitle:titleString];
	}
    
    return titleView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    static UITableViewCell *templateCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        templateCell = [self tableView:nil cellForRowAtIndexPath:indexPath];
    });

    [self configureCell:templateCell
            atIndexPath:indexPath
           forTableView:tableView];

    CGSize cellSize = [templateCell sizeThatFits:CGSizeMake(CGRectGetWidth(tableView.bounds), CGFLOAT_MAX)];
    return cellSize.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    MITMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[MITMultilineTableViewCell alloc] init];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    cell.headlineLabel.numberOfLines = 2;
    cell.headlineLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    cell.bodyLabel.numberOfLines = 1;

    UILabel *shortLocationLabel = (UILabel*)[cell.contentView viewWithTag:MITEventListCellLocationLabelTag];
    if (!shortLocationLabel) {
        shortLocationLabel = [[UILabel alloc] init];
        shortLocationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        shortLocationLabel.backgroundColor = [UIColor clearColor];
        shortLocationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        shortLocationLabel.numberOfLines = 1;
        shortLocationLabel.highlightedTextColor = [UIColor whiteColor];
        shortLocationLabel.textColor = cell.bodyLabel.textColor;
        shortLocationLabel.textAlignment = NSTextAlignmentRight;
        shortLocationLabel.font = cell.bodyLabel.font;
        shortLocationLabel.tag = MITEventListCellLocationLabelTag;

        [cell.contentView addSubview:shortLocationLabel];

        NSDictionary *constraintViews = @{@"bodyLabel" : cell.bodyLabel,
                                          @"headlineLabel" : cell.headlineLabel,
                                          @"locationLabel" : shortLocationLabel};

        [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[bodyLabel]-[locationLabel(<=112.)]-(4)-|"
                                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                                 metrics:nil
                                                                                   views:constraintViews]];
        [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[headlineLabel][locationLabel]"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:constraintViews]];
    }

    [self configureCell:cell
            atIndexPath:indexPath
           forTableView:tableView];

    return cell;
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath forTableView:(UITableView*)tableView
{
    MITMultilineTableViewCell *multilineCell = (MITMultilineTableViewCell*)cell;

    MITCalendarEvent *event = self.events[indexPath.row];
    multilineCell.headlineLabel.text = event.title;

	// show time only if date is shown; date plus time otherwise
    NSTimeInterval eventInterval = [CalendarDataManager intervalForEventType:self.parentViewController.activeEventList
                                                                    fromDate:self.parentViewController.startDate
                                                                     forward:YES];

    NSMutableString *bodyText = [[NSMutableString alloc] init];
    //if ([event.shortloc length]) {
    //    [bodyText appendFormat:@"%@\n",event.shortloc];
    //}

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

    UILabel *locationLabel = (UILabel*)[multilineCell.contentView viewWithTag:MITEventListCellLocationLabelTag];
    locationLabel.text = event.shortloc;
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
