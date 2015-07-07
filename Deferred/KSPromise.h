#import <Foundation/Foundation.h>
#import "KSCancellable.h"
#import "KSNullabilityCompat.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorDomain;
FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorErrorsKey;
FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorValuesKey;

@interface KSPromise<ObjectType> : NSObject<KSCancellable>
typedef __nullable id(^promiseValueCallback)(__nullable ObjectType value);
typedef __nullable id(^promiseErrorCallback)(NSError * __nullable error);
typedef void(^deferredCallback)(KSPromise<ObjectType> *p);

@property (strong, nonatomic, readonly, nullable) ObjectType value;
@property (strong, nonatomic, readonly, nullable) NSError *error;
@property (assign, nonatomic, readonly) BOOL fulfilled;
@property (assign, nonatomic, readonly) BOOL rejected;
@property (assign, nonatomic, readonly) BOOL cancelled;

+ (KSPromise *)when:(NSArray *)promises;
- (KSPromise *)then:(nullable __nullable id(^)(__nullable ObjectType value))fulfilledCallback error:(nullable promiseErrorCallback)errorCallback;

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
