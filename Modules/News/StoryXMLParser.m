#import "StoryXMLParser.h"
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "MIT_MobileAppDelegate.h"
#import "MITMobileServerConfiguration.h"
#import "MobileRequestOperation.h"

@interface StoryXMLParser ()
@property (nonatomic,strong) NSXMLParser *xmlParser;

@property (nonatomic, copy) NSString *currentElement;
@property (nonatomic, strong) NSMutableArray *currentStack;
@property (nonatomic, strong) NSMutableDictionary *currentContents;
@property (nonatomic, strong) NSMutableDictionary *currentImage;

@property NSUInteger expectedNumberOfStories;
@property (getter = isFinished) BOOL finished;
@property BOOL parseSuccessful;
@property (getter = isCanceled) BOOL canceled;


- (void)downloadAndParseURL:(NSURL *)url;
- (NSArray *)itemWhitelist;
- (NSArray *)imageWhitelist;
- (NewsImage *)imageWithDictionary:(NSDictionary *)imageDict;
- (NewsImageRep *)imageRepForURLString:(NSString *)urlString;

- (void)didStartDownloading;
- (void)didStartParsing;
- (void)reportProgress:(NSNumber *)percentComplete;
- (void)parseEnded;
- (void)parseError:(NSError *)error;
@end


@implementation StoryXMLParser
NSString * const NewsTagItem            = @"item";
NSString * const NewsTagTitle           = @"title";
NSString * const NewsTagAuthor          = @"author";
NSString * const NewsTagCategory        = @"category";
NSString * const NewsTagLink            = @"link";
NSString * const NewsTagStoryId         = @"story_id";
NSString * const NewsTagFeatured        = @"featured";
NSString * const NewsTagSummary         = @"description";
NSString * const NewsTagPostDate        = @"postDate";
NSString * const NewsTagBody            = @"body";

NSString * const NewsTagImage           = @"image";
NSString * const NewsTagOtherImages     = @"otherImages";
NSString * const NewsTagThumbnailURL    = @"thumbURL";
NSString * const NewsTagThumbnail2xURL  = @"thumb152";
NSString * const NewsTagSmallURL        = @"smallURL";
NSString * const NewsTagFullURL         = @"fullURL";
NSString * const NewsTagImageCredits    = @"imageCredits";
NSString * const NewsTagImageCaption    = @"imageCaption";

NSString * const NewsTagImageWidth      = @"width";
NSString * const NewsTagImageHeight     = @"height";

- (NSString *)newsTagThumbURL {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]
        && [[UIScreen mainScreen] scale] == 2.0)
    {
        return NewsTagThumbnail2xURL;
    }
    return NewsTagThumbnailURL;
}

- (id) init
{
    self = [super init];
    if (self != nil) {

    }
    return self;
}

- (void)loadStoriesForCategory:(NSInteger)category afterStoryId:(NSInteger)storyId count:(NSInteger)count {
	self.search = NO;
    NSString *newsPath = nil;
    
    if (MITMobileWebGetCurrentServerType() == MITMobileWebDevelopment) {
        newsPath = @"newsoffice-dev";
    } else {
        newsPath = @"newsoffice";
    }
    
    NSURL *host = MITMobileWebGetCurrentServerURL();
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/", [host absoluteString], newsPath]];
    NSMutableString *pathString = [[NSMutableString alloc] init];
    NSMutableArray *params = [[NSMutableArray alloc] init];
    if (category != 0) {
        [params addObject:[NSString stringWithFormat:@"channel=%d", category]];
    } else {
        self.parsingTopStories = YES;
    }

	self.loadingMore = NO;
    if (storyId != 0) {
		self.loadingMore = YES;
        [params addObject:[NSString stringWithFormat:@"story_id=%d", storyId]];
    }
    if ([params count] > 0) {
        [pathString appendString:@"?"];
    }
    [pathString appendString:[params componentsJoinedByString:@"&"]];
    NSURL *fullURL = [NSURL URLWithString:pathString relativeToURL:baseURL];
    
    self.expectedNumberOfStories = 10; // if the server is ever made to support a range param, set this to count instead
    
	[self downloadAndParseURL:fullURL];
}

- (void)loadStoriesforQuery:(NSString *)query afterIndex:(NSInteger)start count:(NSInteger)count {
	self.search = YES;
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
    NSString *relativeString = [NSString stringWithFormat:@"%@/newsoffice/index.php?command=search&q=%@&start=%d&limit=%d",
                                [mobileServer absoluteString], [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], start, count];
    
    NSURL *fullURL = [NSURL URLWithString:relativeString];
    
    self.expectedNumberOfStories = count;
    
	[self downloadAndParseURL:fullURL];
}

- (void)abort {
    self.canceled = YES;
    [self.xmlParser abortParsing];
}

