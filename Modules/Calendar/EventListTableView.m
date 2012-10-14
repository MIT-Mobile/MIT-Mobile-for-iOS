#import "EventListTableView.h"
#import "MITCalendarEvent.h"
#import "CalendarDetailViewController.h"
#import "MITUIConstants.h"
#import "MultiLineTableViewCell.h"

@implementation EventListTableView
@synthesize events, parentViewController, isSearchResults, searchSpan;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if (self.events != nil) {
		return [self.events count];
	}
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (isSearchResults) ? UNGROUPED_SECTION_HEADER_HEIGHT : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *titleView = nil;
    NSString *titleString = nil;
	if (isSearchResults) {
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
        
        if (searchSpan) {
            titleString = [NSString stringWithFormat:@"%@ in the next %@", titleString, searchSpan];
        }
        
        titleView = [UITableView ungroupedSectionHeaderWithTitle:titleString];
	}
    return titleView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *CellIdentifier = [NSString stringWithFormat:@"%d", indexPath.row];
	NSInteger randomTagNumberForLocationLabel = 1831;
    
    MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    } else {
		UIView *extraView = [cell viewWithTag:randomTagNumberForLocationLabel];
		[extraView removeFromSuperview];
	}
	[cell applyStandardFonts];
    
	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];

	//CGFloat maxWidth = self.frame.size.width - MULTILINE_ADJUSTMENT_ACCESSORY;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	//CGSize textSize = [event.title sizeWithFont:cell.textLabel.font];
	//CGFloat textHeight = 10.0 + (textSize.width > maxWidth ? textSize.height * 2 : textSize.height);

    cell.textLabelNumberOfLines = 2;
    cell.textLabelLineBreakMode = UILineBreakModeTailTruncation;
    cell.textLabel.text = event.title;

	// show time only if date is shown; date plus time otherwise
	BOOL showTimeOnly = !isSearchResults && ([CalendarDataManager intervalForEventType:self.parentViewController.activeEventList fromDate:self.parentViewController.startDate forward:YES] == 86400.0);
    
    if (showTimeOnly) {
        cell.detailTextLabel.text = [event dateStringWithDateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
    } else {
        cell.detailTextLabel.text = [event dateStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
    }
        
    if (event.shortloc) {
        // right align event location
        CGSize locationTextSize = [event.shortloc sizeWithFont:[UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE] forWidth:100.0 lineBreakMode:UILineBreakModeTailTruncation];
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
        [locationLabel release];
    }
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //CGFloat *constraintWidth = [MultiLineTableViewCell cellWidthForTableStyle:self accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    //if (*constraintWidth == 0) {
    
	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];
    
    CGFloat cellHeight = [MultiLineTableViewCell cellHeightForTableView:self
                                                                   text:event.title
                                                             detailText:@"ONELINE"
                                                          accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    CGFloat maxHeight = [MultiLineTableViewCell cellHeightForTableView:self
                                                                  text:@"TWO\nLINES"
                                                            detailText:@"ONELINE"
                                                         accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return (cellHeight > maxHeight) ? maxHeight : cellHeight;
    /*
	CGFloat height = CELL_TWO_LINE_HEIGHT;
    
	UIFont *font = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
	CGFloat constraintWidth = self.frame.size.width - MULTILINE_ADJUSTMENT_ACCESSORY;

	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];
	CGSize textSize = [event.title sizeWithFont:font];
	if (textSize.width > constraintWidth) {
		height += textSize.height + 2.0;
	}

	return height;
    */
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	MITCalendarEvent *event = [self.events objectAtIndex:indexPath.row];
		
	CalendarDetailViewController *detailVC = [[CalendarDetailViewController alloc] initWithNibName:nil bundle:nil];//initWithStyle:UITableViewStylePlain];
	detailVC.event = event;
	detailVC.events = self.events;

	[self.parentViewController.navigationController pushViewController:detailVC animated:YES];
	[detailVC release];
}


- (void)dealloc {
    if (searchSpan) {
        [searchSpan release];
    }
    [events release];
    events = nil;
    [super dealloc];
}


@end

