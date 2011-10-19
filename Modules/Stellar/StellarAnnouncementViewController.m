
#import "StellarAnnouncementViewController.h"
#import "MultiLineTableViewCell.h"
#import "MITUIConstants.h"
#import "UIKit+MITAdditions.h"
#define titleRow 0
#define textRow 1
#define textWidth 290
#define textViewHorizontalPadding 16.0
#define textViewVerticalPadding 20.0
#define textViewTag 34689

@implementation StellarAnnouncementViewController

- (id) initWithAnnouncement: (StellarAnnouncement *)anAnnouncement rowIndex:(NSUInteger)index{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		announcement = [anAnnouncement retain];
		dateFormatter = [NSDateFormatter new];
		[dateFormatter setDateFormat:@"EEEE, MMMM d, y @ H:mm"];
		titleFont = [[UIFont fontWithName:BOLD_FONT size:20.0] retain];
		dateFont = [[UIFont fontWithName:STANDARD_FONT size:14.0] retain]; 
		textFont = [[UIFont fontWithName:STANDARD_FONT size:STANDARD_CONTENT_FONT_SIZE] retain];
		url = [[MITModuleURL alloc] initWithTag:StellarTag];
		rowIndex = index;
	}
	return self;
}

- (void) viewDidLoad {
    [MultiLineTableViewCell setNeedsRedrawing:YES];
	self.tableView.allowsSelection = NO;
	self.title = @"News";
	[self.tableView applyStandardColors];
	[url setPathWithViewController:self
                         extension:[NSString stringWithFormat:@"%i", rowIndex]];
}

- (void) viewDidAppear:(BOOL)animated {
	[url setAsModulePath];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if([announcement.text length]) {
		return 2;
	} else {
		return 1;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    static NSString *titleCellIdentifier = @"StellarAnnouncementTitleCell";
	static NSString *contentCellIdentifier = @"StellarAnnouncementcontentCell";
	UITableViewCell *cell = nil;
	
	switch (indexPath.row) {
		case titleRow:
			cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:titleCellIdentifier];
			if(cell == nil) {
				cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:titleCellIdentifier] autorelease];
			}
            //cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.font = titleFont;
			cell.textLabel.text = announcement.title;
			cell.detailTextLabel.font = dateFont;
			cell.detailTextLabel.text = [dateFormatter stringFromDate:announcement.pubDate];
            break;
			
		case textRow:
			// will use a TextView for the announcement (to have added benefits such as copy/select)
			cell = [tableView dequeueReusableCellWithIdentifier:contentCellIdentifier];
			if(cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:contentCellIdentifier] autorelease];
			}
			
            UITextView *textView = (UITextView *)[cell viewWithTag:textViewTag];
            if (textView == nil) {
            
                // a little more padding on the sides
                CGRect frame = cell.frame;
                frame.origin.x += 2.0;
                frame.size.width = textWidth;
                
                // use a UITextView to get automatic linking of URLs and phone numbers
                textView = [[UITextView alloc] initWithFrame: frame];
                textView.scrollEnabled = NO;
                textView.editable = NO;
                textView.dataDetectorTypes = UIDataDetectorTypeAll;
                textView.backgroundColor = [UIColor clearColor];
                textView.font = textFont;
                textView.textColor = STANDARD_CONTENT_FONT_COLOR;
                textView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
                textView.tag = textViewTag;
                [cell.contentView addSubview:textView];
                [textView release];
            }
            textView.text = announcement.text;
            
			break;
	}	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.row) {
		case titleRow:
            
            return [MultiLineTableViewCell cellHeightForTableView:tableView
                                                             text:announcement.title
                                                       detailText:[dateFormatter stringFromDate:announcement.pubDate]
                                                         textFont:titleFont
                                                       detailFont:dateFont
                                                    accessoryType:UITableViewCellAccessoryNone];
            /*
			return [MultiLineTableViewCell 
					cellHeightForTableView:tableView
					main:announcement.title
					mainFont:titleFont
					detail:[dateFormatter stringFromDate:announcement.pubDate]
					detailFont:dateFont
					accessoryType:UITableViewCellAccessoryNone
					isGrouped:YES]; 
            */
		case textRow:
			return [announcement.text sizeWithFont:textFont constrainedToSize:CGSizeMake(textWidth-textViewHorizontalPadding, MAXFLOAT)].height + textViewVerticalPadding;
	}
	return 0;
}

- (void)dealloc {
	[url release];
	[dateFormatter release];
	[titleFont release];
	[dateFont release];
	[textFont release];
	[announcement release];
    [super dealloc];
}


@end

