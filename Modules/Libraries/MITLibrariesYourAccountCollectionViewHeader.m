#import "MITLibrariesYourAccountCollectionViewHeader.h"

@interface MITLibrariesYourAccountCollectionViewHeader ()

@property (nonatomic, weak) IBOutlet UILabel *attributedTextLabel;

@end

@implementation MITLibrariesYourAccountCollectionViewHeader

- (void)setAttributedString:(NSAttributedString *)attributedString
{
    self.attributedTextLabel.attributedText = attributedString;
    self.backgroundColor = [UIColor whiteColor];
}

#pragma mark - Dynamic Sizing

+ (CGFloat)heightForAttributedString:(NSAttributedString *)attributedString width:(CGFloat)width
{
    MITLibrariesYourAccountCollectionViewHeader *sizingHeader = [MITLibrariesYourAccountCollectionViewHeader sizingHeader];
    [sizingHeader setAttributedString:attributedString];
    return [MITLibrariesYourAccountCollectionViewHeader heightForHeader:sizingHeader collectionViewWidth:width];
}

+ (CGFloat)heightForHeader:(MITLibrariesYourAccountCollectionViewHeader *)header collectionViewWidth:(CGFloat)width
{
    CGRect frame = header.frame;
    frame.size.width = width;
    header.frame = frame;
    
    CGFloat height = [header systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    return MAX(51, height);
}

+ (MITLibrariesYourAccountCollectionViewHeader *)sizingHeader
{
    static MITLibrariesYourAccountCollectionViewHeader *sizingHeader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesYourAccountCollectionViewHeader class]) bundle:nil];
        sizingHeader = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingHeader;
}

@end
