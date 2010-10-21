#import <Foundation/Foundation.h>
#import "StellarClass.h"
#import "MultiLineTableViewCell.h"

@interface StellarClassTableCell : MultiLineTableViewCell {

}

- (id) initWithReusableCellIdentifier: (NSString *)identifer;

+ (UITableViewCell *) configureCell: (UITableViewCell *)cell withStellarClass: (StellarClass *)class;

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView class: (StellarClass *)stellarClass;
@end
