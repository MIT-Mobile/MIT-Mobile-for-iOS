
#import <Foundation/Foundation.h>
#import "StellarDetailViewController.h"

@interface NewsDataSource : StellarDetailViewControllerComponent <StellarDetailTableViewDelegate> {
	NSDateFormatter *dateFormatter;
}

@end

@interface NewsTeaserTableViewCell : UITableViewCell {
	UILabel *dateTextLabel;
}
@property (nonatomic, retain) UILabel *dateTextLabel;
@end
