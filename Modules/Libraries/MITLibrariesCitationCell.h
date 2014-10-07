#import <UIKit/UIKit.h>

@class MITLibrariesCitation;

@interface MITLibrariesCitationCell : UITableViewCell

@property (nonatomic, strong) MITLibrariesCitation *citation;

+ (void)heightWithCitation:(MITLibrariesCitation *)citation tableWidth:(CGFloat)width completion:(void (^)(CGFloat height))completion;

@end