// should be spawned on a separate thread
- (void)downloadAndParseURL:(NSURL *)url {
	self.finished = NO;
    self.parseSuccessful = NO;
    
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithURL:url parameters:nil];

    __weak StoryXMLParser *weakSelf = self;
    request.completeBlock = ^(MobileRequestOperation *request, NSData *xmlData, NSString *contentType, NSError *error) {
        StoryXMLParser *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        }

        if (error) {
            blockSelf.parseSuccessful = NO;
            if (blockSelf.delegate != nil && [blockSelf.delegate respondsToSelector:@selector(parser:didFailWithDownloadError:)]) {
                [blockSelf.delegate parser:blockSelf didFailWithDownloadError:error];
            }
            blockSelf.finished = YES;
        } else {
            blockSelf.addedStories = [NSMutableArray array];
            blockSelf.xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
            blockSelf.xmlParser.delegate = blockSelf;
            blockSelf.currentContents = [NSMutableDictionary dictionary];
            blockSelf.currentStack = [NSMutableArray array];
            [blockSelf.xmlParser parse];
            blockSelf.xmlParser = nil;
            blockSelf.currentStack = nil;
        }
    };
    
    [[MobileRequestOperation defaultQueue] addOperation:request];
}

#pragma mark NSXMLParser delegation

- (NSArray *)itemWhitelist {
    static NSArray *itemWhitelist;
    
    if (!itemWhitelist) {
        itemWhitelist = @[NewsTagTitle,
                          NewsTagAuthor,
                          NewsTagCategory,
                          NewsTagLink,
                          NewsTagStoryId,
                          NewsTagFeatured,
                          NewsTagSummary,
                          NewsTagPostDate,
                          NewsTagBody];
    }
    
    return itemWhitelist;
}

