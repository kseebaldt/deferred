#import "KSPromise.h"
#import "KSCancellable.h"
#import "KSNetworkClient.h"
#import "KSURLConnectionClient.h"
#import "KSURLSessionClient.h"
#import "KSNullabilityCompat.h"

NS_ASSUME_NONNULL_BEGIN

@interface KSDeferred : NSObject

@property (strong, nonatomic) KSPromise *promise;

+ (instancetype)defer;

- (void)resolveWithValue:(nullable id)value;
- (void)rejectWithError:(nullable NSError *)error;
- (void)whenCancelled:(void (^)(void))cancelledBlock;

@end

NS_ASSUME_NONNULL_END
