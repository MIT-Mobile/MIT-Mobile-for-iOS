#import "URLShortener.h"

unichar charPlusOffset(NSString *singleChar, unsigned short offset) {
	return ((unichar)
		((unsigned short)[singleChar characterAtIndex:0]) + offset
	);
}

@implementation URLShortener
+ (NSString *) compressedIdFromNumber: (NSNumber *)number {
	NSInteger numericId = [number integerValue];
	NSMutableArray *base62 = [NSMutableArray array];
	NSMutableString *compressedId = [NSMutableString string];
	
	do {
		[base62 addObject:[NSNumber numberWithInteger:(numericId % 62)]];
		numericId = numericId / 62;
	} while (numericId > 0);
		 
	for (NSNumber *base62Digit in [base62 reverseObjectEnumerator]) {
		unichar nextChar;
		unsigned short base62DigitValue = [base62Digit unsignedShortValue];
		
		if (base62DigitValue < 26) {
			nextChar = charPlusOffset(@"a", base62DigitValue);
		} else if (base62DigitValue < 52) {
			nextChar = charPlusOffset(@"A", base62DigitValue-26);
		} else {
			nextChar = charPlusOffset(@"0", base62DigitValue-52);
		}
		
		[compressedId appendFormat:@"%C", nextChar];
	}

	return compressedId;	 
}

@end