- (NSArray *)imageWhitelist {
    static NSArray *imageWhitelist;
    
    if (!imageWhitelist) {
        imageWhitelist = @[[self newsTagThumbURL],
                           NewsTagSmallURL,
                           NewsTagFullURL,
                           NewsTagImageCredits,
                           NewsTagImageCaption];
    }
    return imageWhitelist;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    self.currentElement = elementName;
	if ([elementName isEqualToString:NewsTagItem]) {
        if ([[self.currentContents allValues] count] > 0) {
            DDLogError(@"%s warning: found a nested <item> in the News XML.", __PRETTY_FUNCTION__);
            [self.currentContents removeAllObjects];
        }
        NSArray *whitelist = [self itemWhitelist];
        for (NSString *key in whitelist) {
            self.currentContents[key] = [NSMutableString string];
        }
	} else if ([elementName isEqualToString:NewsTagOtherImages]) {
        self.currentContents[NewsTagOtherImages] = [NSMutableArray array];
    } else if ([elementName isEqualToString:NewsTagImage]) {
        // prep new image element
        self.currentImage = [NSMutableDictionary dictionary];
        NSArray *whitelist = [self imageWhitelist];
        for (NSString *key in whitelist) {
            self.currentImage[key] = [NSMutableString string];
        }
        
        if ([[self.currentStack lastObject] isEqualToString:NewsTagItem]) {
            // if last tag on stack is <item>, then this is an inline image
            self.currentContents[NewsTagImage] = self.currentImage;
        } else {
            // otherwise, this belongs in <otherImages>
            NSMutableArray *otherImages = self.currentContents[NewsTagOtherImages];
            [otherImages addObject:self.currentImage];
        }
    } else if ([elementName isEqualToString:NewsTagSmallURL] && self.currentImage) {
        self.currentImage[@"smallSize"] = attributeDict;
    } else if ([elementName isEqualToString:NewsTagFullURL] && self.currentImage) {
        self.currentImage[@"fullSize" ] = attributeDict;
    } else if ([elementName isEqualToString:@"items"]) {
		self.totalAvailableResults = [attributeDict[@"totalResults"] integerValue];
	}
    
    [self.currentStack addObject:elementName];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (self.isCanceled) {
        [parser abortParsing];
        return;
    }
    
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSMutableDictionary *currentDict = nil;
    NSArray *whitelist = nil;
    
    if ([self.currentStack indexOfObject:NewsTagImage] != NSNotFound) {
        currentDict = self.currentImage;
        whitelist = [self imageWhitelist];
    } else if ([self.currentStack indexOfObject:NewsTagItem] != NSNotFound) {
        currentDict = self.currentContents;
        whitelist = [self itemWhitelist];
    } else {
        return;
    }
    
    if ([string length] > 0 && [whitelist containsObject:self.currentElement]) {
        NSMutableString *value = currentDict[self.currentElement];
        [value appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    @autoreleasepool {
        [self.currentStack removeLastObject];

        if ([elementName isEqualToString:NewsTagItem]) {
                // use existing story if it's already in the db
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"story_id == %d", [self.currentContents[NewsTagStoryId] integerValue]];
                NewsStory *story = [[CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate] lastObject];
                // otherwise create new
                if (!story) {
                    story = (NewsStory *)[CoreDataManager insertNewObjectForEntityForName:NewsStoryEntityName];
                }

                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                [formatter setDateFormat:@"EEE, d MMM y HH:mm:ss zzz"];
                [formatter setTimeZone:[NSTimeZone localTimeZone]];
                NSDate *postDate = [formatter dateFromString:self.currentContents[NewsTagPostDate]];
                
                story.story_id = @([self.currentContents[NewsTagStoryId] integerValue]);
                story.postDate = postDate;
                story.title = self.currentContents[NewsTagTitle];
                story.link = self.currentContents[NewsTagLink];
                story.author = self.currentContents[NewsTagAuthor];
                story.summary = self.currentContents[NewsTagSummary];
                story.body = self.currentContents[NewsTagBody];
                [story addCategory:[self.currentContents[NewsTagCategory] integerValue]];
                if (self.isParsingTopStories) {
                    story.topStory = @(self.parsingTopStories);
                }

                story.searchResult = @(self.isSearch); // gets reset to NO before every search
                story.featured = @([self.currentContents[NewsTagFeatured] boolValue]);
                story.inlineImage = [self imageWithDictionary:self.currentContents[NewsTagImage]];
                
                NSMutableArray *otherImagesDict = self.currentContents[NewsTagOtherImages];
                [otherImagesDict enumerateObjectsUsingBlock:^(NSDictionary *image, NSUInteger idx, BOOL *stop) {
                    NewsImage *anImage = [self imageWithDictionary:image];
                    if (anImage) {
                        anImage.ordinality = @(idx);
                        [story addGalleryImage:anImage];
                    }
                }];

                [self performSelectorOnMainThread:@selector(reportProgress:)
                                       withObject:@([self.addedStories count] / (0.01 * self.expectedNumberOfStories))
                                    waitUntilDone:NO];

                [self.addedStories addObject:story];
                
                // prepare for next item
                [self.currentContents removeAllObjects];
        }
        
    }
}

- (void)reportProgress:(NSNumber *)percentComplete {
    if ([self.delegate respondsToSelector:@selector(parser:didMakeProgress:)]) {
        [self.delegate parser:self didMakeProgress:[percentComplete floatValue]];
    }
}

- (NewsImage *)imageWithDictionary:(NSDictionary *)imageDict {
    NewsImage *newsImage = nil;
    if (imageDict) {
        NSString *credits = imageDict[NewsTagImageCredits];
        NSString *caption = imageDict[NewsTagImageCaption];
        NSString *thumbURL = imageDict[[self newsTagThumbURL]];
        NSString *smallURL = imageDict[NewsTagSmallURL];
        NSString *fullURL = imageDict[NewsTagFullURL];
        NSDictionary *smallSize = imageDict[@"smallSize"];
        NSDictionary *fullSize = imageDict[@"fullSize"];
		
        // every <image> in the feed has at least a <fullURL>, so index on that
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fullImage.url == %@", fullURL];
        newsImage = [[CoreDataManager objectsForEntity:NewsImageEntityName matchingPredicate:predicate] lastObject];
        if (!newsImage) {
            newsImage = [CoreDataManager insertNewObjectForEntityForName:NewsImageEntityName];
        }
        
        newsImage.credits = credits;
        newsImage.caption = caption;
        newsImage.thumbImage = [self imageRepForURLString:thumbURL];
        newsImage.smallImage = [self imageRepForURLString:smallURL];
        if (smallSize) {
            newsImage.smallImage.width = @([smallSize[NewsTagImageWidth] integerValue]);
            newsImage.smallImage.height = @([smallSize[NewsTagImageHeight] integerValue]);
        }
        newsImage.fullImage = [self imageRepForURLString:fullURL];
        if (fullSize) {
            newsImage.fullImage.width = @([fullSize[NewsTagImageWidth] integerValue]);
            newsImage.fullImage.height = @([fullSize[NewsTagImageHeight] integerValue]);
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

#pragma mark -
#pragma mark StoryXMLParser delegation

- (void)didStartDownloading {
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parserDidStartDownloading:)]) {
		[self.delegate parserDidStartDownloading:self];	
	}
}

- (void)didStartParsing {
	if ([self.delegate respondsToSelector:@selector(parserDidStartParsing:)]) {
		[self.delegate parserDidStartParsing:self];	
	}
}

- (void)parseEnded {
	if (self.parseSuccessful && [self.delegate respondsToSelector:@selector(parserDidFinishParsing:)]) {
		[self.delegate parserDidFinishParsing:self];
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self parseError:error];
    });
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self didStartParsing];
    });
}
         
- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.isCanceled) {
        [parser abortParsing];
        return;
    }
    
    self.parseSuccessful = YES;
	[CoreDataManager saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self parseEnded];
    });
}

- (void)parseError:(NSError *)error {
    self.parseSuccessful = NO;
	if ([self.delegate respondsToSelector:@selector(parser:didFailWithParseError:)]) {
		[self.delegate parser:self didFailWithParseError:error];	
	}
}

@end
