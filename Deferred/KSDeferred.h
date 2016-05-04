#import "KSPromise.h"
#import "KSCancellable.h"
#import "KSNetworkClient.h"
#if !TARGET_OS_WATCH && !TARGET_OS_TV
#import "KSURLConnectionClient.h"
#endif
#import "KSURLSessionClient.h"
#import "KSNullabilityCompat.h"
#import "KSGenericsCompat.h"

NS_ASSUME_NONNULL_BEGIN

@interface KSDeferred KS_GENERIC(ObjectType) : NSObject

@property (strong, nonatomic) KSPromise KS_GENERIC(ObjectType) *promise;

+ (instancetype)defer;

- (void)resolveWithValue:(nullable KS_GENERIC_TYPE(ObjectType))value;
- (void)rejectWithError:(nullable NSError *)error;
- (void)whenCancelled:(void (^)(void))cancelledBlock;

@end

NS_ASSUME_NONNULL_END
