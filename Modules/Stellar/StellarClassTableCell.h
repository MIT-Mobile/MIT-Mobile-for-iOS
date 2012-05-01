#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "StellarClass.h"
#import "MultiLineTableViewCell.h"

@interface StellarClassTableCell : UITableViewCell
@property (nonatomic, strong) NSManagedObjectID *stellarClassID;
@property (nonatomic) UIEdgeInsets edgeInsets;

- (id)initWithReuseIdentifier:(NSString *)identifier;
@end
