#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "StellarClass.h"
#import "MultiLineTableViewCell.h"

@interface StellarClassTableCell : UITableViewCell
@property (nonatomic, strong) StellarClass *stellarClass;
@property (nonatomic) UIEdgeInsets edgeInsets;

- (id)initWithReuseIdentifier:(NSString *)identifier;
@end
