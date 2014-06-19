#import "MITNewsPadLayout.h"
#import "UIImageView+WebCache.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"
#import "MITNewsConstants.h"

@interface MITNewsPadLayout ()

@property (nonatomic, strong) NSDictionary *layoutInfo;
@property (nonatomic) CGFloat collectionViewHeight;

@property (nonatomic) UIEdgeInsets itemInsets;

@end

@implementation MITNewsPadLayout

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
#warning not used yet
    self.itemInsets = UIEdgeInsetsMake(10, 30, 10, 30);
}

#pragma mark - Layout

- (void)prepareLayout
{
    
    self.collectionViewHeight = 0;
    NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
    
    NSInteger sectionCount = [self.collectionView numberOfSections];
    NSInteger rowCount = 0;
    UIInterfaceOrientation  orientation = [UIDevice currentDevice].orientation;
#warning used to figure out how many rows per layout
    if (orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown) {
        rowCount = 3;
    } else {
        rowCount = 4;
    }
    //spce between cells
    CGFloat horizontalSpace = 60;

    CGFloat widthOfSmallCell = (self.collectionView.frame.size.width - (horizontalSpace * (rowCount+1)))/rowCount;
    CGFloat widthOfLargeCell = widthOfSmallCell * 2 + horizontalSpace;
    //space for header.
    CGFloat yOrigin = 65;
    
    for (NSInteger section = 0; section < sectionCount; section++) {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
#warning right margin / make individual sections later instead of one big NSMutableDictionary of cellLayoutInfo
        
        CGFloat xOrigin = 60;
        //max height of current row's cells so next row are all aligned
        CGFloat maxHeight = 0;
       // CGFloat previousX = 0;
        BOOL comeUpWithAName = FALSE;

        for (NSInteger item = 0; item < itemCount; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *itemAttributes =
            [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            if (section == 0) {
                //if Jumbo Cell
                if (item == 0) {
                    UICollectionViewLayoutAttributes * layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:MITNewsCollectionReusableHeaderWithCellIdentifier withIndexPath:indexPath];
                    layoutAttributes.frame = CGRectMake(xOrigin, 10, self.collectionView.frame.size.width, 50);
                    cellLayoutInfo[[NSString stringWithFormat:@"%@%d",MITNewsCollectionReusableHeaderWithCellIdentifier,indexPath.section]] = layoutAttributes;
                    
                    itemAttributes.frame = CGRectMake(xOrigin, yOrigin, widthOfLargeCell, [self calculateHeightOfCellFromStory:[self.stories objectAtIndex:indexPath.row] withCellWidth:widthOfLargeCell isJumboCell:YES]);
                    xOrigin += widthOfLargeCell + horizontalSpace;
                } else  {
                    itemAttributes.frame = [self findNextAvailableOpeningForCell:CGRectMake(xOrigin, yOrigin, widthOfSmallCell, [self calculateHeightOfCellFromStory:[self.stories objectAtIndex:indexPath.row] withCellWidth:widthOfSmallCell isJumboCell:NO]) againstFrames:cellLayoutInfo withYOrigin:maxHeight isFeatured:YES];

                    yOrigin = itemAttributes.frame.origin.y;
                    xOrigin = itemAttributes.frame.size.width + itemAttributes.frame.origin.x + horizontalSpace;

                    if (maxHeight < itemAttributes.frame.size.height + itemAttributes.frame.origin.y + 10) {
                        maxHeight = itemAttributes.frame.size.height + itemAttributes.frame.origin.y + 10;
                    }
                }

                
            } else {
                if (indexPath.row == 0) {
                    yOrigin += widthOfSmallCell + horizontalSpace + 15;
                    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:MITNewsCollectionReusableHeaderWithCellIdentifier  withIndexPath:indexPath];
                    layoutAttributes.frame = CGRectMake(40, yOrigin - 50, self.collectionView.frame.size.width, 50);
                    cellLayoutInfo[[NSString stringWithFormat:@"%@%d",MITNewsCollectionReusableHeaderWithCellIdentifier,indexPath.section]] = layoutAttributes;
                    
                }
                itemAttributes.frame = CGRectMake(xOrigin, yOrigin, widthOfSmallCell, widthOfSmallCell);
                xOrigin += + widthOfSmallCell + horizontalSpace;
            }
            cellLayoutInfo[indexPath] = itemAttributes;
            if (self.collectionViewHeight < itemAttributes.frame.origin.y + itemAttributes.frame.size.height + 10) {
                self.collectionViewHeight = itemAttributes.frame.origin.y + itemAttributes.frame.size.height + 10;
            }
        }
    }
    self.layoutInfo = cellLayoutInfo;
}

