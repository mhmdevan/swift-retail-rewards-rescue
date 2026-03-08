#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const RRRLoyaltyBarcodeErrorDomain;

typedef NS_ERROR_ENUM(RRRLoyaltyBarcodeErrorDomain, RRRLoyaltyBarcodeError) {
    RRRLoyaltyBarcodeErrorInvalidMemberID = 1001,
    RRRLoyaltyBarcodeErrorInvalidPayload = 1002,
};

NS_SWIFT_NAME(LegacyLoyaltyBarcodeFormatter)
@interface RRRLegacyLoyaltyBarcodeFormatter : NSObject

+ (nullable NSString *)barcodePayloadForMemberID:(NSString *)memberID
                                            tier:(NSString *)tier
                                          points:(NSInteger)points
                                           error:(NSError * _Nullable * _Nullable)error
    NS_SWIFT_NAME(barcodePayload(memberID:tier:points:));

+ (nullable NSString *)memberIDFromPayload:(NSString *)payload
    NS_SWIFT_NAME(memberID(payload:));

@end

NS_ASSUME_NONNULL_END
