
#import "NewsDataSource.h"
#import "StellarAnnouncement.h"
#import "StellarAnnouncementViewController.h"
#import "MITUIConstants.h"
#import "UIKit+MITAdditions.h"

#define announcementsLoadingMessage @"Announcements loading..."
#define noAnnouncementsMessage @"No announcements"
#define failedToLoadMessage @"Failed to load announcements"
#define DISCLAIMER_HEIGHT 80

@implementation NewsDataSource

- (id) init {
	self = [super init];
	if (self) {
		dateFormatter = [NSDateFormatter new];
		[dateFormatter setDateFormat:@"(M/d H:mm)"];		
	}
	return self;
}

- (void) dealloc {
	[dateFormatter release];
	[super dealloc];
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	// always return at least one row for the disclaimer message
	return MAX([self.viewController.news count], 1);
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	NewsTeaserTableViewCell *newsCell = nil;
    //MultiLineTableViewCell *newsCell = nil;
	if([self.viewController.news count]) {
		newsCell = (NewsTeaserTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarNewsTeaser"];
        //newsCell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarNewsTeaser"];
        
		if(newsCell == nil) {
			newsCell = [[[NewsTeaserTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarNewsTeaser"] autorelease];
            //newsCell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarNewsTeaser"] autorelease];
			
            [newsCell applyStandardFonts];
			makeCellWhite(newsCell);
			//newsCell.dateTextLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
			//newsCell.dateTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
			newsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            /*
            UILabel *dateTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 16)];
			dateTextLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
			dateTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
            dateTextLabel.highlightedTextColor = [UIColor whiteColor];
            dateTextLabel.tag = 678;
            [[newsCell contentView] addSubview:dateTextLabel];
            [dateTextLabel release];
            */
		}	
		
		StellarAnnouncement *newsItem = [self.viewController.news objectAtIndex:indexPath.row];
		newsCell.textLabel.text = newsItem.title;
		newsCell.detailTextLabel.text = newsItem.text;
        newsCell.detailTextLabelNumberOfLines = 1;
        newsCell.detailTextLabelLineBreakMode = UILineBreakModeTailTruncation;
		newsCell.dateTextLabel.text = [dateFormatter stringFromDate:newsItem.pubDate];

        //UILabel *dateTextLabel = (UILabel *)[newsCell viewWithTag:678];
        
        /*
        CGRect frame = newsCell.detailTextLabel.frame;
        frame.size = [newsCell.detailTextLabel.text sizeWithFont:newsCell.detailTextLabel.font					  
                                                        forWidth:279 - 85  // 279 is total width for content and 85 is the maximum width of the date
                                                   lineBreakMode:UILineBreakModeTailTruncation];

        newsCell.detailTextLabel.frame = frame;
        
        if(frame.origin.x < 1) {
            // work around for strange behavior on iPhone 3.1.2
            frame.origin.x = 10;
        }
        */
        
        /*
        CGRect frame = dateTextLabel.frame;
        CGFloat datePadding = [newsCell.detailTextLabel.text length] ? 3.0 : 0.0;
        frame.origin.y = newsCell.detailTextLabel.frame.origin.y;
        frame.origin.x += newsCell.detailTextLabel.frame.size.width + datePadding + 10; // 10 is left margin
        //frame.size.width = 85;

		dateTextLabel.frame = frame;
        */
        
		cell = newsCell;
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"StellarNewsDisclaimer"];
		if(cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StellarNewsDisclaimer"] autorelease];
			[cell applyStandardFonts];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			makeCellWhite(cell);
		}		
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.accessoryView = nil;
		
		switch (self.viewController.loadingState) {
			case StellarNewsLoadingInProcess:
				cell.textLabel.text = announcementsLoadingMessage;
				UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
				cell.accessoryView = spinner;
				[spinner startAnimating];
				[spinner release];
				break;
			case StellarNewsLoadingSucceeded:
				cell.textLabel.text = noAnnouncementsMessage;
				break;
			case StellarNewsLoadingFailed:
				cell.textLabel.text = failedToLoadMessage;
				break;
		}
	}
	return cell;	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	// if we have no items will just have a cell with some disclaimer message
	if([self.viewController.news count] == 0) {
		return DISCLAIMER_HEIGHT;
	}
	
    return [MultiLineTableViewCell cellHeightForTableView:tableView
                                                     text:((StellarAnnouncement *)[self.viewController.news objectAtIndex:indexPath.row]).title
                                               detailText:@"a line"
                                            accessoryType:UITableViewCellAccessoryDisclosureIndicator]
        + 4.0;
    /*
	return [MultiLineTableViewCell 
		cellHeightForTableView:tableView
		main:((StellarAnnouncement *)[self.viewController.news objectAtIndex:indexPath.row]).title
		detail:@"a line"        
		accessoryType:UITableViewCellAccessoryDisclosureIndicator
		isGrouped:NO] + 4; 
    */
}

- (CGFloat) heightOfTableView: (UITableView *)tableView {
	NSInteger newsRows = [self.viewController.news count];
	if(newsRows == 0) {
		return DISCLAIMER_HEIGHT;
	} else {
		NSInteger rowsIndex;
		CGFloat height = 0;
		for(rowsIndex=0; rowsIndex < newsRows; rowsIndex++) {
			height = height + [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:rowsIndex inSection:0]];
		}
		return height;
	}
}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	if(indexPath.row+1 > [self.viewController.news count]) {
		// no annoucements to select, (user must have selected the disclaimer message)
		return;
	}
	
	UIViewController *announcementViewController = [[StellarAnnouncementViewController alloc]
		initWithAnnouncement:(StellarAnnouncement *)[self.viewController.news objectAtIndex:indexPath.row]
		rowIndex:indexPath.row
	];

	[self.viewController.navigationController
		pushViewController:announcementViewController
		animated:YES];
	
	[announcementViewController release];
}
@end

@implementation NewsTeaserTableViewCell
@synthesize dateTextLabel;

- (id)initWithStyle:(UITableViewCellStyle)cellStyle reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:cellStyle reuseIdentifier:reuseIdentifier];
    if (self) {		
		dateTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 16)];		
		[[self contentView] addSubview:dateTextLabel];
		dateTextLabel.highlightedTextColor = [UIColor whiteColor];
		[dateTextLabel release];
    }
    return self;
}

