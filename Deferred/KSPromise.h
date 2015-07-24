#import <Foundation/Foundation.h>
#import "KSCancellable.h"
#import "KSNullabilityCompat.h"

@class KSPromise;

NS_ASSUME_NONNULL_BEGIN

typedef __nullable id(^promiseValueCallback)(__nullable id value);
typedef __nullable id(^promiseErrorCallback)( NSError * __nullable error);
typedef void(^deferredCallback)(KSPromise *p);

FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorDomain;
FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorErrorsKey;
FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorValuesKey;

@interface KSPromise : NSObject<KSCancellable>
@property (strong, nonatomic, readonly, nullable) id value;
@property (strong, nonatomic, readonly, nullable) NSError *error;
@property (assign, nonatomic, readonly) BOOL fulfilled;
@property (assign, nonatomic, readonly) BOOL rejected;
@property (assign, nonatomic, readonly) BOOL cancelled;

+ (KSPromise *)when:(NSArray *)promises;
- (KSPromise *)then:(nullable promiseValueCallback)fulfilledCallback error:(nullable promiseErrorCallback)errorCallback;

- (id)waitForValue;
- (nullable id)waitForValueWithTimeout:(NSTimeInterval)timeout;

- (void)addCancellable:(id<KSCancellable>)cancellable;

#pragma deprecated
+ (KSPromise *)join:(NSArray *)promises;
- (void)whenResolved:(deferredCallback)complete DEPRECATED_ATTRIBUTE;
- (void)whenRejected:(deferredCallback)complete DEPRECATED_ATTRIBUTE;
- (void)whenFulfilled:(deferredCallback)complete DEPRECATED_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END
