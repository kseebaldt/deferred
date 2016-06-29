#import <Foundation/Foundation.h>
#import "KSCancellable.h"
#import "KSNullabilityCompat.h"
#import "KSGenericsCompat.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorDomain;
FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorErrorsKey;
FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorValuesKey;

@interface KSPromise KS_GENERIC(ObjectType) : NSObject<KSCancellable>
typedef __nullable id(^promiseValueCallback)(__nullable KS_GENERIC_TYPE(ObjectType) value);
typedef __nullable id(^promiseErrorCallback)(NSError * __nullable error);
typedef void(^deferredCallback)(KSPromise KS_GENERIC(ObjectType) *p);

typedef void(^resolveType)(__nullable KS_GENERIC_TYPE(ObjectType) value);
typedef void(^rejectType)(NSError * __nullable error);

@property (strong, nonatomic, readonly, nullable) KS_GENERIC_TYPE(ObjectType) value;
@property (strong, nonatomic, readonly, nullable) NSError *error;
@property (assign, nonatomic, readonly) BOOL fulfilled;
@property (assign, nonatomic, readonly) BOOL rejected;
@property (assign, nonatomic, readonly) BOOL cancelled;

#pragma mark - Constructors
+ (KSPromise *)promise:(void (^)(resolveType resolve, rejectType reject))promiseCallback;
+ (KSPromise *)resolve:(nullable KS_GENERIC_TYPE(ObjectType))value;
+ (KSPromise *)reject:(NSError *)error;

+ (KSPromise *)when:(NSArray *)promises;
+ (KSPromise *)all:(NSArray *)promises;

- (KSPromise *)then:(nullable __nullable id(^)(__nullable KS_GENERIC_TYPE(ObjectType) value))fulfilledCallback error:(nullable promiseErrorCallback)errorCallback;
- (KSPromise *)then:(__nullable id(^)(__nullable KS_GENERIC_TYPE(ObjectType) value))fulfilledCallback;
- (KSPromise *)error:(promiseErrorCallback)errorCallback;
- (KSPromise *)finally:(void(^)())callback;

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
