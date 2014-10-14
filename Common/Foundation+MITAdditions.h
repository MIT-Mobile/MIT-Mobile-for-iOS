#import <Foundation/Foundation.h>

#pragma mark Error Domains
extern NSString * const MITXMLErrorDomain;

BOOL MITCGFloatIsEqual(CGFloat f0, CGFloat f1);

@interface NSURL (MITAdditions)

+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path;
+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path query:(NSString *)query;

/** Returns a set of key-value pairs for all parameters
 *  in the query string. Any singleton parameters (for example
 *  ...?parameter&...) will be included in the dictionary but
 *  have a value of [NSNull null]
 *
 * @returns A dictionary of parameter key/value pairs or nil if -query is nil or empty
 * @see -[NSURL query]
 */
- (NSDictionary*)queryDictionary;
@end

@interface NSArray (MITAdditions)
- (NSArray*)arrayByMappingObjectsUsingBlock:(id (^)(id obj, NSUInteger idx))block;
- (NSArray *)mapObjectsUsingBlock:(id (^)(id obj, NSUInteger idx))block;

@end

@interface NSSet (MITAdditions)

- (NSSet *)mapObjectsUsingBlock:(id (^)(id obj))block;

@end

@interface NSMutableString (MITAdditions)
/** Replace all the occurrences of the strings in targets with the
 *  values in replacements.
 *
 *  @param targets The strings to replace. Raises an NSInvalidArgumentException if targets and replacements do not have the same number of strings.
 *  @param replacements The strings with which to replace target. Raises an NSInvalidArgumentException if targets and replacements do not have the same number of strings.
 *  @param opts See replaceOccurrencesOfString:withString:options:range:
 *
 *  @see replaceOccurrencesOfString:withString:options:range:
 */
- (void)replaceOccurrencesOfStrings:(NSArray *)targets withStrings:(NSArray *)replacements options:(NSStringCompareOptions)options;

@end

@interface NSString (MITAdditions)
- (BOOL)containsSubstring:(NSString*)string options:(NSStringCompareOptions)mask;

/** Returns a copy of the receiver which has whitespace
 *  and punctuation removed and normalized using NFKD form.
 */
- (NSString*)stringBySearchNormalization;
- (NSString*)stringBySanitizingHTMLFragmentWithPermittedElementNames:(NSArray*)tagNames error:(NSError**)error;
- (NSString *)substringToMaxIndex:(NSUInteger)to;
@end

@interface NSString (MITAdditions_URLEncoding)
- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding useFormURLEncoded:(BOOL)formUrlEncoded;
- (NSString*)urlDecodeUsingEncoding:(NSStringEncoding)encoding;
@end

@interface NSString (MITAdditions_HTMLEntity)

- (NSString *)stringByDecodingXMLEntities;

/** String representation with HTML tags removed.

 Replaces all angle bracketed text with spaces, collapses all spaces down to a single space, and trims leading and trailing whitespace and newlines.

 @return A plain text string suitable for display in a UILabel.
 */
- (NSString *)stringByStrippingTags;

@end

@interface NSDate (MITAdditions)
+ (NSDate *)fakeDateForDining;
+ (NSDate *) dateForTodayFromTimeString:(NSString *)time;
- (BOOL) isEqualToDateIgnoringTime: (NSDate *) aDate;
- (BOOL)isEqualToTimeIgnoringDay:(NSDate *)date;
- (BOOL) isToday;
- (BOOL) isTomorrow;
- (BOOL) isYesterday;
- (NSDate *)dateWithoutTime;
- (NSDate *)startOfDay;
- (NSDate *)endOfDay;
- (NSDate *)startOfWeek;
- (NSDate *)dayBefore;
- (NSDate *)dayAfter;
- (NSDate *)dateByAddingDay;
- (NSDate *)dateBySubtractingDay;
- (NSDate *)dateByAddingWeek;
- (NSDate *)dateBySubtractingWeek;
- (NSDate *)dateByAddingYear;
- (NSArray *)datesInWeek;
- (NSString *) MITShortTimeOfDayString; // e.g. "1pm", "10:30am", etc
- (NSString *)todayTomorrowYesterdayString;
- (NSDateComponents *) dayComponents;
- (NSDateComponents *) timeComponents;
- (NSDate *)dateWithTimeOfDayFromDate:(NSDate *)date;
- (BOOL)dateFallsBetweenStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;
- (NSString *)ISO8601String;

@end

@interface NSCalendar (MITAdditions)

+ (NSCalendar *)cachedCurrentCalendar;

@end

@interface NSIndexPath (MITAdditions)
+ (NSIndexPath*)indexPathWithIndexPath:(NSIndexPath*)indexPath;
@end
