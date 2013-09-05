#import "StoryParser.h"
#import "MobileRequestOperation.h"
#import "StoryListViewController.h"
#import "CoreDataManager.h"

@implementation StoryParser {
    NSMutableArray *addedStories;
    NSInteger expectedStoryCount;
}

@synthesize parseTopStories;
@synthesize isSearch;
@synthesize loadingMore;
@synthesize delegate;
@synthesize addedStories;

NSString * const NewsStoryTagPath                    = @"news/stories";
NSString * const NewsStoryTagTitle                   = @"title";
NSString * const NewsStoryTagAuthor                  = @"author";
NSString * const NewsStoryTagCategory                = @"categories";
NSString * const NewsStoryTagLink                    = @"source_url";
NSString * const NewsStoryTagStoryId                 = @"id";
NSString * const NewsStoryTagFeatured                = @"featured";
NSString * const NewsStoryTagSummary                 = @"dek";
NSString * const NewsStoryTagPostDate                = @"published_at";
NSString * const NewsStoryTagBody                    = @"body";
    
NSString * const NewsStoryTagImage                   = @"images";
NSString * const NewsStoryTagThumbnailURL            = @"thumb";
NSString * const NewsStoryTagThumbnail2xURL          = @"thumb2x";
NSString * const NewsStoryTagImageSmall              = @"small";
NSString * const NewsStoryTagImageFull               = @"full";
NSString * const NewsStoryTagImageCredits            = @"credits";
NSString * const NewsStoryTagImageCaption            = @"caption";
NSString * const NewsStoryTagImageRepresentations    = @"representations";

NSString * const NewsStoryTagImageWidth              = @"width";
NSString * const NewsStoryTagImageHeight             = @"height";
NSString * const NewsStoryTagImageURL                = @"url";


- (id) init
{
    self = [super init];
    if (self != nil) {
        delegate = nil;
        expectedStoryCount = 0;
        parseTopStories = NO;
        addedStories = nil;
		isSearch = NO;
		loadingMore = NO;
    }
    return self;
}

- (void)dealloc {
    self.delegate = nil;
    self.addedStories = nil;
    [super dealloc];
}

- (void)loadStoriesForCategory:(NSInteger)category_id afterStoryId:(NSInteger)storyId count:(NSInteger)count {
	self.isSearch = NO;
    NSString *newsPath = NewsStoryTagPath;
    NSURL *host = MITMobileWebGetCurrentServerURL();
    NSMutableString *baseURLString = [NSMutableString stringWithFormat:@"%@/%@", [host absoluteString], newsPath];
    NSURL *baseURL = [[NSURL alloc] init];
    NSMutableString *pathString = [NSMutableString stringWithCapacity:22];
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:2];
    [params addObject:[NSString stringWithFormat:@"category=%d", category_id]];
    if (category_id == 0){
        parseTopStories = TRUE;
    }
	self.loadingMore = NO;
    if (storyId != 0) {
//        self.loadingMore = YES; // TODO: This can be useful later
        [baseURLString appendString:[NSString stringWithFormat:@"/%i", storyId]];
    }
    if ([params count] > 0) {
        [pathString appendString:@"?"];
    }
    baseURL =[NSURL URLWithString:baseURLString];
    [pathString appendString:[params componentsJoinedByString:@"&"]];
    NSURL *fullURL = [NSURL URLWithString:pathString relativeToURL:baseURL];
    
    expectedStoryCount = 10; // if the server is ever made to support a range param, set this to count instead
	[self downloadAndParseURL:fullURL];
}

- (void)downloadAndParseURL:(NSURL *)url {
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithURL:url parameters:nil];    
    request.completeBlock = ^(MobileRequestOperation *request, id jsonResult, NSString *contentType, NSError *error) {
        if (error || [jsonResult isKindOfClass:[NSDictionary class]]) {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parserStories:didFailDownload:)]) {
                [self.delegate parserStories:self didFailDownload:error];
            }
        } else {
            self.addedStories = [NSMutableArray array];
            for (NSDictionary *storyInfo in jsonResult)
            {
                [self updateInfo:storyInfo];
            }
            [CoreDataManager saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(didFinishParsing:)]) {
                [self.delegate didFinishParsing:self];
            }
        }
    };
    [[NSOperationQueue mainQueue] addOperation:[request autorelease]];
}

- (void) updateInfo:(NSDictionary *)storyInfo {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"story_id == %d", [[storyInfo objectForKey:NewsStoryTagStoryId] integerValue]];
    NewsStory *story = [[CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate] lastObject];
    // otherwise create new
    if (!story) {
        story = (NewsStory *)[CoreDataManager insertNewObjectForEntityForName:NewsStoryEntityName];
    }
    story.story_id = [NSNumber numberWithInteger:[[storyInfo objectForKey:@"id"] integerValue]];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSDate *date;
    NSError *error;
    [formatter getObjectValue:&date forString:[storyInfo objectForKey:NewsStoryTagPostDate] range:nil error:&error];
    [formatter release];
    story.postDate = date;
    
    story.title = [storyInfo objectForKey:NewsStoryTagTitle];
    story.link = [storyInfo objectForKey:NewsStoryTagLink];
    story.author = [storyInfo objectForKey:NewsStoryTagAuthor];
    story.summary = [storyInfo objectForKey:NewsStoryTagSummary];
    story.body = [storyInfo objectForKey:NewsStoryTagBody];
    
    NSArray *category = [[NSArray alloc] init];
    category = [storyInfo objectForKey:NewsStoryTagCategory];
    [story addCategory:[[category objectAtIndex:0] integerValue]];
    if (parseTopStories) {
        // because NewsStory objects are shared between categories, only set this to YES, never revert it to NO
        story.topStory = [NSNumber numberWithBool:parseTopStories];
    }
    story.searchResult = [NSNumber numberWithBool:isSearch]; // gets reset to NO before every search
    
    story.featured = [NSNumber numberWithBool:[[storyInfo objectForKey:NewsStoryTagFeatured] boolValue]];
    
    NSMutableArray *images = [storyInfo objectForKey:NewsStoryTagImage];
    story.inlineImage = [self imageWithDictionary:[images objectAtIndex:0]];
    [images removeObjectAtIndex:0];
    
    
    if (images != NULL) {
        NSMutableArray *otherImagesDict = images;
        NSInteger i = 0;
        for (NSDictionary *otherImage in otherImagesDict) {
            NewsImage *anImage = [self imageWithDictionary:otherImage];
            if (anImage) {
                anImage.ordinality = [NSNumber numberWithInteger:i];
                i++;
                [story addGalleryImage:anImage];
            }
        }
    }
    [self performSelectorOnMainThread:@selector(reportProgress:) withObject:[NSNumber numberWithFloat:[addedStories count] / (0.01 * expectedStoryCount)] waitUntilDone:NO];
    
    [addedStories addObject:story];
}