- (void) layoutSubviews {
	/*
    CGSize labelSize = [self.textLabel.text sizeWithFont:self.textLabel.font 
                                       constrainedToSize:CGSizeMake(self.textLabel.frame.size.width, 600.0) 
                                           lineBreakMode:UILineBreakModeWordWrap];
    
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, CELL_VERTICAL_PADDING, self.textLabel.frame.size.width, labelSize.height);
    self.textLabel.numberOfLines = 0;
    */
    dateTextLabel.font = self.detailTextLabel.font;
    dateTextLabel.textColor = self.detailTextLabel.textColor;
	[super layoutSubviews];
    
    
	//[MultiLineTableViewCell layoutLabel:self.textLabel atHeight:0];// topPadding:[MultiLineTableViewCell defaultTopPadding]];
	
	// layout the detail label
	CGRect detailFrame = self.detailTextLabel.frame;
	//detailFrame.origin.y = self.textLabel.frame.size.height + CELL_VERTICAL_PADDING; // + [MultiLineTableViewCell defaultTopPadding];
    
	detailFrame.size.width = [self.detailTextLabel.text
		sizeWithFont:self.detailTextLabel.font					  
		forWidth:279 - 85  // 279 is total width for content and 85 is the maximum width of the date
		lineBreakMode:UILineBreakModeTailTruncation].width;
	self.detailTextLabel.frame = detailFrame;
	
	// layout the date label
	CGRect textFrame = dateTextLabel.frame;
	textFrame.origin.y = detailFrame.origin.y;
	textFrame.size.width = [dateTextLabel.text sizeWithFont:dateTextLabel.font].width;

	CGFloat datePadding = 0.0;
	if([self.detailTextLabel.text length]) {
		datePadding = 3.0;
	}
		
	textFrame.origin.x = detailFrame.origin.x + detailFrame.size.width + datePadding;
	if(textFrame.origin.x < 1) {
		// work around for strange behavior on iPhone 3.1.2
		textFrame.origin.x = 10;
	}
	dateTextLabel.frame = textFrame;	
}
@end