- (CGRect)findNextAvailableOpeningForCell:(CGRect)cellFrame againstFrames:(NSDictionary *)dictionary withYOrigin:(CGFloat)yOrigin isFeatured:(BOOL)featured
{
    CGSize displayArea = self.collectionView.bounds.size;
    while (TRUE) {
        if (cellFrame.origin.x + cellFrame.size.width > displayArea.width) {
            CGRect frame = cellFrame;
            frame.origin.y = yOrigin;
            frame.origin.x = 60;
            cellFrame = frame;
        } else {
            BOOL intersectsRect = FALSE;
            
            NSInteger numbeOfSameXOrigins = 0;
            for (NSIndexPath *key in dictionary) {
                UICollectionViewLayoutAttributes *cellAttributes = dictionary[key];
                
                if(CGRectIntersectsRect(cellAttributes.frame, cellFrame)) {
                    CGRect frame = cellFrame;
                    frame.origin.x += cellFrame.size.width + 60;
                    cellFrame = frame;
                    intersectsRect = TRUE;
                    break;
                }
                if (cellAttributes.frame.origin.x == cellFrame.origin.x) {
                    numbeOfSameXOrigins++;
                }
            }
            if (numbeOfSameXOrigins == 1 && [dictionary count] == 3 && featured) {

                if (cellFrame.size.height + cellFrame.origin.y < self.collectionViewHeight && [UIDevice currentDevice].orientation == UIDeviceOrientationPortrait) {
                    CGRect frame = cellFrame;
                    frame.origin.y = self.collectionViewHeight - cellFrame.size.height;
                    cellFrame = frame;
                }

            }
            if (numbeOfSameXOrigins == 1 && [dictionary count] == 4 && featured && [UIDevice currentDevice].orientation != UIDeviceOrientationPortrait) {
                if (cellFrame.size.height + cellFrame.origin.y < self.collectionViewHeight) {
                    CGRect frame = cellFrame;
                    frame.origin.y = self.collectionViewHeight - cellFrame.size.height;
                    cellFrame = frame;
                }
                
            }
            
            if (!intersectsRect) {
                return cellFrame;
            }
        }
    }
    return cellFrame;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:self.layoutInfo.count];
    [self.layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath,
                                                         UICollectionViewLayoutAttributes *attributes,
                                                         BOOL *innerStop) {
        if (CGRectIntersectsRect(rect, attributes.frame)) {
            [allAttributes addObject:attributes];
        }
    }];
    return allAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInfo[indexPath];
}

- (CGSize)collectionViewContentSize
{
    return CGSizeMake(self.collectionView.frame.size.width, self.collectionViewHeight);
}

- (CGSize)boxsize:(NSString *)text textwidth:(float)width font:(UIFont *)font
{
    NSAttributedString *attributedText =
    [[NSAttributedString alloc]
     initWithString:text
     attributes:@
     {
     NSFontAttributeName:font
     }];
    CGRect size = [attributedText boundingRectWithSize:(CGSize) {width, CGFLOAT_MAX}
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    return size.size;
    
}
#warning discard
/*
- (CGSize)scaledSizeForSize:(CGSize)targetSize withMaximumSize:(CGSize)maximumSize
{
    if ((targetSize.width > maximumSize.width) || (targetSize.height > maximumSize.height)) {
        CGFloat xScale = maximumSize.width / targetSize.width;
        CGFloat yScale = maximumSize.height / targetSize.height;
        
        CGFloat scale = MIN(xScale,yScale);
        return CGSizeMake(ceil(targetSize.width * scale), ceil(targetSize.height * scale));
    } else {
        return targetSize;
    }
}
*/

- (CGFloat)calculateHeightOfCellFromStory:(MITNewsStory *)story withCellWidth:(CGFloat)cellWidth isJumboCell:(BOOL)jumboCell
{
    
    CGFloat length = 0;
    if (jumboCell ) {
        if (story.title) {
            length = [self boxsize:story.title textwidth:cellWidth font:[UIFont fontWithName:@"HelveticaNeue-Medium" size:24]].height;
        }
        if (story.dek) {
            length += [self boxsize:story.dek textwidth:cellWidth font:[UIFont fontWithName:@"HelveticaNeue-Medium" size:17]].height;
        }
    } else if ([story.type isEqualToString:@"news_clip"]) {

        length = [self boxsize:story.dek textwidth:cellWidth font:[UIFont fontWithName:@"HelveticaNeue" size:14]].height;
    } else {
        
        if (story.coverImage) {
            
            if (story.title) {
                length = [self boxsize:story.title textwidth:cellWidth font:[UIFont fontWithName:@"HelveticaNeue-Medium" size:18]].height;
            }
            
        } else {
            if (story.title) {
                length = [self boxsize:story.title textwidth:cellWidth font:[UIFont fontWithName:@"HelveticaNeue-Medium" size:18]].height;
            }
            if (story.dek) {
                length += [self boxsize:story.dek textwidth:cellWidth font:[UIFont fontWithName:@"HelveticaNeue" size:15]].height;
            }
        }
    }
    
    
    MITNewsImageRepresentation *representation = [story.coverImage bestRepresentationForSize:CGSizeMake(1000, 1000)];
    if (representation) {
        
        CGFloat ratio = [representation.height floatValue] / [representation.width floatValue];
        CGFloat imageHeight = cellWidth * ratio;
        
        if ([story.type isEqualToString:@"news_clip"]) {
            return length + 34;
        }
        if (jumboCell) {
            return length + imageHeight + 9;
        } else {
            return length + imageHeight + 9;

        }
    } else {
        return length + 1;
    }
}

@end
