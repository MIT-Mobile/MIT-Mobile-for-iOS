#import "FeatureLink.h"
#import "CoreDataManager.h"

@implementation FeatureLink 

@dynamic featureSection;
@dynamic featureID;
@dynamic tintColor;
@dynamic titleColor;
@dynamic arrowColor;
@dynamic subtitle;
@dynamic title;
@dynamic photo;
@dynamic photoURL;
@dynamic photoWidth;
@dynamic photoHeight;
@dynamic url;
@dynamic sortOrder;


+ (FeatureLink *)featureLinkWithDictionary:(NSDictionary *)aDict {
	FeatureLink *featureLink = [CoreDataManager insertNewObjectForEntityForName:@"FeatureLink"];

	static NSInteger fallbackSortOrder = 1000; // something to fall back on in case sort order is not defined on the server
	
	if (featureLink) {
		featureLink.featureID = [aDict objectForKey:@"id"];
		featureLink.title = [aDict objectForKey:@"title"];
		featureLink.subtitle = [aDict objectForKey:@"subtitle"];
		featureLink.tintColor = [aDict objectForKey:@"tint-color"];
        featureLink.titleColor = [aDict objectForKey:@"title-color"];
        featureLink.arrowColor = [aDict objectForKey:@"arrow-color"];
        
		featureLink.url = [aDict objectForKey:@"url"];
		featureLink.photoURL = [aDict objectForKey:@"photo-url"];
		
		NSDictionary *dimensions = [aDict objectForKey:@"dimensions"];
        NSNumber *width = [dimensions objectForKey:@"width"];
        NSNumber *height = [dimensions objectForKey:@"height"];
        // check class in case we get back an NSNull
		if ([width isKindOfClass:[NSNumber class]]
        &&  [width isKindOfClass:[NSNumber class]]) {
			featureLink.photoWidth = width;
			featureLink.photoHeight = height;
		}
		
		NSNumber *order = [aDict objectForKey:@"sort-order"];
		if (!order) {
			order = [NSNumber numberWithInteger:fallbackSortOrder];
			fallbackSortOrder++;
		}
		featureLink.sortOrder = order;
	}
	return featureLink;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"\"%@\" %@ <%@>", self.title, NSStringFromCGSize(self.size), self.url];
}

- (CGSize)size {
    return CGSizeMake([self.photoWidth floatValue], [self.photoHeight floatValue]);
}

@end
