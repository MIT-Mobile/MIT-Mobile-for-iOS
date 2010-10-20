#import <UIKit/UIKit.h>

/*
 * initialize these with UITableViewCellStyleDefault
 * and use secondaryTextLabel instead of detailTextLabel
 *
 */


@interface SecondaryGroupedTableViewCell : UITableViewCell {

	UILabel *secondaryTextLabel;
	
}

@property (nonatomic, retain) UILabel *secondaryTextLabel;

@end
