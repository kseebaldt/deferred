#import "KSNetworkClient.h"
#import "KSNullabilityCompat.h"

@class KSPromise;

NS_ASSUME_NONNULL_BEGIN

@interface KSURLConnectionClient : KSNetworkClient <KSNetworkClient>
@end

NS_ASSUME_NONNULL_END
