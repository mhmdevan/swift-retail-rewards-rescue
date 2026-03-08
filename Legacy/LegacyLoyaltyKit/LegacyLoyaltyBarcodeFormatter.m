#import "LegacyLoyaltyBarcodeFormatter.h"

NSErrorDomain const RRRLoyaltyBarcodeErrorDomain = @"com.retailrewardsrescue.loyalty.barcode";

@implementation RRRLegacyLoyaltyBarcodeFormatter

+ (nullable NSString *)barcodePayloadForMemberID:(NSString *)memberID
                                            tier:(NSString *)tier
                                          points:(NSInteger)points
                                           error:(NSError * _Nullable * _Nullable)error {
    if (memberID.length == 0 || [memberID rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location != NSNotFound) {
        if (error != nil) {
            *error = [NSError errorWithDomain:RRRLoyaltyBarcodeErrorDomain
                                         code:RRRLoyaltyBarcodeErrorInvalidMemberID
                                     userInfo:@{NSLocalizedDescriptionKey: @"Member ID must be non-empty and contain no spaces."}];
        }
        return nil;
    }

    NSInteger checksum = [self checksumForMemberID:memberID points:points];
    return [NSString stringWithFormat:@"RRR|%@|%@|%ld|%ld", memberID, tier, (long)points, (long)checksum];
}

+ (nullable NSString *)memberIDFromPayload:(NSString *)payload {
    NSArray<NSString *> *components = [payload componentsSeparatedByString:@"|"];
    if (components.count < 5 || ![components.firstObject isEqualToString:@"RRR"]) {
        return nil;
    }

    NSString *memberID = components[1];
    if (memberID.length == 0) {
        return nil;
    }

    NSInteger points = [components[3] integerValue];
    NSInteger checksum = [components[4] integerValue];
    NSInteger expectedChecksum = [self checksumForMemberID:memberID points:points];

    if (checksum != expectedChecksum) {
        return nil;
    }

    return memberID;
}

+ (NSInteger)checksumForMemberID:(NSString *)memberID points:(NSInteger)points {
    NSInteger asciiSum = 0;
    for (NSUInteger i = 0; i < memberID.length; i++) {
        unichar character = [memberID characterAtIndex:i];
        asciiSum += character;
    }

    return (asciiSum + points) % 97;
}

@end
