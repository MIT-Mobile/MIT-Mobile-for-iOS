
#import <Foundation/Foundation.h>
#import "StellarDetailViewController.h"
#import "MultiLineTableViewCell.h"

@interface StaffDataSource : StellarDetailViewControllerComponent <StellarDetailTableViewDelegate> {

}

@end

@interface StaffTableViewHeaderCell : MultiLineTableViewCell
{
	CGFloat height;
}

@property CGFloat height;

@end
