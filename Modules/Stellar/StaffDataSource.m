
#import "StaffDataSource.h"
#import "MultiLineTableViewCell.h"
#import "MIT_MobileAppDelegate+ModuleList.h"
#import "PeopleModule.h"
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"

#define INSTRUCTORS_PADDING 15
#define TAS_PADDING 23
#define HEADER_HEIGHT 24

#define INSTRUCTORS 0
#define TAS 1

#define HEADER_FONT_COLOR [UIColor colorWithHexString:@"#808080"]

@implementation StaffDataSource

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 2;
}

- (UIView *) sectionHeaderForTableView: (UITableView *)tableView reuseIdentifier: (NSString *)reuseIdentifier title: (NSString *)title topPadding: (CGFloat)topPadding {
	StaffTableViewHeaderCell *headerCell;
	headerCell = (StaffTableViewHeaderCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if(headerCell == nil) {
		headerCell = [[[StaffTableViewHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
		[headerCell applyStandardFonts];
		headerCell.textLabel.text = title;
		headerCell.textLabel.textColor = HEADER_FONT_COLOR;
		headerCell.selectionStyle = UITableViewCellSelectionStyleNone;
		headerCell.topPadding = topPadding;
		headerCell.height = topPadding + HEADER_HEIGHT;
	}
	return headerCell;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection: (NSInteger)section {
	UIView *header = nil;
	switch (section) {
		case INSTRUCTORS:
			header = [self sectionHeaderForTableView:tableView reuseIdentifier:@"StellarInstructorsHeader" title:@"Instructors" topPadding:INSTRUCTORS_PADDING];
			break;
		case TAS:
			header = [self sectionHeaderForTableView:tableView reuseIdentifier:@"StellarTAsHeader" title:@"TAs" topPadding:TAS_PADDING];
			break;
	}
	
	// return nil for empty sections                                                                                                                                               
	if([self tableView:tableView numberOfRowsInSection:section]) {
		return header;
	} else {
		return nil;
	}
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection: (NSInteger)section {
	switch (section) {
		case INSTRUCTORS:
			return INSTRUCTORS_PADDING + HEADER_HEIGHT;
			
		case TAS:
			return TAS_PADDING + HEADER_HEIGHT;
	}
	return 0;
}

- (CGFloat) heightOfTableView: (UITableView *)tableView {
	CGFloat height;
	height = tableView.rowHeight * ([self.viewController.instructors count] + [self.viewController.tas count]);
	
	if([self.viewController.instructors count]) {
		height = height + INSTRUCTORS_PADDING + HEADER_HEIGHT;
	}
	
	if([self.viewController.tas count]) {
		height = height + TAS_PADDING + HEADER_HEIGHT;
	}
	return height;
}

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	switch (section) {
		case INSTRUCTORS:
			return [self.viewController.instructors count];
		case TAS:
			return [self.viewController.tas count];
	}
	
	return 0;
}

- (StellarStaffMember *) staffMemberForIndexPath: (NSIndexPath *)indexPath {
	NSArray *staff = nil;
	switch (indexPath.section) {
		case INSTRUCTORS:
			staff = self.viewController.instructors;
			break;
		case TAS:
			staff = self.viewController.tas;
			break;
	}
	return (StellarStaffMember *)[staff objectAtIndex:indexPath.row];
}
	
	
- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StellarStaff"];
	if(cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StellarStaff"] autorelease];
		cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPeople];
		[cell applyStandardFonts];
		makeCellWhite(cell);
	}
	
	cell.textLabel.text = [self staffMemberForIndexPath:indexPath].name;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *name = [self staffMemberForIndexPath:indexPath].name;
	
	if (name != nil) {
		name = [name stringByReplacingOccurrencesOfString:@"." withString:@""]; //remove periods which throw off people searches
        [[UIApplication sharedApplication] openURL:[NSURL internalURLWithModuleTag:DirectoryTag path:@"search" query:name]];
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end

@implementation StaffTableViewHeaderCell
@synthesize height;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		self.backgroundColor = [UIColor whiteColor];
	}
	return self;
}
				
- (void) drawRect: (CGRect)Rect {
	[super drawRect:Rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1);
	[[UIColor lightGrayColor] setStroke];
	
	CGPoint points[] = {CGPointMake(0, height), CGPointMake(Rect.size.width, height)};
	CGContextStrokeLineSegments(context, points, 2);
}

@end
