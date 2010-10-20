
#import "InfoDataSource.h"
#import "Foundation+MITAdditions.h"
#import "MultiLineTableViewCell.h"
#import "UIKit+MITAdditions.h"
#import "UITableViewCell+MITUIAdditions.h"
#import "MITUIConstants.h"

#define TIMES 0
#define DESCRIPTION 1

#define DESCRIPTION_PADDING 18


@implementation InfoDataSource

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 2;
}
 
- (NSString *) locationAndTime: (NSUInteger)index {
	StellarClassTime *classTime = [self.viewController.times objectAtIndex:index];
	if(![classTime.location length]) {
		// no location set
		return [NSString stringWithFormat:@"%@: %@", classTime.title, classTime.time];
	} else {
		return [NSString stringWithFormat:@"%@: %@ (%@)", classTime.title, classTime.time, classTime.location];
	}
}
		

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
	MultiLineTableViewCell *cell = nil;
	switch (indexPath.section) {
			
		case TIMES:
			cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarTimes"];
			if(cell == nil) {
				cell = [[[StellarLocationTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarTimes"] autorelease];
				[cell applyStandardFonts];
				makeCellWhite(cell);
			}

			StellarClassTime *classTime = [self.viewController.times objectAtIndex:indexPath.row];
			if([classTime.location length]) {
				cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			} else {
				cell.accessoryView = nil;
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			cell.textLabel.text = [self locationAndTime:indexPath.row];
			break;
			
			
		case DESCRIPTION:
			cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarDescription"];
			if(cell == nil) {
				cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarDescription"] autorelease];
				cell.textLabel.text = @"Description:";
				[cell applyStandardFonts];
				makeCellWhite(cell);
				cell.detailTextLabel.textColor = CELL_STANDARD_FONT_COLOR;
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.topPadding = DESCRIPTION_PADDING;
			}

			cell.detailTextLabel.text = self.viewController.stellarClass.blurb;
			break;
			
	}
	return cell;	
}

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	switch (section) {			
		case TIMES:
			return [self.viewController.times count];
		case DESCRIPTION:
			return 1;			
	}
	return 0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case TIMES:
			return [MultiLineTableViewCell
				cellHeightForTableView:tableView
				main:[self locationAndTime:indexPath.row]
				detail:nil
				widthAdjustment: 26];
			
		case DESCRIPTION:
			return [MultiLineTableViewCell 
					cellHeightForTableView:tableView
					main:@"Description"
					detail:self.viewController.stellarClass.blurb
					accessoryType:UITableViewCellAccessoryNone
					isGrouped:NO
					topPadding:DESCRIPTION_PADDING]; 
	}
	return 0;
} 

- (CGFloat) heightOfTableView: (UITableView *)tableView {
	NSInteger timeRows = [self.viewController.times count];
	CGFloat height = 0;
	NSInteger rowsIndex;
	for(rowsIndex=0; rowsIndex < timeRows; rowsIndex++) {
		height = height + [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:rowsIndex inSection:TIMES]];
	}
	
	height = height + [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:DESCRIPTION]];
	return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == TIMES) {
		StellarClassTime *classTime = [self.viewController.times objectAtIndex:indexPath.row];
		if([classTime.location length]) {
			[[UIApplication sharedApplication] openURL:[NSURL internalURLWithModuleTag:CampusMapTag path:@"search" query:classTime.location]];
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end

@implementation StellarLocationTableViewCell

- (void) layoutSubviews {
	[super layoutSubviews];
	CGRect frame = self.accessoryView.frame;
	frame.origin.x = 287;
	self.accessoryView.frame = frame;
}

@end


