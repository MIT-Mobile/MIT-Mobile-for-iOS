#import <Foundation/Foundation.h>

@interface MITLibrariesFormSheetGroup : NSObject
@property (nonatomic, copy) NSString *headerTitle;
@property (nonatomic, copy) NSString *footerTitle;
@property (nonatomic, strong) NSArray *elements;
@end
