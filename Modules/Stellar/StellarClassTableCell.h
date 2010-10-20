
#import <Foundation/Foundation.h>
#import "StellarClass.h"

@interface StellarClassTableCell : NSObject {

}

+ (UITableViewCell *) configureCell: (UITableViewCell *)cell withStellarClass: (StellarClass *)class;
@end
