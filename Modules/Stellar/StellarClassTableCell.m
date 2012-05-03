#import "StellarClassTableCell.h"
#import "CoreDataManager.h"
#import "MITAttributedLabel.h"
#import "NSMutableAttributedString+MITAdditions.h"

@interface StellarClassTableCell ()
@property (nonatomic, assign) MITAttributedLabel *attributedLabel;
@end

@implementation StellarClassTableCell
{
    UIEdgeInsets _edgeInsets;
    StellarClass *_stellarClass;
}

@synthesize attributedLabel = _attributedLabel;

@dynamic stellarClass;
@dynamic edgeInsets;

- (id)init
{
    return [self initWithReuseIdentifier:nil];
}

- (id)initWithReuseIdentifier:(NSString *)identifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:identifier];

    if (self)
    {
        MITAttributedLabel *label = [[[MITAttributedLabel alloc] initWithFrame:self.contentView.bounds] autorelease];
        label.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                  UIViewAutoresizingFlexibleWidth);
        label.lineBreakMode = UILineBreakModeWordWrap;

        self.contentView.autoresizesSubviews = YES;
        [self.contentView addSubview:label];
        
        self.attributedLabel = label;
        
        self.edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return self;
}

- (void)dealloc
{
    self.stellarClass = nil;
    self.attributedLabel = nil;
    [super dealloc];
}

#pragma mark - Dynamic Properties
- (void)setStellarClass:(StellarClass*)class
{
    [_stellarClass release];
    _stellarClass = [class retain];
    
    if (_stellarClass)
    {
        NSMutableAttributedString *classString = [[[NSMutableAttributedString alloc] init] autorelease];
        [classString appendString:[NSString stringWithFormat:@"%@\n", self.stellarClass.name]
                         withFont:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE]
                        textColor:CELL_STANDARD_FONT_COLOR];


        [classString appendString:self.stellarClass.title
                         withFont:[UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE]
                        textColor:CELL_DETAIL_FONT_COLOR];

        self.attributedLabel.attributedString = classString;
    }
    else
    {
        self.attributedLabel.text = @"";
    }
}

- (NSManagedObject *)stellarClass
{
    return _stellarClass;
}

- (void)setEdgeInsets:(UIEdgeInsets)anEdgeInsets
{
    _edgeInsets = anEdgeInsets;
    [self setNeedsLayout];
}

- (UIEdgeInsets)edgeInsets
{
    return _edgeInsets;
}

#pragma mark - Overridden Methods
- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat heightDiff = CGRectGetHeight(self.bounds) - CGRectGetHeight(self.contentView.frame);
    heightDiff += (CGFloat)(ceil(self.edgeInsets.top + self.edgeInsets.bottom));

    CGSize labelSize = self.contentView.bounds.size;
    labelSize.width -= (CGFloat)(ceil(self.edgeInsets.left + self.edgeInsets.right));

    CGSize fitSize = [self.attributedLabel sizeThatFits:labelSize];

    return CGSizeMake(size.width, fitSize.height + heightDiff);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect labelFrame = self.contentView.bounds;
    labelFrame.origin.x += (CGFloat)(ceil(self.edgeInsets.left));
    labelFrame.origin.y += (CGFloat)(ceil(self.edgeInsets.top));
    labelFrame.size.height -= (CGFloat)(ceil(self.edgeInsets.top + self.edgeInsets.bottom));
    labelFrame.size.width -= (CGFloat)(ceil(self.edgeInsets.left + self.edgeInsets.right));

    labelFrame = CGRectStandardize(labelFrame);
    self.attributedLabel.frame = labelFrame;
}

- (void)prepareForReuse
{
    self.stellarClass = nil;
    self.attributedLabel.text = nil;
}
@end
