#import "EventListTableView.h"
#import "MITCalendarEvent.h"
#import "CalendarDetailViewController.h"
#import "MITUIConstants.h"
#import "MultiLineTableViewCell.h"

@implementation EventListTableView
{
	NSIndexPath *_previousSelectedIndexPath;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.events count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (self.searchResults) ? UNGROUPED_SECTION_HEADER_HEIGHT : 0;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *CellIdentifier = [NSString stringWithFormat:@"%d", indexPath.row];
	NSInteger randomTagNumberForLocationLabel = 1831;
    
    MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    } else {
		UIView *extraView = [cell viewWithTag:randomTagNumberForLocationLabel];
		[extraView removeFromSuperview];
	}
    
	[cell applyStandardFonts];
    
	MITCalendarEvent *event = self.events[indexPath.row];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabelNumberOfLines = 2;
    cell.textLabelLineBreakMode = UILineBreakModeTailTruncation;
    cell.textLabel.text = event.title;

	// show time only if date is shown; date plus time otherwise
	BOOL showTimeOnly = !self.searchResults && ([CalendarDataManager intervalForEventType:self.parentViewController.activeEventList fromDate:self.parentViewController.startDate forward:YES] == 86400.0);
    
    if (showTimeOnly) {
        cell.detailTextLabel.text = [event dateStringWithDateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
    } else {
        cell.detailTextLabel.text = [event dateStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
    }
        
    if (event.shortloc) {
        // right align event location
        CGSize locationTextSize = [event.shortloc sizeWithFont:[UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE]
                                                      forWidth:100.0
                                                 lineBreakMode:UILineBreakModeTailTruncation];
        
        CGFloat labelY = [self tableView:self heightForRowAtIndexPath:indexPath] - CELL_VERTICAL_PADDING - locationTextSize.height;
        CGRect locationFrame = CGRectMake(self.frame.size.width - locationTextSize.width - 20.0,
                                          labelY,
                                          locationTextSize.width,
                                          locationTextSize.height);
        
        UILabel *locationLabel = [[UILabel alloc] initWithFrame:locationFrame];
        locationLabel.lineBreakMode = UILineBreakModeTailTruncation;
        locationLabel.text = event.shortloc;
        locationLabel.textColor = cell.detailTextLabel.textColor;
        locationLabel.font = cell.detailTextLabel.font;
        locationLabel.tag = randomTagNumberForLocationLabel;
        locationLabel.highlightedTextColor = [UIColor whiteColor];
        
        [cell.contentView addSubview:locationLabel];
    }
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MITCalendarEvent *event = self.events[indexPath.row];
    
    CGFloat cellHeight = [MultiLineTableViewCell cellHeightForTableView:self
                                                                   text:event.title
                                                             detailText:@"ONELINE"
                                                          accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    CGFloat maxHeight = [MultiLineTableViewCell cellHeightForTableView:self
                                                                  text:@"TWO\nLINES"
                                                            detailText:@"ONELINE"
                                                         accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return (cellHeight > maxHeight) ? maxHeight : cellHeight;
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
