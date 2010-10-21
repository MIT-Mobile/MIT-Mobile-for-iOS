
#import <Foundation/Foundation.h>
#import "StellarDetailViewController.h"
#import "MultiLineTableViewCell.h"

@interface NewsDataSource : StellarDetailViewControllerComponent <StellarDetailTableViewDelegate> {
	NSDateFormatter *dateFormatter;
}

@end

@interface NewsTeaserTableViewCell : MultiLineTableViewCell {
	UILabel *dateTextLabel;
}
@property (nonatomic, retain) UILabel *dateTextLabel;
@end