- (NSString *)newsTagThumbURL {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]
        && [[UIScreen mainScreen] scale] == 2.0)
    {
        return NewsStoryTagThumbnail2xURL;
    }
    return NewsStoryTagThumbnailURL;
}

- (NewsImage *)imageWithDictionary:(NSDictionary *)imageDict {
    NewsImage *newsImage = nil;
    if (imageDict) {
        NSString *credits = [imageDict objectForKey:NewsStoryTagImageCredits];
        NSString *caption = [imageDict objectForKey:NewsStoryTagImageCaption];
        NSDictionary *representations = [imageDict objectForKey:NewsStoryTagImageRepresentations];
        NSDictionary *thumbImage = [representations objectForKey:[self newsTagThumbURL]];
        
        NSString *thumbURL = [thumbImage objectForKey:NewsStoryTagImageURL];
        NSDictionary *smallImage = [representations objectForKey:NewsStoryTagImageSmall];
        NSDictionary *fullImage = [representations objectForKey:NewsStoryTagImageFull];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fullImage.url == %@", [fullImage objectForKey:NewsStoryTagImageURL]];
        newsImage = [[CoreDataManager objectsForEntity:NewsImageEntityName matchingPredicate:predicate] lastObject];
        if (!newsImage) {
            newsImage = [CoreDataManager insertNewObjectForEntityForName:NewsImageEntityName];
        }
        
        newsImage.credits = credits;
        newsImage.caption = caption;
        newsImage.thumbImage = [self imageRepForURLString:thumbURL];
        
        if (smallImage) {
            newsImage.smallImage = [self imageRepForURLString:[smallImage objectForKey:NewsStoryTagImageURL]];
            newsImage.smallImage.width = [NSNumber numberWithInteger:[[smallImage objectForKey:NewsStoryTagImageWidth] integerValue]];
            newsImage.smallImage.height = [NSNumber numberWithInteger:[[smallImage objectForKey:NewsStoryTagImageHeight] integerValue]];
        }
        
        if (fullImage) {
            newsImage.fullImage = [self imageRepForURLString:[fullImage objectForKey:NewsStoryTagImageURL]];
            newsImage.fullImage.width = [NSNumber numberWithInteger:[[fullImage objectForKey:NewsStoryTagImageWidth] integerValue]];
            newsImage.fullImage.height = [NSNumber numberWithInteger:[[fullImage objectForKey:NewsStoryTagImageHeight] integerValue]];
        }
    }
    return newsImage;
}

- (NewsImageRep *)imageRepForURLString:(NSString *)urlString {
    NewsImageRep *imageRep = nil;
    if (urlString && [urlString length] > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url == %@", urlString];
        imageRep = [[CoreDataManager objectsForEntity:NewsImageRepEntityName matchingPredicate:predicate] lastObject];
        if (!imageRep) {
            imageRep = [CoreDataManager insertNewObjectForEntityForName:NewsImageRepEntityName];
            imageRep.url = urlString;
        }
    }
    return imageRep;
}

- (void)addGalleryImage:(NewsImage *)newImage {
    if (newImage) {
        NSMutableSet *gallerySet = [self mutableSetValueForKey:@"galleryImages"];
        [gallerySet addObject:newImage];
    }
}

- (void)loadStoriesforQuery:(NSString *)query afterIndex:(NSInteger)start count:(NSInteger)count {
	self.isSearch = YES;
	self.loadingMore = (start == 0) ? NO : YES;
	
	// before getting new results, clear old search results if this is a new search request
	if (self.isSearch && !self.loadingMore) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"searchResult == YES"];
		NSArray *results = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
		for (NewsStory *aStory in results) {
			aStory.searchResult = NO;
		}
		[CoreDataManager saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	}
    
    NSURL *mobileServer = MITMobileWebGetCurrentServerURL();
    NSString *relativeString = [NSString stringWithFormat:@"%@/%@?q=%@&limit=%d",
                                [mobileServer absoluteString], NewsStoryTagPath, [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], count];
    
    NSURL *fullURL = [NSURL URLWithString:relativeString];
    
    expectedStoryCount = count;
    
	[self downloadAndParseURL:fullURL];
}

- (void)reportProgress:(NSNumber *)percentComplete {
    if ([self.delegate respondsToSelector:@selector(parserStories:didMakeProgress:)]) {
        [self.delegate parserStories:self didMakeProgress:[percentComplete floatValue]];
    }
}


@end
