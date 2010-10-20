
#import "StellarClassTableCell.h"
#import "UITableViewCell+MITUIAdditions.h"


@implementation StellarClassTableCell

+ (UITableViewCell *) configureCell: (UITableViewCell *)cell withStellarClass: (StellarClass *)class {
	NSString *name;
	if([class.name length]) {
		name = class.name;
	} else {
		name = class.masterSubjectId;
	}
	cell.textLabel.text = name;
	
	cell.detailTextLabel.text = class.title;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	[cell applyStandardFonts];
	return cell;
}
@end
